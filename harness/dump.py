"""Dumps: every test's full output from one tool, and the manifest of a set.

    python3 -m harness -t tools/ngspice.conf -d results/dumps/ngspice ...   (Writer)
    python3 -m harness.dump manifest results/dumps [TOOL=WHY]...              (manifest)

One tool's dump directory (README.md, "Dumps"):
    tool.json         the tool: name, version, how it was obtained, config hash
    records.jsonl     one JSON object per test the tool ran, in test-name order
    raw/<test>.raw    a SPICE deck's result as one canonical binary raw file

A set is a directory of tool dump directories; `manifest` writes its
manifest.json over them: the suite commit, each tool, each deck's sha256 and
each dump's sha256.

Contents:
    Writer(directory, config_path, tool)   .add(name, status, ms, why, record), .close()
    manifest(directory, unavailable) -> dict
"""
import datetime
import hashlib
import json
import os
import subprocess
import sys

FORMAT = 1


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
                     "obtained": os.environ.get("CONFORM_TOOL_SOURCE", "the tool on PATH"),
                     "config": os.path.basename(config_path), "config_sha256": sha256_file(config_path),
                     "date": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}

    def add(self, name, status, ms, why, record):
        """A test's record; a test no stage of the tool ran (no command for its language) has none."""
        stages = [s for s in record if s[0] != "result.raw"]
        if not stages:
            return
        out = {"test": name, "verdict": status, "detail": why, "ms": ms, "stages": [
            {"stage": n, "exit": s.status, "ms": s.ms, "stdout": s.out, "stderr": s.err} for n, s in stages]}
        raw = next((data for n, data in record if n == "result.raw"), None)
        if raw is not None:
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
    the tools named in `unavailable` (name -> why) as slots with no dump."""
    suite = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    commit = subprocess.run(["git", "-C", suite, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    tools, decks, dumps = {}, {}, {}
    for name in sorted(os.listdir(directory)):
        d = f"{directory}/{name}"
        if not os.path.isfile(f"{d}/tool.json"):
            continue
        tools[name] = dict(json.load(open(f"{d}/tool.json")), available=True)
        dumps[name] = {}
        with open(f"{d}/records.jsonl", "rb") as f:
            for line in f:
                rec = json.loads(line)
                dumps[name][rec["test"]] = hashlib.sha256(line.rstrip(b"\n")).hexdigest()
                decks.setdefault(rec["test"], None)
    for name, why in unavailable.items():
        tools.setdefault(name, {"tool": name, "available": False, "why": why})
    for test in decks:
        decks[test] = source_sha256(suite, test)
    return {"format": FORMAT, "suite": "https://github.com/OpenFAT/VAMS-Conformance-Suite", "suite_commit": commit,
            "date": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "tools": tools, "decks": decks, "dumps": dumps}


# ---- private ----

def sha256_file(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def source_sha256(suite, test):
    """The test's source: `tests/<name>`, or a manifest row's `<manifest>/<source>` under the manifest's #root."""
    path = f"{suite}/tests/{test}"
    if not os.path.isfile(path):
        stem, _, rel = test.partition("/")
        m = f"{suite}/external/{stem}.manifest"
        root = next((l[6:].strip() for l in open(m) if l.startswith("#root ")), None) if os.path.isfile(m) else None
        path = f"{suite}/external/{root}/{rel}"
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
