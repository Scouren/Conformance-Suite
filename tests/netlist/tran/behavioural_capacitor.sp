* Behavioural capacitors: a C whose value reads v() is ngspice's G/R/C/V/B
* network for i = C(v) dv/dt (c=, inpcom.c:6979-7000 at a9da7bc), and one
* with q= its G/L/B network for i = dq/dt (inpcom.c:6948-6962).
* Expected results: behavioural_capacitor.expected.json
* Oracle (analytic): each node takes a current ramp i = k t, k = 1e3 A/s, so
* it holds the charge Q(t) = k t^2/2 from v = 0. With C(v) = C0 (1 + a v)
* (and q(v) = C0 (v + a v^2/2), the same charge), C0 = 1n, a = 0.5/V:
*   C0 (v + a v^2/2) = Q / s  =>  v = (sqrt(1 + 2 a Q/(s C0)) - 1)/a
* with s = 1 for ca and cb, s = 2/1.1 for cc (m = 2 in parallel, the B
* divided by its temperature factor 1 + tc1 dT = 1.1 at dT = 100 K,
* reciproctc=1, asrcload.c:41-52), and s = 2 for xd (the X card's m=2 on
* the q= network's G, inpcom.c:4250-4305). The 1e12 ohm leaks keep each
* node's DC solution defined and move v by under 1e-8 relative.
.subckt qsub p q
cq p q q={1n*(v(p,q)+0.25*v(p,q)*v(p,q))}
.ends
ia 0 a pwl(0 0 2u 2m)
ca a 0 c={1n*(1+0.5*v(a))}
ib 0 b pwl(0 0 2u 2m)
cb b 0 q={1n*(v(b)+0.25*v(b)*v(b))}
ic 0 c pwl(0 0 2u 2m)
cc c 0 {1n*(1+0.5*v(c))} m=2 tc1=1m
id 0 d pwl(0 0 2u 2m)
xd d 0 qsub m=2
rla a 0 1e12
rlb b 0 1e12
rlc c 0 1e12
rld d 0 1e12
.temp 127
.options reltol=1e-6
.tran 1n 2u 0 2n
.meas tran va1 find v(a) at=1u
.meas tran va2 find v(a) at=1.5u
.meas tran vb1 find v(b) at=1u
.meas tran vb2 find v(b) at=1.5u
.meas tran vc1 find v(c) at=1u
.meas tran vc2 find v(c) at=1.5u
.meas tran vd1 find v(d) at=1u
.meas tran vd2 find v(d) at=1.5u
.end
