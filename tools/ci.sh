#!/usr/bin/env bash
# Fetch the latest TOOL, run it over every test and manifest, and leave
# results/TOOL.tsv, results/TOOL.version and results/TOOL.log; with DUMPDIR,
# also the tool's full dump (README.md, "Dumps"). Needs Nix with flakes; run
# from the repository root with submodules checked out.
#   tools/ci.sh vera|openvaf|iverilog|verilator|ngspice|espice|xyce|vacask [DUMPDIR]
#
# "Latest" means: VerA and ESPice at their default branch's HEAD, OpenVAF-
# Reloaded at its newest GitHub release, VACASK and sprack as this flake
# locks them, the rest at nixpkgs-unstable's newest revision, resolved once
# so the dump names the exact one.
set -euo pipefail
tool=${1:?usage: tools/ci.sh TOOL [DUMPDIR]}
dump=${2:-}
mkdir -p results
rev=$(nix flake metadata --json github:NixOS/nixpkgs/nixpkgs-unstable | python3 -c 'import json,sys; print(json.load(sys.stdin)["locked"]["rev"])')
unstable=github:NixOS/nixpkgs/$rev
nix build .#sprack -o result-sprack
sprack_rev=$(python3 -c 'import json; print(json.load(open("flake.lock"))["nodes"]["sprack"]["locked"]["rev"])')
export PATH=$PWD/result-sprack/bin:$PATH
paths=(tests external/*.manifest)
in_shell=(nix shell "$unstable#python3")

case $tool in
vera)
  nix build github:OpenFAT/VerA -o result-tool
  export VERA=$PWD/result-tool/bin/vera
  # vera drives Zig at run time: run inside VerA's own dev shell.
  in_shell=(nix develop github:OpenFAT/VerA)
  source="github:OpenFAT/VerA $(nix flake metadata --json github:OpenFAT/VerA | python3 -c 'import json,sys; print(json.load(sys.stdin)["locked"]["rev"])')"
  ;;
espice)
  nix build github:OpenFAT/ESPice -o result-tool
  export ESPICE=$PWD/result-tool/bin/espice
  source="github:OpenFAT/ESPice $(nix flake metadata --json github:OpenFAT/ESPice | python3 -c 'import json,sys; print(json.load(sys.stdin)["locked"]["rev"])')"
  ;;
openvaf)
  # The flake's openvaf-r, with its source swapped for the newest release.
  tag=$(curl -sSfL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} https://api.github.com/repos/OpenVAF/OpenVAF-Reloaded/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')
  url=https://github.com/OpenVAF/OpenVAF-Reloaded/releases/download/$tag/openvaf-r-$tag-linux-x86_64.tar.gz
  nix build --impure -o result-tool --expr "(builtins.getFlake \"path:$PWD\").packages.x86_64-linux.openvaf-r.overrideAttrs (_: { version = \"$tag\"; src = builtins.fetchurl \"$url\"; })"
  in_shell=(nix shell "$unstable#python3" "$unstable#ngspice" "$PWD/result-tool")
  source="$url"
  ;;
vacask)
  nix build .#vacask -o result-tool
  in_shell=(nix shell "$unstable#python3" "$PWD/result-tool")
  source="this flake's vacask ($(nix eval --raw .#vacask.src.rev))"
  ;;
iverilog | ngspice | xyce)
  in_shell=(nix shell "$unstable#python3" "$unstable#$tool")
  source="$unstable#$tool"
  ;;
verilator)
  # verilator --binary runs make and a C++ compiler on what it writes.
  in_shell=(nix shell "$unstable#python3" "$unstable#verilator" "$unstable#gcc" "$unstable#gnumake")
  source="$unstable#verilator (with $unstable#gcc, #gnumake)"
  ;;
*)
  echo "unknown tool $tool" >&2
  exit 2
  ;;
esac

export CONFORM_TOOL_SOURCE="$source; sprack github:Scouren/SPRack $sprack_rev"
version=$("${in_shell[@]}" -c sh -c "$(sed -n 's/^version *= *//p' "tools/$tool.conf")" | head -1)
echo "$version" > "results/$tool.version"
# conform exits 1 on any FAIL: that is the measurement, not an error here.
"${in_shell[@]}" -c python3 -m harness -t "tools/$tool.conf" -T 120 -o "results/$tool.tsv" ${dump:+-d "$dump/$tool"} "${paths[@]}" > "results/$tool.log" || true
tail -3 "results/$tool.log"
