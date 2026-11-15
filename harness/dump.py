"""Dumps: every test's full output from one tool, and the manifest of a set.

    python3 -m harness -t tools/ngspice.conf -d results/dumps/ngspice ...      (Writer)
    python3 -m harness.dump manifest results/dumps [TOOL=WHY]...                 (manifest)

One tool's dump directory (README.md, "Dumps"):
    tool.json         the tool: name, version, where it came from, config hash
    records.jsonl     one JSON object per test the tool ran, in test-name order
    raw/<test>.raw    a SPICE deck's waveforms as one canonical binary raw file

A set is a directory of tool dump directories; `manifest` writes its
manifest.json over them: the suite commit, each tool, each deck's sha256 and
each dump's sha256.

Contents:
    collect(work) -> [(name, value)]       what a test's run left in its work directory
    Writer(directory, config_path, tool)   .add(name, status, ms, why, record), .close()
    write_raw(plots, title) -> bytes
    manifest(directory, unavailable) -> dict
"""
import datetime
import hashlib
import importlib.util
import json
import os
import struct
import subprocess
import sys

FORMAT = 1
SUITE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STREAM_CAP = 4 << 20  # bytes of one stdout or stderr kept; the rest is counted, not stored

_spec = importlib.util.spec_from_file_location("rawcheck", f"{SUITE}/tools/rawcheck.py")
rawcheck = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rawcheck)


def collect(work):
    """[(name, value)]: the result raw file a SPICE deck's run wrote
    (`result.raw`, canonical when it parses, else as written) and the
    simulator runs tools/rawcheck.py recorded (`sim.json`)."""
    out = []
    try:
        with open(f"{work}/result.raw", "rb") as f:
            data = f.read()
        try:
            data = write_raw(rawcheck.parse_raw(data), "result")
        except (ValueError, KeyError, IndexError, struct.error):
            pass  # unreadable: kept as the tool wrote it
        out.append(("result.raw", data))
    except OSError:
        pass
    try:
        with open(f"{work}/sim.json") as f:
            out.append(("sim.json", json.load(f)))
    except (OSError, ValueError):
        pass
    return out


def write_raw(plots, title):
    """The plots as one canonical binary raw file: the header lines a reader
    needs and nothing tool-specific (no Date, no Command), little-endian f64,
    every column typed `real`, so two runs that computed the same numbers
    write the same bytes."""
    out = []
    for name, names, rows, cplx, table in plots:
        out.append(f"Title: {title}\nPlotname: {name}\nFlags: {'complex' if cplx else 'real'}\nNo. Variables: {len(names)}\n"
                   f"No. Points: {rows}\nVariables:\n".encode())
        out += [f"\t{i}\t{n}\treal\n".encode() for i, n in enumerate(names)]
        out.append(b"Binary:\n")
        flat = [x for row in table for v in row for x in ((v.real, v.imag) if cplx else (v.real,))]
        out.append(struct.pack(f"<{len(flat)}d", *flat))
    return b"".join(out)


class Writer:
    """One tool's dump directory, filled in test-name order."""

    def __init__(self, directory, config_path, tool):
        os.makedirs(directory, exist_ok=True)
        self.dir, self.count = directory, 0
        self.records = open(f"{directory}/records.jsonl", "w", encoding="utf-8", errors="surrogateescape")
        version = tool.get("version")
        if version:
            v = subprocess.run(["/bin/sh", "-c", version], capture_output=True, text=True, errors="replace", cwd=tool.dir)
            version = (v.stdout or v.stderr).strip()
        self.tool = {"format": FORMAT, "tool": os.path.basename(config_path).rsplit(".", 1)[0], "version": version,
                     "source": os.environ.get("CONFORM_TOOL_SOURCE", "the tool on PATH"),
                     "config": os.path.basename(config_path), "config_sha256": sha256_file(config_path),
                     "date": now()}

    def add(self, name, status, ms, why, record):
        """A test's record; a test no stage of the tool ran (no command for its language) has none."""
        stages = [(n, s) for n, s in record if n not in ("result.raw", "sim.json")]
        if not stages:
            return
        out = {"test": name, "verdict": status, "detail": why, "ms": ms,
               "stages": [dict(stage=n, exit=s.status, ms=s.ms, **streams(s.out, s.err)) for n, s in stages]}
        extra = dict((n, v) for n, v in record if n in ("result.raw", "sim.json"))
        if "sim.json" in extra:  # the simulator's own runs, as rawcheck.py made them
            out["simulator"] = [dict(r, **streams(r.pop("stdout", ""), r.pop("stderr", ""))) for r in extra["sim.json"]]
        if "result.raw" in extra:
            raw = extra["result.raw"]
            out["raw"] = f"raw/{name}.raw"
            out["raw_sha256"] = hashlib.sha256(raw).hexdigest()
            os.makedirs(os.path.dirname(f"{self.dir}/{out['raw']}"), exist_ok=True)
            with open(f"{self.dir}/{out['raw']}", "wb") as f:
                f.write(raw)
        self.records.write(json.dumps(out, ensure_ascii=False, sort_keys=True) + "\n")
        self.count += 1

    def close(self):
        self.records.close()
        self.tool["records"] = self.count
        self.tool["records_sha256"] = sha256_file(f"{self.dir}/records.jsonl")
        with open(f"{self.dir}/tool.json", "w") as f:
            json.dump(self.tool, f, indent=1, sort_keys=True)
            f.write("\n")


def manifest(directory, unavailable):
    """The set's manifest.json: every tool dump directory under `directory`,
    and the tools in `unavailable` (name -> why) as slots with no dump."""
    commit = subprocess.run(["git", "-C", SUITE, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    tools, decks, dumps = {}, {}, {}
    for name in sorted(os.listdir(directory)):
        d = f"{directory}/{name}"
        if not os.path.isfile(f"{d}/tool.json"):
            continue
        with open(f"{d}/tool.json") as f:
            tools[name] = dict(json.load(f), available=True)
        dumps[name] = {}
        with open(f"{d}/records.jsonl", "rb") as f:
            for line in f:
                rec = json.loads(line)
                entry = {"record_sha256": hashlib.sha256(line.rstrip(b"\n")).hexdigest()}
                if "raw" in rec:
                    entry["raw_sha256"] = rec["raw_sha256"]
                dumps[name][rec["test"]] = entry
                decks.setdefault(rec["test"], None)
    for name, why in unavailable.items():
        tools.setdefault(name, {"tool": name, "available": False, "why": why})
    for test in decks:
        decks[test] = source_sha256(test)
    return {"format": FORMAT, "suite": "https://github.com/Scouren/Conformance-Suite", "suite_commit": commit,
            "date": now(), "tools": tools, "decks": decks, "dumps": dumps}


# ---- private ----

def streams(out, err):
    """stdout and stderr, each cut at STREAM_CAP bytes with its full size kept."""
    rec = {}
    for key, text in (("stdout", out), ("stderr", err)):
        b = text.encode("utf-8", "surrogateescape")
        rec[key] = b[:STREAM_CAP].decode("utf-8", "replace")
        if len(b) > STREAM_CAP:
            rec[f"{key}_bytes"] = len(b)
    return rec


def now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def source_sha256(test):
    """The test's source: `tests/<name>`, or a manifest row's `<manifest>/<source>` under the manifest's #root."""
    path = f"{SUITE}/tests/{test}"
    if not os.path.isfile(path):
        stem, _, rel = test.partition("/")
        m = f"{SUITE}/external/{stem}.manifest"
        root = None
        if os.path.isfile(m):
            with open(m) as f:
                root = next((line[6:].strip() for line in f if line.startswith("#root ")), None)
        path = f"{SUITE}/external/{root}/{rel}"
    return sha256_file(path) if os.path.isfile(path) else None


def main(argv):
    if len(argv) < 2 or argv[0] != "manifest":
        sys.exit("usage: python3 -m harness.dump manifest DIR [TOOL=WHY]...")
    unavailable = dict(a.split("=", 1) for a in argv[2:] if "=" in a)
    with open(f"{argv[1]}/manifest.json", "w") as f:
        json.dump(manifest(argv[1], unavailable), f, indent=1, sort_keys=True)
        f.write("\n")


if __name__ == "__main__":
    main(sys.argv[1:])
