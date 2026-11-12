* TXL (Y card) on a lossless line shorter than ngspice's step: ESPice keeps
* every TXL step under 0.9 tau (txl.va), so each delayed read comes from
* accepted history. ngspice bounds no step on a lossless TXL (txlload.c:118
* tests !tx->lsl) and reads a delay that falls past its history by
* interpolating toward the unknowns it is solving for (txlload.c:221-228).
* No tmax: the default, min(tstep, (tstop - tstart)/50) = 0.8 ns
* (traninit.c:29-34), is longer than tau.
* Oracle: the exact delay line. Z0 = sqrt(25n/10p) = 50 ohm and
* tau = sqrt(25n * 10p) * 1 m = 0.5 ns; with 50 ohm at both ends nothing
* reflects, so v(out)(t) = 0.5 vs(t - 0.5 ns) for the 2 ns-ramp pulse vs:
* v(out) ramps over 0.5-2.5, 12.5-14.5, 20.5-22.5 and 32.5-34.5 ns.
*   t = 1.5 ns: 0.25    7 ns: 0.5    13 ns: 0.375   13.5 ns: 0.25    17 ns: 0
*   t = 21.5 ns: 0.25  27 ns: 0.5    33 ns: 0.375   33.5 ns: 0.25    37 ns: 0
* Every sample is at least 0.5 ns from a corner of v(out), so a grid of
* steps under 0.45 ns leaves .meas's linear interpolation exact. Tolerance
* 1e-5 V. ngspice 44.2 fails it at 13 ns (0.3751345 V) and 13.5 ns
* (0.2500637 V) and matches every other sample.
* Expected results: txl_tran_lossless_step_bound.expected.json
V1 s 0 PULSE(0 1 0 2n 2n 10n 20n)
Rs s in 50
Y1 in 0 out 0 ymod
RL out 0 50
.model ymod txl r=0 l=25n g=0 c=10p length=1
.tran 1n 40n
.meas tran o1_5 find v(out) at=1.5n
.meas tran o7 find v(out) at=7n
.meas tran o13 find v(out) at=13n
.meas tran o13_5 find v(out) at=13.5n
.meas tran o17 find v(out) at=17n
.meas tran o21_5 find v(out) at=21.5n
.meas tran o27 find v(out) at=27n
.meas tran o33 find v(out) at=33n
.meas tran o33_5 find v(out) at=33.5n
.meas tran o37 find v(out) at=37n
.end
