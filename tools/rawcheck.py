#!/usr/bin/env python3
"""Run a SPICE simulator on a deck and judge its binary raw file against the
deck's `.expected.json` oracle, one `ok=` line per check.

    python3 rawcheck.py 'ngspice -b ${RAW:+-r "$RAW"} "$DECK"' ['ngspice -b "$DECK"']
    python3 rawcheck.py --selftest

The command runs under `sh` in the deck's directory (so relative `.include`
paths keep their meaning) with DECK (the deck's file name), RAW (where the
raw file goes) and TOKENIZER (the oracle's input dialect, default ngspice)
set. Without an `.expected.json`, RAW is unset and the command's stdout
passes through, for decks judged by a gold file instead (external manifests).
The optional second command runs once more, RAW unset, for an oracle with
`measure` checks or a Fourier plot, which read its stdout instead: ngspice
44.2 refuses every `.measure` and `.four` under `-b -r` ("No .measure
possible in batch mode (-b) with -r rawfile set!", ".fourier line ignored
since rawfile was produced"). Its `.four` tables join the plots as
`fourier_plots` names them; the waveforms still come from the first run.

A port of ESPice's tests/test_correctness.zig judge, tool-neutral:
- `status: error` passes on a diagnosed failure (exit 1-125). ESPice also
  matches its own error category, which other tools do not print.
- plots: the `exact`, `selected_rows`, `samples` and `unordered` match
  modes, |got - want| <= atol + rtol*|want| on the complex plane.
- checks: `measure` (a `.meas` line on stdout, at the digits it prints:
  "printed channel: N digits"), `repeatability` (the command once more,
  its plots bitwise equal), `stderr_line` (the first run's stderr), and the
  plot checks `axis_bounds`, `selected_values`, `fourier_thd`,
  `sample_moments`, `time_weighted_moments`, `oscillation` and
  `pole_zero_sets`, each as test_correctness.zig `compareCheck` judges it,
  on the plots the tool writes. Any other kind is an `ok=0` line,
  "unported check kind X": unsupported fails, never skips.
"""
import json, math, os, re, struct, subprocess, sys


def parse_raw(data):
    """[(plotname, [column names], rows, complex, values[row][col])]"""
    plots, pos = [], 0

    def line():
        nonlocal pos
        end = data.index(b"\n", pos)
        text = data[pos:end].decode(errors="replace").strip()
        pos = end + 1
        return text

    while pos < len(data):
        if data[pos:pos + 1] in (b"\n", b"\r"):
            pos += 1
            continue
        if not line().startswith("Title:"):
            raise ValueError("raw: no Title")
        head = {}
        while (t := line()).lower() != "variables:":
            k, _, v = t.partition(":")
            head[k.strip().lower()] = v.strip()
        cols, rows = int(head["no. variables"]), int(head["no. points"])
        cplx = head["flags"].lower() == "complex"
        names = [line().split()[1] for _ in range(cols)]
        if line().lower() != "binary:":
            raise ValueError("raw: not a binary raw file")
        width = 2 if cplx else 1
        n = rows * cols * width
        vals = struct.unpack_from(f"<{n}d", data, pos)
        pos += n * 8
        table = [[complex(vals[(r * cols + c) * 2], vals[(r * cols + c) * 2 + 1]) if cplx else complex(vals[r * cols + c], 0)
                  for c in range(cols)] for r in range(rows)]
        plots.append((head["plotname"], names, rows, cplx, table))
    if not plots:
        raise ValueError("raw: no plots")
    return plots


def canonical(name):
    """The spellings ngspice and espice use for the same column, folded."""
    n = name.lower()
    tf = {"v(transfer_function)": "transfer_function"}
    if n in tf:
        return tf[n]
    if "#input_impedance" in n:
        return "input_resistance"
    if n.startswith("v(output_impedance_at_"):
        return "output_resistance"
    return n[:-7] if n.endswith("#branch") else n


def column(plot, name):
    """An exact name first (case-folded), then the one `canonical` alias
    (test_correctness.zig `Plot.column`)."""
    exact = [i for i, n in enumerate(plot[1]) if n.lower() == name.lower()]
    if exact:
        return exact[0]
    hits = [i for i, n in enumerate(plot[1]) if canonical(n) == canonical(name)]
    if len(hits) != 1:
        raise KeyError(f"column {name}: {len(hits)} matches")
    return hits[0]


def close(got, want, rtol, atol):
    return abs(got - want) <= atol + rtol * abs(want)


def scalar(v):
    return complex(v[0], v[1]) if isinstance(v, list) else complex(v, 0)


def plot_name(actual, want):
    a, w = actual.lower(), want.lower()
    return a == w or (w.startswith("fourier analysis") and a.startswith(w) and a[len(w):].startswith(" (thd = "))


def sample(plot, axis, col, t, rtol, atol):
    """Column `col` linearly interpolated at axis value `t`."""
    tab, rows = plot[4], plot[2]
    xs = [tab[r][axis].real for r in range(rows)]
    if not rows:
        raise ValueError("no samples")
    if t < xs[0] or t > xs[-1]:
        end = 0 if t < xs[0] else rows - 1
        if close(complex(xs[end], 0), complex(t, 0), rtol, atol):
            return tab[end][col]
        raise ValueError(f"axis does not reach {t}")
    lo, hi = 0, rows - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if xs[mid] <= t else (lo, mid)
    if xs[hi] == xs[lo]:
        return tab[lo][col]
    f = (t - xs[lo]) / (xs[hi] - xs[lo])
    return tab[lo][col] + f * (tab[hi][col] - tab[lo][col])


def judge_plot(want, plot):
    """[(label, ok, detail)] for one expected plot against its raw plot."""
    out = []
    if want.get("row_count") is not None and want["row_count"] != plot[2]:
        return [(f"{want['name']} rows", False, f"got={plot[2]} want={want['row_count']}")]
    mode, axis, cols = want["match"], want.get("axis"), want["columns"]
    if mode == "unordered":
        # Bipartite match, expected rows onto actual rows (augmenting paths).
        idx = {n: column(plot, n) for n in cols}
        ax = axis and column(plot, axis["name"])
        owner = [None] * plot[2]

        def fits(r, c):
            ok = all(close(plot[4][c][idx[n]], scalar(col["values"][r]), col["rtol"], col["atol"]) for n, col in cols.items())
            return ok and (not axis or close(plot[4][c][ax], complex(axis["values"][r], 0), axis["rtol"], axis["atol"]))

        def assign(r, seen):
            for c in range(plot[2]):
                if c in seen or not fits(r, c):
                    continue
                seen.add(c)
                if owner[c] is None or assign(owner[c], seen):
                    owner[c] = r
                    return True
            return False

        ok = all(assign(r, set()) for r in range(plot[2]))
        return [(f"{want['name']} rows (unordered)", ok, "")]
    rows = want.get("row_indices") if mode == "selected_rows" else None
    if axis and mode != "samples":
        a = column(plot, axis["name"])
        bad = [(j, plot[4][rows[j] if rows else j][a]) for j, v in enumerate(axis["values"])
               if not close(plot[4][rows[j] if rows else j][a], complex(v, 0), axis["rtol"], axis["atol"])]
        out.append((f"{want['name']}:{axis['name']}", not bad, f"got={bad[0][1]} want={axis['values'][bad[0][0]]}" if bad else ""))
    for name, col in cols.items():
        c = column(plot, name)
        first = None
        for j, v in enumerate(col["values"]):
            if mode == "samples":
                a = column(plot, axis["name"])
                got = sample(plot, a, c, axis["values"][j], axis["rtol"], axis["atol"])
            else:
                got = plot[4][rows[j] if rows else j][c]
            w = scalar(v)
            if col.get("magnitude"):
                got, w = complex(abs(got), 0), complex(abs(w), 0)
            if not close(got, w, col["rtol"], col["atol"]):
                first = (j, got, w)
                break
        detail = f"[{first[0]}] got={first[1]:.9g} want={first[2]:.9g}" if first else f"got={len(col['values'])} points want={len(col['values'])}"
        out.append((f"{want['name']}:{name}", first is None, detail))
    return out


def measure(stdout, check):
    """The first `name = value ...` line, judged at the line's own accuracy:
    atol widens by half a unit in its last printed digit. A tool's listing
    is all rawcheck reads, and ngspice 44.2's prints a PARAM, WHEN, RMS or
    INTEG card at %.5e and the rest at %e; no option reaches it (`set
    numdgt=16` in a .control block leaves it as it is)."""
    for text in stdout.splitlines():
        name, eq, rest = text.partition("=")
        if eq and name.strip().lower() == check["name"].lower():
            try:
                token = rest.split()[0]
                got = float(token)
            except (ValueError, IndexError):
                break
            mantissa, _, exponent = token.lower().partition("e")
            half = 0.5 * 10.0 ** (int(exponent or 0) - len(mantissa.partition(".")[2]))
            digits = sum(c.isdigit() for c in mantissa)
            ok = close(complex(got, 0), complex(check["value"], 0), check["rtol"], check["atol"] + half)
            return ok, f"got={got:.9g} want={check['value']:.9g} printed channel: {digits} digits"
    return False, f"got=missing want={check['value']:.9g}"


def fourier_plots(stdout):
    """Each `Fourier analysis for <output>:` table on stdout as the plot
    ESPice writes for it: "Fourier Analysis[ <output>] (THD = t %)", the
    output named only when there are several, with the columns harmonic,
    frequency, magnitude and phase_deg (ngspice prints degrees)."""
    blocks = re.findall(r"^Fourier analysis for (.+?):\n.*?THD: (\S+) %.*?\n-+[ -]*\n((?:[ \t]*\d[^\n]*\n?)+)", stdout, re.M | re.S)
    plots = []
    for output, thd, table in blocks:
        label = f" {output}" if len(blocks) > 1 else ""
        rows = [[complex(float(x), 0) for x in line.split()[:4]] for line in table.splitlines()]
        plots.append((f"Fourier Analysis{label} (THD = {thd} %)", ["harmonic", "frequency", "magnitude", "phase_deg"], len(rows), False, rows))
    return plots


def reads_stdout(exp):
    """A `measure` check or a Fourier plot: ngspice prints both only without -r."""
    checks = exp.get("checks", [])
    names = [p["name"] for p in exp.get("plots", [])] + [c.get("plot", "") for c in checks]
    return any(c["kind"] in ("measure", "fourier_thd") for c in checks) or any(n.startswith("Fourier Analysis") for n in names)


def repeatable(check, first, again):
    """A second run of the same deck: its plots bitwise equal to the first's,
    names, row counts and every value (test_correctness.zig `repeatable`)."""
    if check.get("same_netlist") is not True or check.get("comparison") != "bitwise_numeric_results":
        return False, "got=invalid oracle want=same_netlist and bitwise_numeric_results"
    try:
        second = parse_raw(again)
    except (ValueError, KeyError, struct.error) as e:
        return False, f"got={e} want=a second binary raw file"

    def bits(plots):
        return [(p[:4], b"".join(struct.pack("<2d", v.real, v.imag) for row in p[4] for v in row)) for p in plots]
    return bits(first) == bits(second), f"got={len(second)} plots want={len(first)} bitwise equal"


# The plot checks, each as test_correctness.zig `compareCheck` judges it.
# Each returns (ok, detail); a malformed oracle or a missing plot, column or
# sample raises, and `judge` reports it as a failure.

def find_plot(plots, name):
    hits = [p for p in plots if plot_name(p[0], name)]
    if len(hits) != 1:
        raise ValueError(f"plot {name}: {len(hits)} matches")
    return hits[0]


def real(v, what):
    if v.imag != 0:
        raise ValueError(f"{what}: a complex value")
    return v.real


def tolerance(rtol, atol):
    if not (math.isfinite(rtol) and math.isfinite(atol) and rtol >= 0 and atol >= 0):
        raise ValueError("invalid oracle: tolerance")


def between(name, value, lo, hi):
    if lo > hi:
        raise ValueError("invalid oracle: minimum above maximum")
    return math.isfinite(value) and lo <= value <= hi, f"{name} got={value:.9g} want=[{lo:.9g}, {hi:.9g}]"


def measured(name, got, want, rtol):
    tolerance(rtol, 0)
    return math.isfinite(got) and close(got, want, rtol, 0), f"{name} got={got:.9g} want={want:.9g} rtol={rtol:g}"


def first_failure(*results):
    return next((r for r in results if not r[0]), results[-1])


def increasing(p, axis):
    if not p[2]:
        raise ValueError("empty time axis")
    ts = [real(p[4][r][axis], "time") for r in range(p[2])]
    if any(ts[r] <= ts[r - 1] for r in range(1, len(ts))):
        raise ValueError("time axis not increasing")
    return ts


def axis_bounds(check, plots):
    p = find_plot(plots, check["plot"])
    a, lo, hi = column(p, check["axis"]), check["minimum"], check["maximum"]
    if lo > hi:
        raise ValueError("invalid oracle: minimum above maximum")
    if not p[2]:
        raise ValueError("no samples")
    xs = [real(p[4][r][a], check["axis"]) for r in range(p[2])]
    return all(math.isfinite(x) and lo <= x <= hi for x in xs), f"got=[{min(xs):.9g}, {max(xs):.9g}] want=[{lo:.9g}, {hi:.9g}]"


def selected_values(check, plots):
    """The row whose axis equals each coordinate exactly; its value within
    atol of the expected one modulo `period` (a phase wraps)."""
    p = find_plot(plots, check["plot"])
    c, a, period, atol = column(p, check["column"]), column(p, check["axis"]), check["period"], check["atol"]
    if len(check["coordinates"]) != len(check["values"]) or period <= 0 or atol < 0:
        raise ValueError("invalid oracle")
    for x, want in zip(check["coordinates"], check["values"]):
        rows = [r for r in range(p[2]) if p[4][r][a].real == x]
        if len(rows) != 1:
            raise ValueError(f"{check['axis']} = {x}: {len(rows)} rows")
        v = p[4][rows[0]][c]
        delta = (v.real - want + period / 2) % period - period / 2
        if not close(complex(delta, v.imag), 0, 0, atol):
            return False, f"[{x}] got={v.real:.9g} want={want:.9g} mod {period:g}"
    return True, f"got={len(check['values'])} values want={len(check['values'])}"


def fourier_thd(check, plots):
    """100 sqrt(sum of the squared harmonics above the first) / the first."""
    p = find_plot(plots, "Fourier Analysis")
    h, m = column(p, "harmonic"), column(p, "magnitude")
    fundamental, total = None, 0.0
    for r in range(p[2]):
        k, v = p[4][r][h].real, p[4][r][m]
        if v.imag != 0 or k < 0 or k % 1 != 0:
            raise ValueError("invalid harmonics")
        if k == 1:
            if fundamental is not None:
                raise ValueError("invalid harmonics: two fundamentals")
            fundamental = v.real
        elif k > 1:
            total += v.real * v.real
    if fundamental is None or fundamental <= 0:
        raise ValueError("no fundamental")
    return between("thd %", 100 * math.sqrt(total) / fundamental, check["percent_min"], check["percent_max"])


def sample_moments(check, plots):
    """The rows' mean and Bessel-corrected standard deviation (Welford)."""
    p = find_plot(plots, check["plot"])
    if p[2] != check["row_count"] or p[2] < 2:
        return False, f"rows got={p[2]} want={check['row_count']}"
    c, mean, m2 = column(p, check["column"]), 0.0, 0.0
    for r in range(p[2]):
        x = real(p[4][r][c], check["column"])
        delta = x - mean
        mean += delta / (r + 1)
        m2 += delta * (x - mean)
    return first_failure(between("mean", mean, check["mean_min"], check["mean_max"]),
                         between("stddev", math.sqrt(m2 / (p[2] - 1)), check["stddev_min"], check["stddev_max"]))


def time_weighted_moments(check, plots):
    """The trapezoid time average and variance over `time_window`, which
    the time axis must cover, with at least `min_points` samples in it."""
    p = find_plot(plots, check["plot"])
    c, ts = column(p, check["column"]), increasing(p, column(p, "time"))
    start, stop = check["time_window"]
    if stop <= start:
        raise ValueError("invalid oracle: empty window")
    slack = 1e-12  # a `10u` t_stop parses one ulp short of a literal 1e-5
    if ts[0] > start + slack * abs(start) or ts[-1] < stop - slack * abs(stop):
        return False, f"time got=[{ts[0]:.9g}, {ts[-1]:.9g}] want=[{start:.9g}, {stop:.9g}]"

    def at(r, t):  # `sample` inside the segment ts[r - 1]..ts[r]
        if t == ts[r - 1]:
            return p[4][r - 1][c]
        if t == ts[r]:
            return p[4][r][c]
        x, y = p[4][r - 1][c], p[4][r][c]
        return x + (t - ts[r - 1]) / (ts[r] - ts[r - 1]) * (y - x)
    count, integral, square = 0, 0.0, 0.0
    for r, t in enumerate(ts):
        count += start <= t <= stop
        if r == 0:
            continue
        left, right = max(start, ts[r - 1]), min(stop, t)
        if left >= right:
            continue
        v0, v1 = real(at(r, left), check["column"]), real(at(r, right), check["column"])
        integral += (right - left) * (v0 + v1) / 2
        square += (right - left) * (v0 * v0 + v1 * v1) / 2
    if count < check["min_points"]:
        return False, f"points got={count} want>={check['min_points']}"
    mean = integral / (stop - start)
    return first_failure(between("|mean|", abs(mean), 0, check["mean_abs_max"]),
                         between("variance", square / (stop - start) - mean * mean, check["variance_min"], check["variance_max"]))


def oscillation(check, plots):
    """Period: the mean spacing of the rising `level` crossings in the
    window, each interpolated; swing: max - min of the window's samples."""
    p = find_plot(plots, check["plot"])
    c, ts = column(p, check["column"]), increasing(p, column(p, "time"))
    start, stop = check["time_window"]
    level = check["level"]
    if stop <= start:
        raise ValueError("invalid oracle: empty window")
    first, last, crossings, lo, hi = None, 0.0, 0, math.inf, -math.inf
    for r, t in enumerate(ts):
        v = real(p[4][r][c], check["column"])
        if t < start or t > stop:
            continue
        lo, hi = min(lo, v), max(hi, v)
        if r == 0 or ts[r - 1] < start:
            continue
        v0 = p[4][r - 1][c].real
        if not (v0 < level and v >= level):
            continue
        last = ts[r - 1] + (level - v0) / (v - v0) * (t - ts[r - 1])
        first = last if first is None else first
        crossings += 1
    if crossings < 3:
        return False, f"got={crossings} rising crossings of {level:g} want>=3"
    return first_failure(measured("period", (last - first) / (crossings - 1), check["period"], check["period_rtol"]),
                         measured("swing", hi - lo, check["swing"], check["swing_rtol"]))


def pole_zero_sets(check, plots):
    """The `pole`/`zero` columns (one vector, or `pole(k)` columns of one
    row) matched to the expected roots in any order, multiplicity kept."""
    p = find_plot(plots, check["plot"])
    tolerance(check["rtol"], check["atol"])
    if check.get("multiplicity") is not True:
        raise ValueError("invalid oracle: multiplicity")
    for prefix, key in (("pole", "poles"), ("zero", "zeros")):
        roots = []
        for c, name in enumerate(p[1]):
            bare = name[2:-1] if name.startswith("v(") else name
            if bare.lower() == prefix:
                roots += [p[4][r][c] for r in range(p[2])]
            elif bare.startswith(prefix) and len(bare) > len(prefix) and bare[len(prefix)] == "(":
                if p[2] != 1:
                    raise ValueError("root layout: indexed roots over several rows")
                roots.append(p[4][0][c])
        want = check[key]
        if len(roots) != len(want):
            return False, f"{key} got={len(roots)} want={len(want)}"
        spec = {"name": p[0], "match": "unordered", "row_count": len(roots),
                "columns": {prefix: {"values": want, "rtol": check["rtol"], "atol": check["atol"]}}}
        if not judge_plot(spec, (p[0], [prefix], len(roots), True, [[x] for x in roots]))[0][1]:
            return False, f"{key} got={[f'{x:.6g}' for x in roots]} want={want}"
    return True, "got=poles and zeros matched"


def stderr_line(stderr, check):
    hit = any(line.startswith(check["prefix"]) for line in stderr.split("\n"))
    return hit, f"got={'present' if hit else 'missing'} want=a stderr line starting {check['prefix']!r}"


PLOT_CHECKS = {"axis_bounds": axis_bounds, "selected_values": selected_values, "fourier_thd": fourier_thd,
               "sample_moments": sample_moments, "time_weighted_moments": time_weighted_moments,
               "oscillation": oscillation, "pole_zero_sets": pole_zero_sets}


def judge(oracle, rc, stdout, raw, again=b"", stderr=""):
    """[(label, ok, detail)] for the whole oracle; `again` is a second run's
    raw file, for a `repeatability` check."""
    exp = oracle["expect"]
    if exp["status"] == "error":
        return [("rejected with a diagnostic", 1 <= rc <= 125, f"got=exit {rc} want=exit 1-125")]
    if rc != 0:
        return [("simulation succeeded", False, f"got=exit {rc} want=exit 0")]
    try:
        plots = parse_raw(raw) + fourier_plots(stdout)
    except (ValueError, KeyError, OSError, struct.error) as e:
        return [("raw file", False, f"got={e} want=a binary raw file")]
    out, used = [], set()
    for want in exp.get("plots", []):
        cands = [i for i, p in enumerate(plots) if i not in used and plot_name(p[0], want["name"])]
        src = want.get("input_source")
        if src:  # repeated .tf plots: the one whose impedance column names the source
            named = [i for i in cands if any(n.lower().startswith(f"{src.lower()}#input_impedance") or
                                             n.lower().startswith(f"v({src.lower()})#input_impedance") for n in plots[i][1])]
            cands = named or cands
        if not cands:
            out.append((f"plot {want['name']}", False, "got=missing want=present"))
            continue
        used.add(cands[0])
        try:
            out += judge_plot(want, plots[cands[0]])
        except (KeyError, ValueError) as e:
            out.append((f"plot {want['name']}", False, f"got={e} want=columns present"))
    for check in exp.get("checks", []):
        kind = check["kind"]
        if kind == "measure":
            out.append((f"measure {check['name']}", *measure(stdout, check)))
        elif kind == "repeatability":
            out.append(("repeatability", *repeatable(check, plots, again)))
        elif kind == "stderr_line":
            out.append(("stderr_line", *stderr_line(stderr, check)))
        elif kind in PLOT_CHECKS:
            label = f"{kind} {check.get('column') or check.get('axis') or ''}".strip()
            try:
                out.append((label, *PLOT_CHECKS[kind](check, plots)))
            except (KeyError, ValueError, TypeError, ZeroDivisionError) as e:
                out.append((label, False, f"got={e}"))
        else:  # unsupported fails, never skips
            out.append((f"check {kind}", False, f"unported check kind {kind}"))
    return out


def main():
    cmd, measure_cmd = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None
    src, work = os.environ["CONFORM_SRC"], os.environ["CONFORM_WORK"]
    env = dict(os.environ, DECK=os.path.basename(src))
    expected = os.path.splitext(src)[0] + ".expected.json"
    oracle = None
    if os.path.exists(expected):
        oracle = json.load(open(expected))
        env.update(RAW=os.path.join(work, "result.raw"), TOKENIZER=oracle.get("tokenizer") or "ngspice")

    def run(command, env):
        r = subprocess.run(["sh", "-c", command], cwd=os.path.dirname(src), env=env, capture_output=True, text=True, errors="replace")
        sys.stderr.write(r.stderr)
        return r

    def read(path):
        return open(path, "rb").read() if os.path.exists(path) else b""
    p = run(cmd, env)
    if oracle is None:
        sys.stdout.write(p.stdout)
        sys.exit(p.returncode)
    raw, stdout, again = read(env["RAW"]), p.stdout, b""
    kinds = {c["kind"] for c in oracle["expect"].get("checks", [])}
    if "repeatability" in kinds:
        # The same command to a fresh file, so a missing second result cannot reuse the first.
        second = os.path.join(work, "again.raw")
        if os.path.exists(second):
            os.remove(second)
        run(cmd, dict(env, RAW=second))
        again = read(second)
    if measure_cmd and reads_stdout(oracle["expect"]):
        del env["RAW"]
        stdout = run(measure_cmd, env).stdout
    for label, ok, detail in judge(oracle, p.returncode, stdout, raw, again, p.stderr):
        print(f"{label} {detail} ok={int(ok)}")


def selftest():
    hdr = b"Title: t\nPlotname: Transient Analysis\nFlags: real\nNo. Variables: 2\nNo. Points: 3\nVariables:\n\t0\ttime\ttime\n\t1\tv(out)\tvoltage\nBinary:\n"
    raw = hdr + struct.pack("<6d", 0, 0, 1, 2, 2, 4)
    tol = {"rtol": 1e-6, "atol": 1e-12}
    def oracle(match, **kw):
        return {"expect": {"status": "success", "plots": [dict(name="transient analysis", match=match, **kw)],
                           "checks": [{"kind": "measure", "name": "vmax", "value": 4, **tol}]}}
    exact = oracle("exact", row_count=3, columns={"V(OUT)": dict(values=[0, 2, 4], **tol)})
    assert all(ok for _, ok, _ in judge(exact, 0, "vmax = 4.0e+00 at 2", raw))
    samples = oracle("samples", axis=dict(name="time", values=[0.5, 1.5], **tol), columns={"v(out)": dict(values=[1, 3], **tol)})
    assert all(ok for _, ok, _ in judge(samples, 0, "vmax = 4", raw))
    wrong = oracle("exact", row_count=3, columns={"v(out)": dict(values=[0, 2, 5], **tol)})
    assert [ok for _, ok, _ in judge(wrong, 0, "vmax = 4", raw)] == [False, True]
    unordered = oracle("unordered", row_count=3, columns={"v(out)": dict(values=[4, 0, 2], **tol)})
    assert all(ok for _, ok, _ in judge(unordered, 0, "vmax = 4", raw))
    assert judge({"expect": {"status": "error"}}, 1, "", b"")[0][1]
    assert not judge({"expect": {"status": "error"}}, 0, "", b"")[0][1]
    assert not judge(exact, 0, "", b"")[0][1]  # no raw file
    # ngspice 44.2's line for 4*sqrt(6) (tran/meas_param_expr) passes at
    # rtol 1e-12 by half a unit of its sixth digit, and no more.
    exact4 = {"kind": "measure", "name": "c", "value": 9.797958971132712, "rtol": 1e-12, "atol": 0}
    ok, detail = measure("c                   =  9.79796e+00\n", exact4)
    assert ok and detail.endswith("printed channel: 6 digits"), detail
    assert not measure("c = 9.79797e+00\n", exact4)[0]
    # A second run equal bit for bit passes; one ulp off, or no file, fails.
    twice = {"expect": {"status": "success", "checks": [{"kind": "repeatability", "same_netlist": True, "comparison": "bitwise_numeric_results"}]}}
    assert judge(twice, 0, "", raw, raw)[0][1]
    assert not judge(twice, 0, "", raw, raw[:-8] + struct.pack("<d", math.nextafter(4, 5)))[0][1]
    assert not judge(twice, 0, "", raw, b"")[0][1]
    assert judge({"expect": {"status": "success", "checks": [{"kind": "bogus"}]}}, 0, "", raw) == [("check bogus", False, "unported check kind bogus")]
    plot_checks_selftest(raw)
    print("rawcheck selftest: ok")


def plot_checks_selftest(raw):
    """One pass and one fail per ported kind, each answer derived by hand."""
    def plot(name, names, rows, cplx=False):
        return (name, names, len(rows), cplx, [[complex(v) for v in row] for row in rows])

    def verdict(check, plots):
        return PLOT_CHECKS[check["kind"]](check, plots)[0]
    # The time axis 0..4 lies in [0, 4], not in [0, 3.5].
    tran = plot("Transient Analysis", ["time", "v(1)"], [[0, 1], [1, -1], [2, 1], [3, -1], [4, 1]])
    bounds = {"kind": "axis_bounds", "plot": "Transient Analysis", "axis": "time", "minimum": 0, "maximum": 4}
    assert verdict(bounds, [tran]) and not verdict(dict(bounds, maximum=3.5), [tran])
    # Phases 179 and -170 deg are -179 and 190 deg less 2 and 0 deg, mod 360.
    four = plot("Fourier Analysis (THD = 5 %)", ["harmonic", "magnitude", "phase_deg"], [[0, 0.5, 0], [1, 1, 179], [2, 0.03, -170], [3, 0.04, 0]])
    phases = {"kind": "selected_values", "plot": "Fourier Analysis", "axis": "harmonic", "coordinates": [1, 2], "column": "phase_deg",
              "values": [-179, 190], "atol": 3, "period": 360}
    assert verdict(phases, [four]) and not verdict(dict(phases, atol=1), [four])
    # THD = 100 sqrt(0.03^2 + 0.04^2) / 1 = 5 %; the DC row is no harmonic.
    thd = {"kind": "fourier_thd", "percent_min": 4.99, "percent_max": 5.01}
    assert verdict(thd, [four]) and not verdict(dict(thd, percent_min=5.01, percent_max=6), [four])
    # 1, 2, 3, 4: mean 2.5, sample stddev sqrt(5/3) = 1.291 (the population's is 1.118).
    mc = plot("Monte Carlo", ["v(out)"], [[1], [2], [3], [4]])
    moments = {"kind": "sample_moments", "plot": "Monte Carlo", "column": "v(out)", "row_count": 4,
               "mean_min": 2.49, "mean_max": 2.51, "stddev_min": 1.29, "stddev_max": 1.30}
    assert verdict(moments, [mc]) and not verdict(dict(moments, stddev_min=1.1, stddev_max=1.2), [mc])
    # The +-1 triangle over [0.5, 4]: the first trapezoid runs from v(0.5) = 0
    # to -1, so the mean is -0.25 / 3.5 = -0.0714 and the variance, from the
    # trapezoids of the samples' squares, (0.25 + 3) / 3.5 - 0.0714^2 = 0.9235.
    weighted = {"kind": "time_weighted_moments", "plot": "Transient Analysis", "column": "v(1)", "time_window": [0.5, 4],
                "min_points": 4, "mean_abs_max": 0.072, "variance_min": 0.92, "variance_max": 0.93}
    assert verdict(weighted, [tran]) and not verdict(dict(weighted, mean_abs_max=0.07), [tran])
    # A 0..1 triangle of period 2: rising 0.5 crossings at 0.5, 2.5, 4.5, 6.5.
    tri = plot("Transient Analysis", ["time", "v(1)"], [[t, t % 2] for t in range(8)])
    osc = {"kind": "oscillation", "plot": "Transient Analysis", "column": "v(1)", "level": 0.5, "time_window": [0, 7],
           "period": 2, "period_rtol": 1e-3, "swing": 1, "swing_rtol": 1e-3}
    assert verdict(osc, [tri]) and not verdict(dict(osc, period=2.2), [tri])
    # ngspice's layout: one row of pole(k), zero(k) columns, in any order.
    pz = plot("Pole-Zero Analysis", ["pole(1)", "pole(2)", "zero(1)"], [[-1, -2 + 1j, -3]], cplx=True)
    roots = {"kind": "pole_zero_sets", "plot": "Pole-Zero Analysis", "poles": [[-2, 1], [-1, 0]], "zeros": [[-3, 0]],
             "rtol": 1e-6, "atol": 1e-9, "multiplicity": True}
    assert verdict(roots, [pz]) and not verdict(dict(roots, zeros=[[-3.1, 0]]), [pz])
    # ngspice 44.2's `.four` listing (its layout, these numbers): the fundamental
    # at 30 deg, THD 100 sqrt(0.03^2 + 0.04^2) / 1 = 5 %; a raw holds no such plot.
    table = ("Fourier analysis for v(out):\n  No. Harmonics: 4, THD: 5 %, Gridsize: 200, Interpolation Degree: 1\n\n"
             "Harmonic Frequency   Magnitude   Phase       Norm. Mag   Norm. Phase\n"
             "-------- ---------   ---------   -----       ---------   -----------\n"
             " 0       0           0.5         0           0           0          \n"
             " 1       1000        1           30          1           0          \n"
             " 2       2000        0.03        -170        0.03        -200       \n"
             " 3       3000        0.04        0           0.04        -30        \n\n")
    fourier = {"expect": {"status": "success", "checks": [dict(phases, coordinates=[1], values=[30], atol=0.25), thd]}}
    assert [ok for _, ok, _ in judge(fourier, 0, table, raw)] == [True, True]
    assert [ok for _, ok, _ in judge(fourier, 0, "", raw)] == [False, False]
    two = fourier_plots(table + table.replace("v(out)", "v(b)"))
    assert [p[0] for p in two] == ["Fourier Analysis v(out) (THD = 5 %)", "Fourier Analysis v(b) (THD = 5 %)"]
    line = {"expect": {"status": "success", "checks": [{"kind": "stderr_line", "prefix": "note: seam"}]}}
    assert judge(line, 0, "", raw, stderr="warning: x\nnote: seam 4 of 11\n")[0][1]
    assert not judge(line, 0, "", raw, stderr="warning: x\n  note: seam 4 of 11\n")[0][1]


if __name__ == "__main__":
    selftest() if sys.argv[1:] == ["--selftest"] else main()
