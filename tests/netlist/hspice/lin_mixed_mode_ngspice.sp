* HSPICE .lin with a mixed-mode P element [SA Ch.17]: port 1 is balanced
* ngspice twin of hspice/lin_mixed_mode.sp (P1-062): the same circuit and oracle in ESPice's own dialect, port 1 as two portnum V cards on port number 1 (the first, at a, its + leg), as SpiceRack writes a mixed-mode P element.
* (legs a and b against ground, z0 = 50), port 2 single-ended at c. An
* asymmetric resistive network with 1 nF at c couples every mode, so the
* modes, in HSPICE's Touchstone order d1, s2, c1, all convert.
* Oracle: analytic (see the expected.json derivation).
* Expected results: lin_mixed_mode_ngspice.expected.json
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
.ac lin 1 1meg 1meg
.lin
.end
