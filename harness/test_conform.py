"""The harness fed a fake tool whose behaviour each test scripts beside itself
(<stem>.out is printed, <stem>.exit is the exit status). Every verdict is
known in advance; any other verdict fails. Oracle: the verdict rules in
README.md, one hand-built case per rule.

    python3 -m unittest discover -s harness -t .
"""
import hashlib
import json
import os
import struct
import subprocess
import sys
import tempfile
import unittest

SUITE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TOOL = r'''
run.verilog-a = cat "$CONFORM_DIR/$CONFORM_STEM.out" 2>/dev/null; s=$(cat "$CONFORM_DIR/$CONFORM_STEM.exit" 2>/dev/null || echo 0); [ "$s" = segv ] && kill -SEGV $$; [ "$s" = hang ] && sleep 30; exit $s
run.verilog = [ -z "$CONFORM_COMPILE_ONLY" ] || exit 0; cp "$CONFORM_DIR/$CONFORM_STEM.file" out.txt 2>/dev/null; cat "$CONFORM_DIR/$CONFORM_STEM.out" 2>/dev/null; cat "$CONFORM_DIR/$CONFORM_STEM.err" >&2 2>/dev/null; ${CONFORM_STD:+echo std=$CONFORM_STD}; ${CONFORM_PROTECT_KEYS:+echo keys=${CONFORM_PROTECT_KEYS##*/}}; exit $(cat "$CONFORM_DIR/$CONFORM_STEM.exit" 2>/dev/null || echo 0)
run.vpi = echo "$CONFORM_LANG $(basename "$CONFORM_SRC")"
'''

# A fake simulator behind rawcheck.py: copies <stem>.raw beside the deck to
# $RAW, prints <stem>.out, exits <stem>.exit; a deck in another dialect goes
# through a fake sprack that copies it and says so.
SIM = r'''
run.netlist = export SPRACK_TO=ngspice SPRACK="$CONFORM_TOOLDIR/sprack"; python3 "$SUITE/tools/rawcheck.py" '[ -f "${DECK%.*}.exit" ] && exit $(cat "${DECK%.*}.exit"); [ -n "$RAW" ] && cp "${DECK%.*}.raw" "$RAW"; cat "${DECK%.*}.out" 2>/dev/null; true'
version = echo fake 1.0
'''
SPRACK = r'''#!/bin/sh
# sprack project --from D --to T --out DIR DECK
[ "$3" = refuse ] && { echo "error[unsupported]: refused" >&2; exit 1; }
mkdir -p "$7"; for f in "${8%.*}".*; do cp "$f" "$7/"; done; echo "translated $3 to $5" >&2
'''

WANT = """
PASS	verilog-a/pass.va
FAIL	verilog-a/wrong_want.va
FAIL	verilog-a/checks_off_by_one.va
FAIL	verilog-a/no_assertion_ran.va
FAIL	verilog-a/run_failed.va
PASS	verilog-a/reject_ok.va
FAIL	verilog-a/reject_accepted.va
FAIL	verilog-a/reject_crash.va
FAIL	verilog-a/reject_exit_139.va
PASS	verilog-a/reject_run_ok.va
PASS	verilog-a/exit_code.va
PASS	verilog-a/stdout_line.va
FAIL	verilog-a/timeout.va
XFAIL	verilog-a/xfail.va
XPASS	verilog-a/xpass.va
SKIP	verilog-a/tool_cannot.va
SKIP	spice/no_command.va
PASS	verilog/golden.v
PASS	verilog/app.v
PASS	verilog/app.c
FAIL	verilog/golden_diff.v
PASS	up/t/a.v
FAIL	up/t/b.v
PASS	up/t/c.v
FAIL	up/t/d.v
PASS	up/t/e.v
PASS	up/t/f.v
FAIL	up/t/g.v
PASS	up/t/h.v
FAIL	up/t/i.v
PASS	up/t/j.v
FAIL	up/t/k.v
PASS	verilog/named_gold.v
PASS	verilog/keys.v
FAIL	verilog/named_gold_missing.v
SKIP	verilog-a/deck.sp
"""


def conform(*args):
    return subprocess.run([sys.executable, "-m", "harness", *args], cwd=SUITE, capture_output=True, text=True,
                          env=dict(os.environ, SUITE=SUITE))


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def read(path, mode="r"):
    with open(path, mode) as f:
        return f.read()


def verdicts(tsv):
    return sorted(tuple(line.split("\t")[:2]) for line in read(tsv).splitlines())


class Verdicts(unittest.TestCase):
    maxDiff = None
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.t = self.tmp.name
        os.makedirs(f"{self.t}/s/include")

    def tearDown(self):
        self.tmp.cleanup()

    def case(self, d, name, directives, out, status):
        write(f"{self.t}/s/{d}/{name}.va", f"{directives}\nmodule {name}; endmodule\n")
        write(f"{self.t}/s/{d}/{name}.out", out)
        write(f"{self.t}/s/{d}/{name}.exit", f"{status}\n")

    def test_every_verdict(self):
        t, s = self.t, f"{self.t}/s"
        write(f"{t}/tool.conf", TOOL)
        write(f"{t}/compile-only.conf", "compile.verilog-a = exit 0\n")
        c = self.case
        c("verilog-a", "pass", '//! bias V(p) = 1\n`CHECK("x", 1, 1, 0);', "x ok=1\n", 0)
        c("verilog-a", "wrong_want", "//! bias V(p) = 1", "x ok=1\ny ok=0\n", 0)
        c("verilog-a", "checks_off_by_one", "//! checks 2", "x ok=1\n", 0)
        c("verilog-a", "no_assertion_ran", '//! lrm 4.1\n`CHECK("x", 1, 1, 0);', "", 0)
        c("verilog-a", "run_failed", "//! bias V(p) = 1", "", 1)
        c("verilog-a", "reject_ok", "//! reject E0001", "", 1)
        c("verilog-a", "reject_accepted", "//! reject E0001", "", 0)
        c("verilog-a", "reject_crash", "//! reject E0001", "", "segv")
        c("verilog-a", "reject_exit_139", "//! reject E0001", "", 139)  # a crash as the shell reports it: 128 + SIGSEGV
        c("verilog-a", "reject_run_ok", "//! reject-run out of range", "", 1)
        c("verilog-a", "exit_code", "//! exit 3", "", 3)
        c("verilog-a", "stdout_line", "//! stdout t=20 reached", "p: t=20 reached\n", 0)
        c("verilog-a", "timeout", "//! bias V(p) = 1", "", "hang")
        c("verilog-a", "xfail", "//! bias V(p) = 1", "ok=0\n", 0)
        c("verilog-a", "xpass", "//! bias V(p) = 1", "ok=1\n", 0)
        c("verilog-a", "tool_cannot", "//! bias V(p) = 1", "", 77)
        c("spice", "no_command", "//! bias V(p) = 1", "", 0)
        v = f"{s}/verilog"
        for name, text in {
            "golden.v": "module g; endmodule\n", "golden.expected.txt": "hi\n", "golden.out": "hi\n",
            "golden_diff.v": "module h; endmodule\n", "golden_diff.expected.txt": "hi\n", "golden_diff.out": "ho\n",
            "support_only.v": "module support; endmodule\n",
            # A design its same-stem VPI application names runs as that application.
            "app.v": "module app; endmodule\n", "app.c": "//! design app.v\n", "app.expected.txt": "vpi app.c\n",
            # `//! expect stdout F` names the gold; a name that is not there fails.
            "named_gold.v": "//! expect stdout named.gold.txt\nmodule n; endmodule\n", "named.gold.txt": "hi\n",
            "named_gold.out": "hi\n", "named_gold_missing.out": "hi\n",
            "named_gold_missing.v": "//! expect stdout gone.expected.txt\nmodule n; endmodule\n",
            # `//@ protect-keys F` reaches the tool as CONFORM_PROTECT_KEYS.
            "keys.v": "//@ protect-keys k.json\nmodule k; endmodule\n", "k.json": "{}\n", "keys.expected.txt": "keys=k.json\n",
        }.items():
            write(f"{v}/{name}", text)
        # A SPICE deck is `netlist` wherever it is filed (no command here: SKIP).
        write(f"{s}/verilog-a/deck.sp", "* deck\n.end\n")
        write(f"{s}/verilog-a/deck.expected.json", "{}\n")
        # An upstream-style suite driven by a manifest: its own gold, its own filter.
        up, mod = f"{t}/up", "module a; endmodule\n"
        for x in "abcdefghijk":
            write(f"{up}/t/{x}.v", mod)
        for name, text in {
            "t/a.out": "banner 1.0\nvalue 3\n", "gold/a.gold": "banner 2.0\nvalue 3\n",
            "t/b.out": "value 4\n", "gold/b.gold": "value 3\n", "t/c.out": "all\n PASSED\n", "t/d.out": "FAILED\n",
            # e: a row's STD= reaches the tool. f: a compile row's run is told it only compiles.
            "gold/e.gold": "std=1364-2005\n", "t/f.exit": "1\n",
            # j, k: STDERR= is text the run's stderr must hold, here a reject-run's diagnostic.
            "t/j.err": "error: budget\n", "t/j.exit": "1\n", "t/k.err": "error: budget\n", "t/k.exit": "1\n",
            # h, i: DIFF= judges the file the run writes (tokens, as a VCD).
            "t/h.file": "x 1\n", "gold/h.gold": "x  1\n", "t/i.file": "x 2\n", "gold/i.gold": "x  1\n",
        }.items():
            write(f"{up}/{name}", text)
        write(f"{s}/up.manifest", "#root ../up\n" + "".join("\t".join(r) + "\n" for r in [
            ("verilog", "ok", "t/a.v", "gold/a.gold", "FILTER=grep -v banner"),
            ("verilog", "ok", "t/b.v", "gold/b.gold", "FILTER=grep -v banner"),
            ("verilog", "passed", "t/c.v"), ("verilog", "passed", "t/d.v"),
            ("verilog", "ok", "t/e.v", "gold/e.gold", "STD=1364-2005"),
            ("verilog", "compile", "t/f.v"),
            # g: a KEY=VALUE in the gold column is a broken row, not a gold file.
            ("verilog", "compile", "t/g.v", "STD=1364-2005"),
            ("verilog", "ok", "t/h.v", "-", "DIFF=out.txt:gold/h.gold"),
            ("verilog", "ok", "t/i.v", "-", "DIFF=out.txt:gold/i.gold"),
            ("verilog", "reject-run", "t/j.v", "-", "STDERR=error: budget"),
            ("verilog", "reject-run", "t/k.v", "-", "STDERR=error: other")]))
        write(f"{t}/xfail", "verilog-a/xfail.va  # a known bug\nverilog-a/xpass.va\n")

        r = conform("-t", f"{t}/tool.conf", "-x", f"{t}/xfail", "-T", "2", "-j", "4", "-o", f"{t}/got.tsv", s)
        self.assertEqual(r.returncode, 1, r.stderr)
        self.assertEqual(verdicts(f"{t}/got.tsv"), sorted(tuple(l.split("\t")) for l in WANT.strip().split("\n")))
        r = conform("-t", f"{t}/compile-only.conf", "-o", f"{t}/compile.tsv", f"{s}/verilog-a/pass.va", f"{s}/verilog-a/reject_ok.va")
        self.assertEqual(verdicts(f"{t}/compile.tsv"), [("FAIL", "verilog-a/reject_ok.va"), ("PASS", "verilog-a/pass.va")])
        self.assertIn("compile-only", read(f"{t}/compile.tsv"))

    def test_order_ignores_jobs(self):
        """Determinism: -j 1 and -j 8 write the same lines in the same order (times aside)."""
        for i in range(24):
            self.case("verilog-a", f"t{i:02}", "//! bias V(p) = 1", "ok=1\n" if i % 3 else "ok=0\n", 0)
        write(f"{self.t}/tool.conf", TOOL)
        got = []
        for jobs in ("1", "8"):
            r = conform("-t", f"{self.t}/tool.conf", "-j", jobs, "-o", f"{self.t}/{jobs}.tsv", f"{self.t}/s")
            got.append((r.stdout.splitlines()[:-1], [l.split("\t")[:2] for l in read(f"{self.t}/{jobs}.tsv").splitlines()]))
        self.assertEqual(got[0], got[1])
        self.assertEqual(got[0][1], sorted(got[0][1], key=lambda l: l[1]))


def raw(names, rows):
    head = (f"Title: t\nDate: today\nPlotname: Transient Analysis\nFlags: real\nNo. Variables: {len(names)}\nNo. Points: {len(rows)}\n"
            "Variables:\n" + "".join(f"\t{i}\t{n}\tvoltage\n" for i, n in enumerate(names)) + "Binary:\n").encode()
    return head + struct.pack(f"<{len(names) * len(rows)}d", *[x for r in rows for x in r])


class Decks(unittest.TestCase):
    maxDiff = None
    """Decks judged by rawcheck.py against their .expected.json, translated
    when foreign, their results dumped."""

    def test_decks_and_dump(self):
        with tempfile.TemporaryDirectory() as t:
            write(f"{t}/sim.conf", SIM)
            write(f"{t}/sprack", SPRACK)
            os.chmod(f"{t}/sprack", 0o755)
            n = f"{t}/s/netlist"
            os.makedirs(f"{t}/s/include")

            def deck(name, oracle, raw_bytes=None, out="", status=None):
                text = f"* {name}\n.end\n"
                write(f"{n}/{name}.sp", text)
                oracle = dict(schema_version=1, netlist_sha256=hashlib.sha256(text.encode()).hexdigest(), **oracle)
                write(f"{n}/{name}.expected.json", json.dumps(oracle))
                if raw_bytes is not None:
                    with open(f"{n}/{name}.raw", "wb") as f:
                        f.write(raw_bytes)
                write(f"{n}/{name}.out", out)
                if status is not None:
                    write(f"{n}/{name}.exit", str(status))
            good = raw(["time", "v(out)"], [(0, 0), (1, 2), (2, 4)])
            tol = {"rtol": 1e-6, "atol": 1e-12}
            plot = {"name": "Transient Analysis", "match": "exact", "row_count": 3, "columns": {"v(out)": dict(values=[0, 2, 4], **tol)}}
            ok = {"expect": {"status": "success", "plots": [plot]}}
            deck("good", ok, good, out="sim says hi\n")
            deck("wrong", {"expect": {"status": "success", "plots": [dict(plot, columns={"v(out)": dict(values=[0, 2, 5], **tol)})]}}, good)
            deck("refused", {"expect": {"status": "error", "category": "unsupported_input"}}, status=1)
            deck("crashed", {"expect": {"status": "error", "category": "unsupported_input"}}, status=139)
            deck("cannot", ok, status=77)
            deck("foreign", dict(ok, tokenizer="hspice"), good)
            deck("untranslatable", dict(ok, tokenizer="refuse"), good)
            r = conform("-t", f"{t}/sim.conf", "-o", f"{t}/got.tsv", "-d", f"{t}/dump/sim", f"{t}/s")
            self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
            self.assertEqual(verdicts(f"{t}/got.tsv"), sorted([
                ("PASS", "netlist/good.sp"), ("FAIL", "netlist/wrong.sp"), ("PASS", "netlist/refused.sp"),
                ("FAIL", "netlist/crashed.sp"), ("FAIL", "netlist/cannot.sp"), ("PASS", "netlist/foreign.sp"),
                ("FAIL", "netlist/untranslatable.sp")]))
            # The dump: one record per deck in name order, the simulator's own
            # output in it, the canonical raw beside it, hashed.
            records = {x["test"]: x for x in map(json.loads, read(f"{t}/dump/sim/records.jsonl").splitlines())}
            self.assertEqual(list(records), sorted(records))
            g = records["netlist/good.sp"]
            self.assertEqual([(x["run"], x["exit"], x["stdout"]) for x in g["simulator"]], [("sim", 0, "sim says hi\n")])
            data = read(f"{t}/dump/sim/{g['raw']}", "rb")
            self.assertEqual(g["raw_sha256"], hashlib.sha256(data).hexdigest())
            self.assertNotIn(b"Date:", data)  # canonical: nothing tool- or run-specific
            self.assertEqual(data[data.index(b"Binary:\n") + 8:], good[good.index(b"Binary:\n") + 8:])
            f = records["netlist/foreign.sp"]
            self.assertEqual([x["run"] for x in f["simulator"]], ["translate", "sim"])
            self.assertIn("translated hspice to ngspice", f["simulator"][0]["stderr"])
            self.assertEqual(json.loads(read(f"{t}/dump/sim/tool.json"))["version"], "fake 1.0")
            from harness import dump
            m = dump.manifest(f"{t}/dump", {"hspice": "unavailable: licensed"})
            self.assertEqual(m["dumps"]["sim"]["netlist/good.sp"]["raw_sha256"], g["raw_sha256"])
            self.assertEqual(m["tools"]["hspice"], {"tool": "hspice", "available": False, "why": "unavailable: licensed"})


class Caps(unittest.TestCase):
    """A stage past the memory cap is a FAIL that says so, and the harness lives on."""

    def test_memory_cap(self):
        with tempfile.TemporaryDirectory() as t:
            write(f"{t}/s/include/.keep", "")
            write(f"{t}/s/verilog-a/hog.va", "//! bias V(p) = 1\nmodule hog; endmodule\n")
            write(f"{t}/s/verilog-a/fine.va", "//! bias V(p) = 1\nmodule fine; endmodule\n")
            # 256 MiB written page by page, far past a 64 MiB cap.
            write(f"{t}/tool.conf", 'run.verilog-a = [ "$CONFORM_STEM" = fine ] || python3 -c "b = b\'x\' * (256 << 20)"; echo ok=1\n')
            r = conform("-t", f"{t}/tool.conf", "-M", "64M", "-o", f"{t}/got.tsv", f"{t}/s")
            self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
            rows = {line.split("\t")[1]: line.split("\t") for line in read(f"{t}/got.tsv").splitlines()}
            self.assertEqual(rows["verilog-a/fine.va"][0], "PASS")
            self.assertEqual(rows["verilog-a/hog.va"][0], "FAIL")
            from harness import conform as c
            want = "run killed at the memory cap 64 MiB" if c.capper(64 << 20)[0] != "rlimit" else "MemoryError"
            self.assertIn(want, rows["verilog-a/hog.va"][3])


if __name__ == "__main__":
    unittest.main()
