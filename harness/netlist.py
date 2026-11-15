"""A SPICE deck run by one tool and judged against its `.expected.json`.

    run_deck(tool, src, work, env, timeout, record, run_stage) -> Stage

In: the deck, the tool's `sim.netlist` command (and `measure.netlist`,
`dialect`, `reads`). Out: a Stage whose stdout holds one `ok=` line per
oracle check, which conform judges like any self-checking test; without an
oracle, the simulator's own stage (an external manifest deck, judged by its
gold). The judge ports ESPice's tests/test_correctness.zig `runCase`
(the schema's semantics live there), tool-neutral where ESPice reads its own
output (README.md, "SPICE decks", lists the differences). The result raw
file, canonicalised, goes into `record` for a dump.

Contents:
    run_deck(tool, src, work, env, timeout, record, run_stage) -> Stage
    parse_raw(data, strict=True) -> [Plot]
    write_raw(plots, title) -> bytes
    fourier_plots(stdout) -> [Plot]
    judge(oracle, rc, stdout, raw, again=b"", stderr="", source=None, measures=None) -> [(label, ok, detail)]
"""
import hashlib
import json
import math
import os
import struct

from harness import checks
from harness.checks import fourier_plots, judge_plot


def run_deck(tool, src, work, env, timeout, record, run_stage):
    """The deck through `sim.netlist`, translated first when its dialect is
    not one the tool reads (`sprack project --from <d> --to <dialect>`)."""
    from harness.conform import Stage
    expected = os.path.splitext(src)[0] + ".expected.json"
    oracle = json.load(open(expected)) if os.path.exists(expected) else None
    source = (oracle or {}).get("tokenizer") or "ngspice"
    target = tool.get("dialect") or "ngspice"
    cwd, deck = os.path.dirname(src), os.path.basename(src)
    env = dict(env, DECK=deck, TOKENIZER=source)
    if source != target and source not in (tool.get("reads") or "").split():
        kit = f"{work}/kit"
        t = run_stage(f'sprack project --from {source} --to {target} --out "{kit}" "$DECK"', work, "translate", env,
                      timeout, cwd=cwd)
        record.append(("translate", t))
        if t.status != 0:
            # sprack's exit 1 is a construct it cannot express: the deck's refusal.
            refused = t.status == 1
            return Stage(1 if refused else t.status, "", t.err + (f"\nError: {deck}: SprackRefused\n" if refused else ""))
        cwd, env = kit, dict(env, TOKENIZER=target)
    sim = tool.command("sim", "netlist")
    if oracle is None:  # judged by a gold file: the simulator's stdout passes through
        s = run_stage(sim, work, "sim", env, timeout, cwd=cwd)
        record.append(("sim", s))
        return s
    raw = f"{work}/result.raw"
    env["RAW"] = raw
    first = run_stage(sim, work, "sim", env, timeout, cwd=cwd)
    record.append(("sim", first))
    if first.status == 77:  # the tool cannot express this deck
        return first
    data, stdout, again = read(raw), first.out, b""
    kinds = {c.get("kind") for c in oracle.get("expect", {}).get("checks", [])}
    if "repeatability" in kinds:  # the same command to a fresh file, so a missing second result cannot reuse the first
        second = f"{work}/again.raw"
        record.append(("again", run_stage(sim, work, "again", dict(env, RAW=second), timeout, cwd=cwd)))
        again = read(second)
    measure = tool.command("measure", "netlist")
    if measure and checks.reads_stdout(oracle.get("expect", {})):
        m = run_stage(measure, work, "measure", {k: v for k, v in env.items() if k != "RAW"}, timeout, cwd=cwd)
        record.append(("measure", m))
        stdout = m.out
    try:
        record.append(("result.raw", write_raw(parse_raw(data, strict=False) + fourier_plots(stdout), deck)))
    except (ValueError, KeyError, struct.error):
        if data:
            record.append(("result.raw", data))  # unreadable: kept as the tool wrote it
    measures = json.loads(read(raw + ".json") or b"null")
    lines = judge(oracle, first.status, stdout, data, again, first.err, read(src), measures)
    return Stage(0, "".join(f"{label} {detail} ok={int(ok)}\n" for label, ok, detail in lines), first.err, first.ms)


def read(path):
    try:
        with open(path, "rb") as f:
            return f.read()
    except OSError:
        return b""


def parse_raw(data, strict=True):
    """[(plotname, [column names], rows, complex, values[row][col])] from
    concatenated binary raw plots. `strict`, as test_correctness.zig
    `parseRaw`: a duplicate column, a flag other than real/complex or a
    non-finite value is an error."""
    plots, pos = [], 0

    def line():
        nonlocal pos
        end = data.index(b"\n", pos)
        text = data[pos:end].decode(errors="replace").strip(" \t\r")
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
            k, colon, v = t.partition(":")
            if not colon:
                raise ValueError("raw: invalid header")
            head[k.strip().lower()] = v.strip(" \t")
        cols, rows, flags = int(head["no. variables"]), int(head["no. points"]), head["flags"].lower()
        if flags not in ("real", "complex") and strict:
            raise ValueError(f"raw: unsupported flags {flags}")
        cplx = flags == "complex"
        if cols == 0 or cols > len(data):
            raise ValueError("raw: invalid header")
        names = []
        for i in range(cols):
            fields = line().split()
            if len(fields) != 3 or int(fields[0]) != i:
                raise ValueError("raw: invalid variable line")
            names.append(fields[1])
        if strict and len({n.lower() for n in names}) != cols:
            raise ValueError("raw: duplicate column")
        if line().lower() != "binary:":
            raise ValueError("raw: not a binary raw file")
        width = 2 if cplx else 1
        n = rows * cols * width
        if n * 8 > len(data) - pos:
            raise ValueError("raw: truncated")
        vals = struct.unpack_from(f"<{n}d", data, pos)
        if strict and not all(map(math.isfinite, vals)):
            raise ValueError("raw: non-finite output")
        pos += n * 8
        table = [[complex(vals[(r * cols + c) * 2], vals[(r * cols + c) * 2 + 1]) if cplx else complex(vals[r * cols + c], 0)
                  for c in range(cols)] for r in range(rows)]
        plots.append((head["plotname"], names, rows, cplx, table))
    if not plots:
        raise ValueError("raw: no plots")
    return plots


def write_raw(plots, title):
    """The plots as one canonical binary raw file: the header lines a reader
    needs and nothing tool-specific (no Date, no Command), little-endian f64,
    every column typed `real`."""
    out = []
    for name, names, rows, cplx, table in plots:
        out.append(f"Title: {title}\nPlotname: {name}\nFlags: {'complex' if cplx else 'real'}\nNo. Variables: {len(names)}\n"
                   f"No. Points: {rows}\nVariables:\n".encode())
        out += [f"\t{i}\t{n}\treal\n".encode() for i, n in enumerate(names)]
        out.append(b"Binary:\n")
        flat = [x for row in table for v in row for x in ((v.real, v.imag) if cplx else (v.real,))]
        out.append(struct.pack(f"<{len(flat)}d", *flat))
    return b"".join(out)


def judge(oracle, rc, stdout, raw, again=b"", stderr="", source=None, measures=None):
    """[(label, ok, detail)] for the whole oracle. `again` is a second run's
    raw file (repeatability); `source` the deck's bytes, against
    `netlist_sha256`; `measures` the tool's exact `.meas` values when it
    writes them (ESPice's `--measures`), else measures are read as printed."""
    out = []
    if source is not None and hashlib.sha256(source).hexdigest() != oracle.get("netlist_sha256"):
        out.append(("netlist_sha256", False, "got=a deck whose hash the oracle does not record want=its recorded hash"))
    try:
        checks.validate(oracle)
    except (ValueError, KeyError, TypeError) as e:
        return out + [("oracle", False, f"got=invalid oracle: {e}")]
    exp = oracle["expect"]
    if exp["status"] == "error":
        return out + [("rejected with a diagnostic", 1 <= rc <= 125, f"got=exit {rc} want=exit 1-125")]
    if rc != 0:
        return out + [("simulation succeeded", False, f"got=exit {rc} want=exit 0")]
    try:
        plots = parse_raw(raw) + fourier_plots(stdout)
    except (ValueError, KeyError, OSError, struct.error) as e:
        return out + [("raw file", False, f"got={e} want=a binary raw file")]
    used = set()
    for want in exp.get("plots", []):
        i = checks.choose_plot(plots, want, used)
        if i is None:
            out.append((f"plot {want['name']}", False, "got=missing want=present"))
            continue
        used.add(i)
        try:
            out += judge_plot(want, plots[i])
        except (KeyError, ValueError) as e:
            out.append((f"plot {want['name']}", False, f"got={e} want=columns present"))
    for check in exp.get("checks", []):
        kind = check["kind"]
        if kind == "measure":
            out.append((f"measure {check['name']}", *checks.measure(stdout, check, measures)))
        elif kind == "display":
            out.append((f"display {check['name']}", *checks.display(stdout, check)))
        elif kind == "repeatability":
            out.append(("repeatability", *repeatable(plots, again)))
        elif kind == "stderr_line":
            hit = any(line.startswith(check["prefix"]) for line in stderr.split("\n"))
            out.append(("stderr_line", hit, f"got={'present' if hit else 'missing'} want=a stderr line starting {check['prefix']!r}"))
        elif kind in checks.PLOT_CHECKS:
            label = f"{kind} {check.get('column') or check.get('axis') or ''}".strip()
            try:
                out.append((label, *checks.PLOT_CHECKS[kind](check, plots)))
            except (KeyError, ValueError, TypeError, ZeroDivisionError) as e:
                out.append((label, False, f"got={e}"))
        else:  # unsupported fails, never skips
            out.append((f"check {kind}", False, f"unported check kind {kind}"))
    return out


def repeatable(first, again):
    """A second run of the same deck: its plots bitwise equal to the first's,
    names, row counts and every value (test_correctness.zig `repeatable`)."""
    try:
        second = parse_raw(again)
    except (ValueError, KeyError, struct.error) as e:
        return False, f"got={e} want=a second binary raw file"

    def bits(plots):
        return [(p[0].lower(), [n.lower() for n in p[1]], p[2], p[3],
                 b"".join(struct.pack("<2d", v.real, v.imag) for row in p[4] for v in row)) for p in plots]
    fourier = [p for p in first if p[0].lower().startswith("fourier analysis")]  # read off stdout, not the raw
    return bits([p for p in first if p not in fourier]) == bits(second), f"got={len(second)} plots want={len(first) - len(fourier)} bitwise equal"
