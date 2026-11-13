* Behavioural inductors: an L whose value reads i() is ngspice's F/L/B
* network, a v= B over a 1 H inductor's di/dt (inpcom.c:7048-7056).
* Expected results: behavioural_inductor.expected.json
* Oracle (analytic): each inductor takes a current ramp i = k t, k = 1e3 A/s,
* and its value reads that current through a 0 V sense source, so
*   v = L(i) di/dt / s = 1m (1 + 500 k t) k / s
* with s = 1 for la, s = 2/1.1 for lb (m = 2 divides, the temperature factor
* 1 + tc1 dT = 1.1 at dT = 100 K multiplies, reciproctc=0) and s = 2 for xc
* (the X card's m=2 reaches the divisor, inpcom.c:4250-4305). The 1e12 ohm
* leaks move v by under 1e-8 relative.
.subckt lsub p q
vs p p2 0
l1 p2 q {1m*(1+500*i(vs))}
.ends
ia 0 a pwl(0 0 2u 2m)
vsa a a2 0
la a2 0 l={1m*(1+500*i(vsa))}
ib 0 b pwl(0 0 2u 2m)
vsb b b2 0
lb b2 0 {1m*(1+500*i(vsb))} m=2 tc1=1m
ic 0 c pwl(0 0 2u 2m)
xc c 0 lsub m=2
rla a 0 1e12
rlb b 0 1e12
rlc c 0 1e12
.temp 127
.options reltol=1e-6
.tran 1n 2u 0 2n
.meas tran va1 find v(a) at=0.5u
.meas tran va2 find v(a) at=1.5u
.meas tran vb1 find v(b) at=0.5u
.meas tran vb2 find v(b) at=1.5u
.meas tran vc1 find v(c) at=0.5u
.meas tran vc2 find v(c) at=1.5u
.end
