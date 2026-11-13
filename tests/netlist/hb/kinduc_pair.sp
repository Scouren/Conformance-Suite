* A K card on harmonic balance: a coupled pair, swept so the points batch
* Expected results: kinduc_pair.expected.json
* Linear, so the fundamental is the AC phasor of SIN(0 1 1meg), -j, and every
* other harmonic is zero. The two points share one pattern: under --backend
* cuda they run as one HB lane batch, whose sampled operator evaluates kinduc
* on the card.
.param rl=25
Vin in 0 SIN(0 1 1meg)
R1 in p1 10
L1 p1 0 1u
L2 p2 0 4u
R2 p2 0 {rl}
K1 L1 L2 0.5
.hb tones=1meg nharms=3 sweep rl poi 2 25 100
.end
