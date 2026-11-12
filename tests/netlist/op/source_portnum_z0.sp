* A portnum V carries its z0 in series in every analysis, not only in .sp
* (ngspice 44.2 vsrcload.c/vsrcacld.c stamp 1/z0 from n+ to an internal
* `#res` node the ideal source drives). V1 (1 V, AC 1, z0 = 50) into
* R1 = 50: v(a) = 0.5 V and i(v1) = -10 mA at the operating point, and
* v(a) = 0.5 at 1 kHz; an ideal source would hold v(a) at 1. V2 steps
* 0 -> 1 V through its z0 = 1k into C2 = 1n: v(b) = 1 - exp(-t / 1 us).
* Oracle: ngspice 44.2 (provenance in the expected.json); the values match
* the closed forms above.
* Expected results: source_portnum_z0.expected.json
V1 a 0 dc 1 ac 1 portnum 1 z0 50
R1 a 0 50
V2 b 0 pulse(0 1 0 1p 1p 1 2) portnum 2 z0 1k
C2 b 0 1n
.op
.ac lin 1 1k 1k
.tran 10n 3u
.end
