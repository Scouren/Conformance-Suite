* A portnum V's z0 is in the circuit in .noise too, and noiseless (ngspice
* 44.2: vsrc has no noise routine). V1 (z0 = 50) drives v(a) through its z0
* against R1 = 50, so R1's 4kT/50 noise current sees 50 || 50 = 25 ohm:
* onoise = sqrt(4kT * 12.5) and the gain is 0.5, so inoise = 2 onoise.
* An ideal source would hold a (onoise = 0); a noisy z0 would give
* sqrt(4kT * 25).
* Oracle: ngspice 44.2 (provenance in the expected.json); the values match
* the closed forms above at 300.15 K.
* Expected results: source_portnum_z0.expected.json
V1 a 0 dc 0 ac 1 portnum 1 z0 50
R1 a 0 50
.noise v(a) V1 dec 1 1k 100k
.end
