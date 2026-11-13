* .sp over a balanced port: two portnum V cards on port number 1 (legs a
* and b, the first card's a the + leg, z0 = 50 each) and a single-ended
* port 2 at c, the circuit of hspice/lin_mixed_mode.sp. S, Y and Z are over
* the modes d1, s2, c1 against 100, 50 and 25 ohm; no donoise, so the sweep
* is the one a GPU lane precomputes. ngspice 44.2 refuses the deck
* ("duplicate port Index").
* Oracle: analytic (see the expected.json derivation).
* Expected results: balanced_mixed_mode.expected.json
Vp1_p a 0 dc 0 portnum 1 z0 50
Vp1_n b 0 dc 0 portnum 1 z0 50
Vp2 c 0 dc 0 portnum 2 z0 50
RA a 0 100
RB b 0 200
RAB a b 300
RAC a c 50
RC c 0 75
RBC b c 400
C1 c 0 1n
.sp lin 1 1meg 1meg
.end
