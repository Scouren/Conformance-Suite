"""The `.expected.json` schema's comparisons, each as ESPice's
tests/test_correctness.zig judges it, on plots read from a binary raw file.

A plot is `(name, [column names], rows, complex, values[row][col])`, every
value a Python complex. Each check returns `(ok, detail)`; a malformed oracle
or a missing plot, column or sample raises, and the caller reports it as a
failure.

Contents:
    validate(oracle)                       (test_correctness.zig validateOracle)
    choose_plot(plots, want, used) -> index | None
    judge_plot(want, plot) -> [(label, ok, detail)]
    measure(stdout, check, doc) -> (ok, detail)
    display(stdout, check) -> (ok, detail)
    fourier_plots(stdout) -> [plot]
    reads_stdout(expect) -> bool
    PLOT_CHECKS: kind -> check(check, plots) -> (ok, detail)
"""
import math
import re


def validate(oracle):
    """ValueError unless the oracle is well-formed schema version 1."""
    exp = oracle["expect"]
    if oracle.get("schema_version") != 1 or len(oracle.get("netlist_sha256") or "") != 64:
        raise ValueError("schema_version or netlist_sha256")
    if exp["status"] not in ("success", "error"):
        raise ValueError(f"status {exp['status']}")
    if exp["status"] == "error":
        if exp.get("category") is None:
            raise ValueError("an error oracle without a category")
        return
    plots, check_list = exp.get("plots", []), exp.get("checks", [])
    if not plots and not check_list:
        raise ValueError("empty oracle")
    for p in plots:
        mode, axis, rc = p["match"], p.get("axis"), p.get("row_count")
        if mode not in ("exact", "samples", "selected_rows", "unordered"):
            raise ValueError(f"match {mode}")
        if mode != "samples" and rc is None or mode == "samples" and axis is None:
            raise ValueError(f"plot {p['name']}: row_count or axis")
        count = len(p.get("row_indices", [])) if mode == "selected_rows" else len(axis["values"]) if axis else rc
        if mode in ("exact", "unordered") and count != rc:
            raise ValueError(f"plot {p['name']}: row count")
        if mode == "selected_rows":
            idx = p.get("row_indices", [])
            if any(i >= rc or k and i <= idx[k - 1] for k, i in enumerate(idx)):
                raise ValueError(f"plot {p['name']}: row_indices")
        if axis:
            tolerance(axis["rtol"], axis["atol"])
            vs = axis["values"]
            if len(vs) != count or not all(math.isfinite(v) for v in vs):
                raise ValueError(f"plot {p['name']}: axis values")
            if mode == "samples" and any(vs[i] <= vs[i - 1] for i in range(1, len(vs))):
                raise ValueError(f"plot {p['name']}: sample axis not increasing")
        for name, col in p["columns"].items():
            tolerance(col["rtol"], col["atol"])
            if len(col["values"]) != count:
                raise ValueError(f"plot {p['name']}: column {name} length")
            for v in col["values"]:
                scalar(v)
    for c in check_list:
        if c["kind"] not in KINDS:
            raise ValueError(f"unknown check kind {c['kind']}")


def choose_plot(plots, want, used):
    """The first unused plot of the name; with `input_source`, one whose
    `#input_impedance` column names that source, or one with no such column
    (test_correctness.zig `compare`)."""
    src = want.get("input_source")
    for i, p in enumerate(plots):
        if i in used or not plot_name(p[0], want["name"]):
            continue
        if src:
            named = [n[:n.index("#input_impedance")] for n in p[1] if "#input_impedance" in n]
            if named and not any(n.removeprefix("v(").lower() == src.lower() for n in named):
                continue
        return i
    return None


def judge_plot(want, plot):
    """[(label, ok, detail)] for one expected plot against its raw plot."""
    mode, axis, cols = want["match"], want.get("axis"), want["columns"]
    idx = {n: column(plot, n) for n in cols}
    if want.get("row_count") is not None and want["row_count"] != plot[2]:
        return [(f"{want['name']} rows", False, f"got={plot[2]} want={want['row_count']}")]
    if mode == "unordered":
        # Bipartite match, expected rows onto actual rows (augmenting paths).
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
    out = []
    rows = want.get("row_indices") if mode == "selected_rows" else None
    if axis:
        a = column(plot, axis["name"])
        if mode == "samples":
            increasing(plot, a)
        else:
            bad = [(j, plot[4][rows[j] if rows else j][a]) for j, v in enumerate(axis["values"])
                   if not close(plot[4][rows[j] if rows else j][a], complex(v, 0), axis["rtol"], axis["atol"])]
            out.append((f"{want['name']}:{axis['name']}", not bad, f"got={bad[0][1]} want={axis['values'][bad[0][0]]}" if bad else ""))
    for name, col in cols.items():
        c, first = idx[name], None
        for j, v in enumerate(col["values"]):
            if mode == "samples":
                got = sample(plot, column(plot, axis["name"]), c, axis["values"][j], axis["rtol"], axis["atol"])
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


def measure(stdout, check, doc):
    """The first stdout line `name = value ...`. With the tool's exact values
    (`doc`, ESPice's --measures JSON) the line must print the exact value
    rounded to 6 or 7 digits, and the exact value is judged, as
    test_correctness.zig `measure`. Without them the printed value is
    judged at the line's own accuracy: atol widens by half a unit in its
    last printed digit (ngspice prints a PARAM, WHEN, RMS or INTEG card at
    %.5e and the rest at %e; no option reaches it)."""
    tolerance(check["rtol"], check["atol"])
    token = printed(stdout, check["name"])
    if token is None:
        return False, f"got=missing want={check['value']:.9g}"
    if doc is not None:
        got = exact_value(doc, check["name"])
        if got is None:
            return False, "got=not in --measures (or the card failed)"
        if not printed_as(token, got):
            return False, f"got=printed {token} for {got!r} want=6 or 7 digits of it"
        return close(complex(got, 0), complex(check["value"], 0), check["rtol"], check["atol"]), \
            f"got={got:.17g} want={check['value']:.17g} exact channel"
    try:
        got = float(token)
    except ValueError:
        return False, f"got={token} want={check['value']:.9g}"
    mantissa, _, exponent = token.lower().partition("e")
    half = 0.5 * 10.0 ** (int(exponent or 0) - len(mantissa.partition(".")[2]))
    digits = sum(c.isdigit() for c in mantissa)
    ok = close(complex(got, 0), complex(check["value"], 0), check["rtol"], check["atol"] + half)
    return ok, f"got={got:.9g} want={check['value']:.9g} printed channel: {digits} digits"


def display(stdout, check):
    """An .hdl display task's stdout line `name = value`, as printed."""
    tolerance(check["rtol"], check["atol"])
    token = printed(stdout, check["name"])
    try:
        got = float(token)
    except (TypeError, ValueError):
        return False, f"got={token or 'missing'} want={check['value']:.9g}"
    return close(complex(got, 0), complex(check["value"], 0), check["rtol"], check["atol"]), f"got={got:.9g} want={check['value']:.9g}"


def fourier_plots(stdout):
    """Each `Fourier analysis for <output>:` table on stdout (ngspice's
    listing) as the plot ESPice writes for it: "Fourier Analysis[ <output>]
    (THD = t %)", the output named only when there are several, with the
    columns harmonic, frequency, magnitude and phase_deg."""
    blocks = re.findall(r"^Fourier analysis for (.+?):\n.*?THD: (\S+) %.*?\n-+[ -]*\n((?:[ \t]*\d[^\n]*\n?)+)", stdout, re.M | re.S)
    plots = []
    for output, thd, table in blocks:
        label = f" {output}" if len(blocks) > 1 else ""
        rows = [[complex(float(x), 0) for x in line.split()[:4]] for line in table.splitlines()]
        plots.append((f"Fourier Analysis{label} (THD = {thd} %)", ["harmonic", "frequency", "magnitude", "phase_deg"], len(rows), False, rows))
    return plots


def reads_stdout(exp):
    """A `measure` check or a Fourier plot: ngspice prints both only without -r."""
    found = exp.get("checks", [])
    names = [p["name"] for p in exp.get("plots", [])] + [c.get("plot", "") for c in found]
    return any(c["kind"] in ("measure", "fourier_thd") for c in found) or any(n.startswith("Fourier Analysis") for n in names)


# ---- private ----

KINDS = {"selected_values", "fourier_thd", "sample_moments", "repeatability", "pole_zero_sets", "axis_bounds",
         "time_weighted_moments", "oscillation", "measure", "stderr_line", "display"}


def canonical(name):
    """The spellings ngspice and espice use for the same `.tf` and branch-current column, folded."""
    n = name.lower()
    if n == "v(transfer_function)":
        return "transfer_function"
    if "#input_impedance" in n:
        return "input_resistance"
    if n.startswith("v(output_impedance_at_"):
        return "output_resistance"
    return n[:-7] if n.endswith("#branch") else n


def column(plot, name):
    """An exact name first (case-folded), then the one `canonical` alias."""
    for i, n in enumerate(plot[1]):
        if n.lower() == name.lower():
            return i
    hits = [i for i, n in enumerate(plot[1]) if canonical(n) == canonical(name)]
    if len(hits) != 1:
        raise KeyError(f"column {name}: {len(hits)} matches")
    return hits[0]


def close(got, want, rtol, atol):
    return abs(got - want) <= atol + rtol * abs(want)


def scalar(v):
    if isinstance(v, list):
        if len(v) != 2 or not all(isinstance(x, (int, float)) and math.isfinite(x) for x in v):
            raise ValueError("invalid oracle: a complex value")
        return complex(v[0], v[1])
    if isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v):
        raise ValueError("invalid oracle: a value")
    return complex(v, 0)


def tolerance(rtol, atol):
    if not (math.isfinite(rtol) and math.isfinite(atol) and rtol >= 0 and atol >= 0):
        raise ValueError("invalid oracle: tolerance")


def plot_name(actual, want):
    a, w = actual.lower(), want.lower()
    return a == w or (w.startswith("fourier analysis") and a.startswith(w) and a[len(w):].startswith(" (thd = "))


def increasing(p, axis):
    if not p[2]:
        raise ValueError("empty time axis")
    ts = [p[4][r][axis] for r in range(p[2])]
    if any(t.imag != 0 for t in ts) or any(ts[r].real <= ts[r - 1].real for r in range(1, len(ts))):
        raise ValueError("axis not increasing")
    return [t.real for t in ts]


def sample(plot, axis, col, t, rtol, atol):
    """Column `col` linearly interpolated at axis value `t`; an endpoint
    within tolerance of `t` covers it."""
    tab, rows = plot[4], plot[2]
    if not rows:
        raise ValueError("no samples")
    first, last = tab[0][axis].real, tab[rows - 1][axis].real
    if t < first or t > last:
        end = 0 if t < first else rows - 1
        if close(complex(tab[end][axis].real, 0), complex(t, 0), rtol, atol):
            return tab[end][col]
        raise ValueError(f"axis does not reach {t}")
    lo, hi = 0, rows - 1
    while hi - lo > 1:
        mid = lo + (hi - lo) // 2
        lo, hi = (mid, hi) if tab[mid][axis].real <= t else (lo, mid)
    if t == tab[lo][axis].real:
        return tab[lo][col]
    if t == tab[hi][axis].real:
        return tab[hi][col]
    f = (t - tab[lo][axis].real) / (tab[hi][axis].real - tab[lo][axis].real)
    x, y = tab[lo][col], tab[hi][col]
    return complex(x.real + f * (y.real - x.real), x.imag + f * (y.imag - x.imag))


def printed(stdout, name):
    """The first token after `=` on the first stdout line `name = ...`."""
    for text in stdout.split("\n"):
        lhs, eq, rest = text.partition("=")
        if eq and lhs.strip(" \t").lower() == name.lower():
            fields = rest.split()
            return fields[0] if fields else None
    return None


def exact_value(doc, name):
    """The exact value the line `name = ...` prints: an optimized parameter,
    a `.meas` result, or a Monte Carlo statistic's `mean(card)`,
    `sigma(card)`, `min(card)` or `max(card)`; None when absent or failed."""
    for r in doc.get("optimized", []) + doc.get("results", []):
        if r["name"].lower() == name.lower():
            return r.get("value")
    m = re.fullmatch(r"(mean|sigma|min|max)\((.*)\)", name, re.I)
    for s in doc.get("statistics", []) if m else []:
        if s.get("kind", "").lower() == "monte" and s.get("name", "").lower() == m.group(2).lower():
            return s.get(m.group(1).lower())
    return None


def printed_as(text, exact):
    """`text` is `exact` rounded: an integer exactly, else 6 or 7
    significant digits within half a unit of the last."""
    try:
        value = float(text)
    except ValueError:
        return False
    e = text.find("e")
    e = len(text) if e < 0 else e
    try:
        power = int(text[e + 1:]) if e < len(text) else 0
    except ValueError:
        return False
    digits = sum(c.isdigit() for c in text[:e])
    if "." not in text and "e" not in text:
        return value == exact
    return digits in (6, 7) and abs(value - exact) <= 0.5 * 10.0 ** (power - digits + 1) * (1 + 1e-6)


def find_plot(plots, name):
    hits = [p for p in plots if plot_name(p[0], name)]
    if len(hits) != 1:
        raise ValueError(f"plot {name}: {len(hits)} matches")
    return hits[0]


def real(v, what):
    if v.imag != 0:
        raise ValueError(f"{what}: a complex value")
    return v.real


def between(name, value, lo, hi):
    if lo > hi:
        raise ValueError("invalid oracle: minimum above maximum")
    return math.isfinite(value) and lo <= value <= hi, f"{name} got={value:.9g} want=[{lo:.9g}, {hi:.9g}]"


def measured(name, got, want, rtol):
    tolerance(rtol, 0)
    return math.isfinite(got) and close(got, want, rtol, 0), f"{name} got={got:.9g} want={want:.9g} rtol={rtol:g}"


def first_failure(*results):
    return next((r for r in results if not r[0]), results[-1])


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
    """The trapezoid time average and variance over `time_window`, which the
    time axis must cover, with at least `min_points` samples in it."""
    p = find_plot(plots, check["plot"])
    a = column(p, "time")
    c, ts = column(p, check["column"]), increasing(p, a)
    start, stop = check["time_window"]
    if stop <= start:
        raise ValueError("invalid oracle: empty window")
    slack = 1e-12  # a `10u` t_stop parses one ulp short of a literal 1e-5
    if ts[0] > start + slack * abs(start) or ts[-1] < stop - slack * abs(stop):
        return False, f"time got=[{ts[0]:.9g}, {ts[-1]:.9g}] want=[{start:.9g}, {stop:.9g}]"
    count, integral, square = 0, 0.0, 0.0
    for r, t in enumerate(ts):
        count += start <= t <= stop
        if r == 0:
            continue
        left, right = max(start, ts[r - 1]), min(stop, t)
        if left >= right:
            continue
        v0, v1 = real(sample(p, a, c, left, 0, 0), check["column"]), real(sample(p, a, c, right, 0, 0), check["column"])
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


PLOT_CHECKS = {"axis_bounds": axis_bounds, "selected_values": selected_values, "fourier_thd": fourier_thd,
               "sample_moments": sample_moments, "time_weighted_moments": time_weighted_moments,
               "oscillation": oscillation, "pole_zero_sets": pole_zero_sets}
