"""conform: run the suite's tests against one tool and judge each one.

    python3 -m harness -t TOOL.conf [-j N] [-x XFAIL] [-T SECONDS] [-M BYTES]
                       [-o RESULTS.tsv] [-d DUMPDIR] [-k] [-v] PATH...

The tool is a config file of shell commands, one per stage and language
(README.md, "Tool configs"). The harness never interprets the testbench
directives a tool reads (`//! bias`, `//! analysis`, ...); it decides the
verdict from exit statuses, `ok=` lines and expected outputs (a SPICE
deck's `.expected.json` is judged by the tool's run stage, tools/rawcheck.py,
which prints one `ok=` line per check). Every stage runs under a memory cap.
With `-d` every test's full output is kept (harness/dump.py). Output and the
results file follow test-name order, whatever -j is.

Contents:
    main(argv) -> int
"""
import getopt
import os
import re
import resource
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field

from harness import dump

PASS, FAIL, SKIP, ACCEPT = range(4)  # ACCEPT: compiled, run stage absent
NAMES = ["PASS", "FAIL", "SKIP", "PASS"]
META = {"lrm", "inherited", "lrm-reject", "inherited-reject", "neighbour", "reject", "reject-only", "warn", "nowarn"}
WORD = re.compile(r"[A-Za-z0-9_.+-]+")
MSG = 511  # conform.c's detail buffer, less its NUL


class Die(Exception):
    """A usage or setup error: conform exits 2."""


@dataclass
class Tool:
    """A config's `key = command` pairs in file order, and its directory."""
    keys: list
    dir: str

    def command(self, stage, lang):
        """`stage.lang`, falling back to the last `stage.*`."""
        fallback = None
        for key, cmd in self.keys:
            if key == f"{stage}.{lang}":
                return cmd
            if key == f"{stage}.*":
                fallback = cmd
        return fallback

    def get(self, key):
        return next((cmd for k, cmd in self.keys if k == key), None)


@dataclass
class Test:
    name: str
    path: str = None  # a file test
    row: str = None  # a manifest test: its row, and the directory its paths start at
    mroot: str = None


@dataclass
class Spec:
    reject: bool = False
    reject_run: bool = False
    exit_want: int = 0
    checks_want: int = -1
    needs_run: bool = False
    self_checks: bool = False
    passed: bool = False
    stdout_want: list = field(default_factory=list)
    stderr_want: list = field(default_factory=list)
    vcd_out: str = None
    vcd_gold: str = None
    gold: str = ""
    errgold: str = ""
    filter: str = None
    rtol: float = 0.0
    atol: float = 0.0
    env: dict = field(default_factory=dict)  # CONFORM_* a file's `//@` lines or a row's columns set; None unsets


@dataclass
class Stage:
    status: int  # exit code, -1 signal, -2 timeout, -3 killed at the memory cap
    out: str
    err: str
    ms: int = 0


def main(argv):
    try:
        return run(argv)
    except Die as e:
        print(f"conform: {e}", file=sys.stderr)
        return 2


def run(argv):
    sys.stdout.reconfigure(errors="surrogateescape")
    try:
        opts, paths = getopt.gnu_getopt(argv, "t:j:x:T:M:o:d:kv")
    except getopt.GetoptError:
        usage()
    tool_path = results = dump_dir = None
    jobs, timeout, keep, verbose, xfails = min(4, os.cpu_count() or 1), 120, False, False, set()
    cap = 4 << 30
    for o, a in opts:
        if o == "-t":
            tool_path = a
        elif o == "-j":
            jobs = atoi(a) if atoi(a) > 0 else 1
        elif o == "-x":
            xfails |= load_xfails(a)
        elif o == "-T":
            timeout = atoi(a) if atoi(a) > 0 else 1
        elif o == "-M":
            cap = parse_bytes(a)
        elif o == "-o":
            results = a
        elif o == "-d":
            dump_dir = a
        elif o == "-k":
            keep = True
        elif o == "-v":
            verbose = True
    if not tool_path or not paths:
        usage()
    tool = load_conf(tool_path)
    tests = []
    for p in paths:
        if not os.path.exists(p):
            raise Die(f"{p}: No such file or directory")
        if os.path.isdir(p):
            for d, dirs, files in os.walk(p):
                dirs.sort()
                for f in files:  # a symlink in a walk is no test (conform.c's FTW_PHYS)
                    if not os.path.islink(os.path.join(d, f)):
                        collect(os.path.join(d, f), tests)
        else:
            collect(p, tests)
    if not tests:
        raise Die("no tests found")
    tests.sort(key=lambda t: t.name.encode("utf-8", "surrogateescape"))
    limit_file_size()
    work_root = tempfile.mkdtemp(prefix="conform.", dir=os.environ.get("TMPDIR") or "/tmp")
    tsv = open(results, "w", encoding="utf-8", errors="surrogateescape") if results else None
    dumps = dump.Writer(dump_dir, tool_path, tool) if dump_dir else None
    tally = dict.fromkeys(["PASS", "FAIL", "SKIP", "XFAIL", "XPASS", "compile-only"], 0)
    ctx = Context(tool, work_root, timeout, keep, dumps, cap, capper(cap))
    with ThreadPoolExecutor(jobs) as pool:
        futures = [pool.submit(timed, ctx, t, i) for i, t in enumerate(tests)]
        for t, fut in zip(tests, futures):
            v, ms, why, record = fut.result()
            status, xf = NAMES[v], t.name in xfails
            if xf and v == FAIL:
                status = "XFAIL"
            elif xf and v in (PASS, ACCEPT):
                status, why = "XPASS", "expected to fail, passed"
            tally[status if status in ("XFAIL", "XPASS") else "compile-only" if v == ACCEPT else status] += 1
            if v == ACCEPT and not xf:
                why = "compile-only: the tool has no run command"
            if verbose or status not in ("PASS", "SKIP", "XFAIL"):
                print(f"{status:<5} {t.name}{': ' if why else ''}{why}", flush=True)
            if tsv:
                tsv.write(f"{status}\t{t.name}\t{ms}\t{why}\n")
            if dumps:
                dumps.add(t.name, status, ms, why, record)
    if tsv:
        tsv.close()
    if dumps:
        dumps.close()
    if not keep:
        try:
            os.rmdir(work_root)  # only empty when nothing failed
        except OSError:
            pass
    print(f"\n{len(tests)} tests: {tally['PASS']} passed, {tally['compile-only']} compile-only, {tally['FAIL']} failed, "
          f"{tally['SKIP']} skipped, {tally['XFAIL']} xfail, {tally['XPASS']} xpass")
    if tally["FAIL"] or tally["XPASS"]:
        print(f"work directories of failures: {work_root}")
    return int(bool(tally["FAIL"] or tally["XPASS"]))


@dataclass
class Context:
    tool: Tool
    work_root: str
    timeout: int
    keep: bool
    dumps: object
    cap: int  # bytes; 0: none
    wrap: list  # the argv prefix that enforces it


def timed(ctx, t, index):
    """(verdict, milliseconds, why, record): `record` holds every stage's output for a dump."""
    t0 = time.monotonic()
    record = []
    try:
        v, why = run_test(ctx, t, index, record)
    except Exception as e:  # conform.c: "harness child died"
        v, why = FAIL, f"harness child died: {e!r}"
    return v, int((time.monotonic() - t0) * 1000), why[:MSG], record


# ---- private ----

def usage():
    sys.stderr.write(
        "usage: conform -t TOOL.conf [-j N] [-x XFAIL] [-T SECONDS] [-o RESULTS.tsv] [-d DUMPDIR] [-k] [-v] PATH...\n"
        "  PATH      test files, directories under a suite root (tests/), or .manifest files\n"
        "  -t        the tool config: `stage.language = shell command` lines\n"
        "  -j        tests run in parallel (default min(4, CPUs))\n"
        "  -x        expected failures: one test name (as printed) per line\n"
        "  -T        per-stage timeout (default 120)\n"
        "  -M        per-stage memory cap, bytes or 512M/4G (default 4G; 0: none)\n"
        "  -o        write every verdict as `STATUS<TAB>name<TAB>milliseconds<TAB>detail`\n"
        "  -d        keep every test's full output in DUMPDIR (README.md, Dumps)\n"
        "  -k        keep every work directory (failures always keep theirs)\n"
        "  -v        print passing tests too\n")
    raise SystemExit(2)


def atoi(s):
    m = re.match(r"\s*([+-]?\d+)", s)
    return int(m.group(1)) if m else 0


def slurp(path):
    """The file as text up to its first NUL (a C string), bytes kept; None if unreadable."""
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError:
        return None
    return data.split(b"\0", 1)[0].decode("utf-8", "surrogateescape")


def load_conf(path):
    text = slurp(path)
    if text is None:
        raise Die(f"cannot read {path}")
    keys = []
    for line in text.split("\n"):
        s = line.strip(" \t\r\n")
        if not s or s.startswith("#"):
            continue
        key, eq, cmd = s.partition("=")
        if not eq:
            raise Die(f"{path}: expected `key = command`: {s}")
        keys.append((key.strip(" \t\r\n"), cmd.strip(" \t\r\n")))
    return Tool(keys, os.path.dirname(os.path.realpath(path)))


def load_xfails(path):
    text = slurp(path)
    if text is None:
        raise Die(f"cannot read {path}")
    names = set()
    for line in text.split("\n"):
        line = line.strip(" \t\r\n")
        if line and not line.startswith("#"):
            names.add(re.split(r"[ \t]", line, 1)[0])
    return names


def parse_bytes(s):
    m = re.fullmatch(r"(\d+)([KMG]?)i?B?", s.strip(), re.I)
    if not m:
        raise Die(f"-M {s}: not a size (4G, 512M, bytes)")
    return int(m.group(1)) << {"": 0, "k": 10, "m": 20, "g": 30}[m.group(2).lower()]


def human(n):
    for unit, shift in (("GiB", 30), ("MiB", 20), ("KiB", 10)):
        if n >= 1 << shift and n % (1 << shift) == 0:
            return f"{n >> shift} {unit}"
    return f"{n} bytes"


def capper(cap):
    """The argv prefix that holds a stage to `cap` bytes: a systemd user scope
    (MemoryMax, no swap, OOMPolicy=kill: past the cap the kernel kills the
    whole tree, the shell too, so the stage ends on SIGKILL), else
    ("rlimit", cap), an address-space limit on the shell and what it starts.
    Probed once; () for no cap. `--expand-environment=no`: systemd-run
    would otherwise expand `$VAR` in the command before the shell sees it."""
    if not cap:
        return ()
    scope = ("systemd-run", "--user", "--scope", "-q", "--expand-environment=no", "-p", f"MemoryMax={cap}", "-p", "MemorySwapMax=0", "-p", "OOMPolicy=kill",
             "--")
    try:
        if subprocess.run([*scope, "true"], capture_output=True, timeout=30).returncode == 0:
            return scope
    except (OSError, subprocess.TimeoutExpired):
        pass
    return ("rlimit", cap)


def limit_file_size():
    """A runaway tool (iverilog on an instance array whose width overflows)
    writes until the disk is full and takes the CI runner down with it; past
    256 MiB it gets SIGXFSZ and its stage fails. Children inherit the limit,
    SIGXFSZ's default action and SIGPIPE ignored, as conform.c's did."""
    signal.signal(signal.SIGXFSZ, signal.SIG_DFL)
    _, hard = resource.getrlimit(resource.RLIMIT_FSIZE)
    cap = 256 << 20 if hard == resource.RLIM_INFINITY else min(256 << 20, hard)
    try:
        resource.setrlimit(resource.RLIMIT_FSIZE, (cap, cap))
    except (ValueError, OSError):
        pass


# ---- discovery ----

def is_source(p):
    return p.endswith((".va", ".vams", ".v", ".c", ".sp"))


def sibling(path, suffix):
    """`<dir>/<stem><suffix>` beside `path`."""
    slash, dot = path.rfind("/"), path.rfind(".")
    return (path[:dot] if dot > slash else path) + suffix


def directive(line, marker):
    """The body of a line that, trimmed, starts with `marker`; None otherwise."""
    s = line.lstrip(" \t")
    return s[len(marker):].lstrip(" \t") if s.startswith(marker) else None


def is_test(path):
    if os.path.exists(sibling(path, ".expected.txt")) or os.path.exists(sibling(path, ".expected.json")):
        return True
    text = slurp(path)
    for line in (text or "").split("\n"):
        d = directive(line, "//!")
        if d and (d.startswith("design ") or not path.endswith(".c")):
            return True
    return False


def collect(path, tests):
    if "/include/" in path:
        return
    if path.endswith(".manifest"):
        return collect_manifest(path, tests)
    if not is_source(path) or not is_test(path):
        return
    found = locate(os.path.realpath(path))
    if not found:
        raise Die(f"{path}: not under a suite root (no include/ above it)")
    tests.append(Test(found[2], path=os.path.realpath(path)))


def collect_manifest(path, tests):
    """`#root DIR` (relative to the manifest), then one test per row:
    `lang<TAB>want<TAB>source[<TAB>gold|-][<TAB>KEY=VALUE...]`."""
    text = slurp(path)
    if text is None:
        raise Die(f"cannot read {path}")
    absolute = os.path.realpath(path)
    mdir, stem = os.path.dirname(absolute), os.path.basename(absolute).rsplit(".", 1)[0]
    root = None
    for line in text.split("\n"):
        if not line:
            continue
        if line.startswith("#root "):
            probe = f"{mdir}/{line[6:].strip(' \t\r\n')}"
            if not os.path.exists(probe):
                raise Die(f"{path}: root {probe} does not exist (git submodule update --init?)")
            root = os.path.realpath(probe)
            continue
        row = line.rstrip(" \t\r\n")
        if not row.strip(" \t") or line.startswith("#"):
            continue
        if root is None:
            raise Die(f"{path}: a row before #root")
        m = re.match(r"[^\t]+\t[^\t]+\t([^\t]+)", row)
        if not m:
            raise Die(f"{path}: bad row: {row}")
        tests.append(Test(f"{stem}/{m.group(1)}", row=row, mroot=root))


def locate(absolute):
    """(root, lang, rel): the suite root is the nearest ancestor holding
    `include/`; the language the directory right below it (a `.c` is `vpi`,
    a `.sp` `netlist`, wherever it is filed). None when there is none."""
    root = absolute
    while (s := root.rfind("/")) > 0:
        root = root[:s]
        if os.path.isdir(f"{root}/include"):
            rel = absolute[len(root) + 1:]
            if "/" not in rel:
                return None
            lang = "vpi" if absolute.endswith(".c") else "netlist" if absolute.endswith(".sp") else rel.split("/", 1)[0]
            return root, lang, rel
    return None


def app_of(absolute):
    """A design whose same-stem `.c` names it with `//! design` is that VPI
    application's input and shares its gold: it runs as the `.c`, never
    alone (a design run without its application tests nothing the gold
    describes)."""
    if absolute.endswith(".c"):
        return absolute
    c = sibling(absolute, ".c")
    want = os.path.basename(absolute)
    for line in (slurp(c) or "").split("\n"):
        d = directive(line, "//! design")
        if d is not None and d.startswith(want) and not d[len(want):].strip(" \t\r"):
            return c
    return absolute


# ---- one test ----

def parse(src, d):
    """A file test's Spec from its `//!` and `//@` lines."""
    text = slurp(src)
    if text is None:
        raise Broken("cannot read source")
    sp, exit_set, named = Spec(), False, ""
    sp.self_checks = "`CHECK" in text or "ok=" in text
    at = {"files": [], "libmap": [], "liblist": [], "std": [], "protect-keys": []}
    for line in text.split("\n"):
        body = directive(line, "//@")
        if body is not None:
            m = re.match(r"(\S{0,31})\s*([^\r]*)", body)
            kw, rest = m.group(1), m.group(2)
            if kw not in at:
                raise Broken(f"unknown directive //@ {kw}")
            words = rest.split() if kw in ("files", "libmap", "protect-keys") else [rest]
            at[kw] += [f"{d}/{w}" for w in words] if kw in ("files", "libmap", "protect-keys") else words
            continue
        body = directive(line, "//!")
        if not body:
            continue
        kw = re.match(r"[^ \t\r]*", body).group(0)
        arg = body[len(kw):].lstrip(" \t")
        if kw in ("reject", "reject-only"):
            sp.reject = True
        elif kw == "reject-run":
            sp.reject_run = True
        elif kw == "exit":
            sp.exit_want, exit_set = atoi(arg), True
        elif kw == "checks":
            sp.checks_want = atoi(arg)
        elif kw == "stdout" and len(sp.stdout_want) < 16:
            sp.stdout_want.append(arg.strip(" \t\r\n"))
        elif kw == "expect":
            if m := re.match(r"stdout\s*(\S{1,255})", arg):
                named = m.group(1)
            elif m := re.match(r"vcd\s*(\S++)\s*==\s*(\S+)", arg):
                sp.vcd_out, sp.vcd_gold = m.group(1), m.group(2)
            else:
                raise Broken(f"bad //! expect: {arg}")
        if kw not in META:
            sp.needs_run = True
    if sp.reject_run and not exit_set:
        sp.exit_want = -1  # any normal failure
    if named:  # a named gold that is not there is a broken test, not a gold-less one
        sp.gold = f"{d}/{named}"
        if not os.path.exists(sp.gold):
            raise Broken(f"//! expect stdout {named}: no such file")
    elif os.path.exists(sibling(src, ".expected.txt")):
        sp.gold = sibling(src, ".expected.txt")
    if os.path.exists(sibling(src, ".expected.stderr.txt")):
        sp.errgold = sibling(src, ".expected.stderr.txt")
    if sp.gold or sp.self_checks or src.endswith(".c"):
        sp.needs_run = True
    if os.path.exists(sibling(src, ".expected.json")):  # judged by ok= lines, one per oracle check
        sp.needs_run = sp.self_checks = True
    for kw, var in (("files", "FILES"), ("libmap", "LIBMAP"), ("liblist", "LIBLIST"), ("std", "STD"),
                    ("protect-keys", "PROTECT_KEYS")):
        sp.env[f"CONFORM_{var}"] = " ".join(at[kw]) if at[kw] else None
    return sp


def parse_row(row, mroot):
    """(Spec, lang, src) from a manifest row; KEY=VALUE columns become CONFORM_KEY."""
    col = [c for c in row.split("\t") if c][:32]
    if len(col) < 3:
        raise Broken(f"manifest row has {len(col)} columns")
    sp, want = Spec(), col[1]
    if want == "ok":
        sp.needs_run = True
    elif want == "passed":
        sp.needs_run = sp.passed = True
    elif want == "reject":
        sp.reject = True
    elif want == "reject-run":
        sp.reject_run = sp.needs_run = True
        sp.exit_want = -1
    elif want != "compile":
        raise Broken(f"unknown want `{want}`")
    if len(col) > 3 and "=" in col[3]:
        raise Broken(f"gold column is `{col[3]}`: write `-` before KEY=VALUE")
    if len(col) > 3 and col[3] != "-":
        sp.gold = f"{mroot}/{col[3]}"
    for c in col[4:]:
        key, eq, value = c.partition("=")
        if not eq:
            raise Broken(f"column `{c}` is not KEY=VALUE")
        sp.env[f"CONFORM_{key}"] = value
        if key == "FILTER":
            sp.filter = value
        elif key == "DIFF":  # OUT:GOLD, as `//! expect vcd OUT == GOLD`, GOLD from the root
            out, colon, gold = value.partition(":")
            if not colon:
                raise Broken(f"DIFF={value} is not OUT:GOLD")
            sp.vcd_out, sp.vcd_gold = out, f"{mroot}/{gold}"
        elif key == "STDERR" and len(sp.stderr_want) < 16:
            sp.stderr_want.append(value)
        elif key in ("RTOL", "ATOL"):
            setattr(sp, key.lower(), atof(value))
    return sp, col[0], f"{mroot}/{col[2]}"


class Broken(Exception):
    """A test that cannot be judged as written: its verdict is FAIL."""


def atof(s):
    m = re.match(r"\s*[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?", s)
    return float(m.group(0)) if m else 0.0


def run_test(ctx, t, index, record):
    """(verdict, why); `record` collects every stage run, for a dump."""
    try:
        if t.row:
            sp, lang, src = parse_row(t.row, t.mroot)
            root, rel = t.mroot, src[len(t.mroot) + 1:]
        else:
            src = app_of(t.path)
            found = locate(src)
            if not found:
                return FAIL, "not under a suite root"
            root, lang, rel = found
            sp = parse(src, os.path.dirname(src))
    except Broken as e:
        return FAIL, str(e)
    d = os.path.dirname(src)
    tool = ctx.tool
    cc, rc = tool.command("compile", lang), tool.command("run", lang)
    if not cc and not rc:
        return SKIP, f"tool has no command for {lang}"
    if sp.reject_run and not rc:
        return SKIP, "reject-run needs a run command"
    if not sp.reject and not sp.needs_run:
        rc = None if cc else rc  # accept test: compiling is enough
    compile_only = not sp.reject and not sp.needs_run and not cc  # the run may stop after compiling
    if sp.reject and not sp.needs_run and cc:
        rc = None

    work = f"{ctx.work_root}/{index}"
    os.makedirs(work, exist_ok=True)
    stem = os.path.basename(src)
    stem = stem.rsplit(".", 1)[0] if "." in stem else stem
    env = dict(os.environ, CONFORM_SRC=src, CONFORM_REL=rel, CONFORM_DIR=d, CONFORM_STEM=stem, CONFORM_WORK=work,
               CONFORM_LANG=lang, CONFORM_INCLUDE=root if t.row else f"{root}/include", CONFORM_TOOLDIR=tool.dir)
    for k, v in list(sp.env.items()) + [("CONFORM_COMPILE_ONLY", "1" if compile_only else None)]:
        if v is None:
            env.pop(k, None)
        else:
            env[k] = v
    if t.row:
        link_root(root, work)
    else:
        link_inputs(src, d, work)

    def stage(cmd, name):
        s = run_stage(cmd, work, name, env, ctx.timeout, ctx.wrap)
        record.append((name, s))
        return s

    verdict, why = judge_stages(ctx, sp, cc, rc, stage, d, work, env)
    if ctx.dumps:
        record += dump.collect(work)
    if verdict != FAIL and not ctx.keep:
        shutil.rmtree(work, ignore_errors=True)
    return verdict, why


def judge_stages(ctx, sp, cc, rc, stage, d, work, env):
    if cc:
        c = stage(cc, "compile")
        if c.status != 0:
            return (PASS, "") if sp.reject and diagnosed(c) else (FAIL, describe(c, "compile", ctx))
    if not rc:
        if sp.reject:
            return FAIL, "compiled cleanly; expected a rejection"
        return (ACCEPT if sp.needs_run else PASS), ""
    r = stage(rc, "run")
    if r.status == 77:  # the tool cannot express this testbench
        e = r.err or "run stage skipped (exit 77)"
        return SKIP, e.split("\n", 1)[0]
    if sp.reject or sp.reject_run:
        ok = r.status == sp.exit_want if sp.exit_want > 0 else diagnosed(r)
        if not ok:
            return FAIL, "ran cleanly; expected a rejection" if r.status == 0 else describe(r, "run", ctx)
        why = judge_output(d, work, sp, r, env, ctx)
        return (FAIL, why) if why else (PASS, "")
    if r.status != sp.exit_want:
        why = describe(r, "run", ctx)
        if 0 <= r.status < 126:
            e = r.err or r.out
            why += ": " + e.split("\n", 1)[0][:200]
        return FAIL, why
    why = judge_output(d, work, sp, r, env, ctx)
    return (FAIL, why) if why else (PASS, "")


def link_root(mroot, work):
    """Every top-level entry of a manifest's root, linked into the work
    directory: an upstream suite's tests read paths relative to its root."""
    for e in sorted(os.listdir(mroot)):
        if not e.startswith("."):
            try:
                os.symlink(f"{mroot}/{e}", f"{work}/{e}")
            except OSError:
                pass


def link_inputs(src, d, work):
    """Every file the source names that exists beside the test, linked into
    the work directory (`$readmemh("x.hex")`, `//! data x.bin`), so a test
    reads its inputs from the directory it runs in and its writes stay out of
    the tree.
    ponytail: names with a `/` are not linked; add when a test reads one."""
    for w in set(WORD.findall(slurp(src) or "")):
        if "." in w and w not in (".", "..") and len(w) < 256 and os.path.isfile(f"{d}/{w}"):
            try:
                os.symlink(f"{d}/{w}", f"{work}/{w}")
            except OSError:
                pass


def run_stage(cmd, work, name, env, timeout, wrap=(), cwd=None):
    """`cmd` under /bin/sh in `cwd` (default `work`), stdout and stderr to
    `work/<name>.stdout|.stderr`, killed with its process group at `timeout`.
    `wrap` (capper) caps its memory; a SIGKILL nobody here sent is the cap."""
    out, err = f"{work}/{name}.stdout", f"{work}/{name}.stderr"
    t0 = time.monotonic()
    rlimit = wrap[1] if wrap and wrap[0] == "rlimit" else None
    argv = (list(wrap) if not rlimit else []) + ["/bin/sh", "-c", cmd]
    try:
        with open(out, "wb") as o, open(err, "wb") as e:
            p = subprocess.Popen(argv, cwd=cwd or work, env=env, stdin=subprocess.DEVNULL, stdout=o, stderr=e,
                                 process_group=0, restore_signals=False,
                                 preexec_fn=(lambda: resource.setrlimit(resource.RLIMIT_AS, (rlimit, rlimit))) if rlimit else None)
    except OSError:
        return Stage(126, slurp(out) or "", slurp(err) or "")
    try:
        p.wait(timeout=timeout)
        status = p.returncode if p.returncode >= 0 else -3 if p.returncode == -signal.SIGKILL and wrap and not rlimit else -1
    except subprocess.TimeoutExpired:
        status = -2
    try:
        os.killpg(p.pid, signal.SIGKILL)  # the timed-out group, or stray background children
    except OSError:
        pass
    p.wait()
    return Stage(status, slurp(out) or "", slurp(err) or "", int((time.monotonic() - t0) * 1000))


def describe(s, name, ctx):
    if s.status == -2:
        return f"{name} timed out after {ctx.timeout}s"
    if s.status == -3:
        return f"{name} killed at the memory cap {human(ctx.cap)}"
    if s.status == -1:
        return f"{name} crashed (signal)" + (f" under the address-space cap {human(ctx.cap)}" if ctx.wrap[:1] == ("rlimit",) else "")
    if s.status >= 126:
        return f"{name} could not run the command (exit {s.status})"
    return f"{name} exited {s.status}"


def diagnosed(s):
    """A normal nonzero exit, not a crash, a timeout or a command the shell could not run."""
    return 1 <= s.status <= 125


def judge_output(d, work, sp, s, env, ctx):
    """Why the stage's transcript fails the Spec; "" when it passes."""
    if sp.gold:
        if sp.filter:
            got = run_stage(f"({sp.filter}) < '{work}/run.stdout'", work, "filtered-run", env, ctx.timeout, ctx.wrap).out
            want = run_stage(f"({sp.filter}) < '{sp.gold}'", work, "filtered-gold", env, ctx.timeout, ctx.wrap).out
        else:
            got, want = s.out, slurp(sp.gold)
        same = want is not None and (same_within(want, got, sp.rtol, sp.atol) if sp.rtol > 0 or sp.atol > 0 else want == got)
        if not same:
            return f"stdout differs from {os.path.basename(sp.gold)}"
    if sp.errgold:
        want = slurp(sp.errgold)
        if want is not None and want not in s.err:  # stderr also carries the tool's diagnostics
            return f"stderr lacks {os.path.basename(sp.errgold)}"
    if sp.passed and not passed_line(s.out):
        return "no PASSED line"
    for w in sp.stdout_want:
        if w not in s.out:
            return f'stdout lacks "{w}"'
    for w in sp.stderr_want:
        if w not in s.err:
            return f'stderr lacks "{w}"'
    bad, every = s.out.count("ok=0"), s.out.count("ok=")
    if bad:
        return f"{bad} of {every} assertion(s) reported ok=0"
    if sp.checks_want >= 0 and every != sp.checks_want:
        return f"expected exactly {sp.checks_want} ok= line(s), got {every}"
    if sp.self_checks and every == 0 and not sp.reject and not sp.reject_run:
        return "no assertion printed an ok= line"
    if sp.vcd_out:
        gold = sp.vcd_gold if sp.vcd_gold.startswith("/") else f"{d}/{sp.vcd_gold}"
        x, y = slurp(f"{work}/{sp.vcd_out}"), slurp(gold)
        if x is None or y is None or vcd_norm(x) != vcd_norm(y):
            return f"{sp.vcd_out} differs from {sp.vcd_gold}"
    return ""


def vcd_norm(text):
    """VCD tokens with the `$date` and `$version` bodies dropped (IEEE 1364
    §18.2.3.2, §18.2.3.8: tool-specific text)."""
    out, skip = [], False
    for t in re.split(r"[ \t\r\n]+", text):
        if not t or skip and t != "$end":
            continue
        skip = t in ("$date", "$version")
        out.append(t)
    return out


C_NUMBER = re.compile(r"[ \t\n\v\f\r]*[+-]?(\d+\.?\d*([eE][+-]?\d+)?|\.\d+([eE][+-]?\d+)?|inf(inity)?|nan(\([0-9A-Za-z_]*\))?"
                      r"|0[xX]([0-9a-fA-F]+\.?[0-9a-fA-F]*|\.[0-9a-fA-F]+)([pP][+-]?\d+)?)", re.I)


def strtod(s):
    """C strtod over the whole token; None when it is not one number."""
    if not C_NUMBER.fullmatch(s):
        return None
    t = s.strip().lower()
    return float.fromhex(t) if "0x" in t else float(t.split("(")[0])


def same_within(a, b, rtol, atol):
    """Same whitespace-separated tokens, where two numbers also match when
    |a - b| <= atol + rtol * max(|a|, |b|)."""
    xs, ys = re.split(r"[ \t\r\n]+", a.strip(" \t\r\n")), re.split(r"[ \t\r\n]+", b.strip(" \t\r\n"))
    xs, ys = [x for x in xs if x], [y for y in ys if y]
    for x, y in zip(xs, ys):
        if x == y:
            continue
        u, v = strtod(x), strtod(y)
        if u is None or v is None:
            return False
        m = abs(u) if abs(u) > abs(v) else abs(v)
        if abs(u - v) > atol + rtol * m:
            return False
    return len(xs) == len(ys)


def passed_line(out):
    for line in out.split("\n"):
        s = line.lstrip(" \t")
        if s[:6].lower() == "passed" and not s[6:].strip(" \t\r"):
            return True
    return False
