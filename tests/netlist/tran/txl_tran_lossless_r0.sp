* TXL (Y card) with r=0, as SpiceRack P8-049 wrote it: ESPice refused it
* (UnsupportedTransmissionLineParameters) and ngspice runs it. ReadTxL
* (txlsetup.c) makes a line with R/L < 5e5 and G < 1e-2 lossless (lsl):
* taul = sqrt(L C) len, Y0 = sqrt(C/L), unit propagation; txl.va's `lsl`
* branch is the same.
* Z0 = sqrt(250n/100p) = 50 ohm, sqrt(L C) = 5 ns/m. Both lines run between
* 50 ohm ends, so the far end is the near end's 0.5 V delayed and nothing
* reflects: Y1 (the model's 1 m) arrives at 5 ns, Y2 (its card's LEN=2 over
* the model's length=1, inp2y.c and ReadTxL) at 10 ns.
*   t =  3 ns: v(o1) = v(o2) = 0      t = 8 ns: v(o1) = 0.5, v(o2) = 0
*   t = 12 ns and 25 ns: v(o1) = v(o2) = 0.5
* ngspice also stamps 0.1 gmin on each port's row (txlload.c:62-73), which
* leaves -1.25e-12 V where the wave has not arrived.
* Expected results: txl_tran_lossless_r0.expected.json
V1 s1 0 PULSE(0 1 0 0.1n 0.1n 100n 200n)
Rs1 s1 i1 50
Y1 i1 0 o1 0 ymod
RL1 o1 0 50
V2 s2 0 PULSE(0 1 0 0.1n 0.1n 100n 200n)
Rs2 s2 i2 50
Y2 i2 0 o2 0 ymod LEN=2
RL2 o2 0 50
.model ymod txl r=0 l=250n g=0 c=100p length=1
.tran 0.1n 30n 0 0.1n
.meas tran o1_3 find v(o1) at=3n
.meas tran o2_3 find v(o2) at=3n
.meas tran o1_8 find v(o1) at=8n
.meas tran o2_8 find v(o2) at=8n
.meas tran o1_12 find v(o1) at=12n
.meas tran o2_12 find v(o2) at=12n
.meas tran o1_25 find v(o1) at=25n
.meas tran o2_25 find v(o2) at=25n
.end
