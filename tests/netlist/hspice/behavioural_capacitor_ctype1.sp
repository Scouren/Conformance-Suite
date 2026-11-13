* HSPICE behavioural capacitors, CTYPE=1: a C='equation' of other nodes
* holds the charge q = C v (User Guide E-2010.12 ch. 8 p. 181; ch. 31
* pp. 986-988: C Vm = A C Vm' as C steps to A C, Figure 219). Built as
* ngspice's q= network over q = (equation)*v(n1,n2).
* KNOWN GAP: spice2rack writes CTYPE=1 through, which ngspice's behavioural C drops (i = C dv/dt); write q={(eq)*v(n1,n2)} with M and TC folded in (SpiceRack row P3-144) (Scouren/SpiceRack#24)
* Expected results: behavioural_capacitor_ctype1.expected.json
* Oracle (analytic): each node takes a current ramp i = k t, k = 1e3 A/s,
* the charge Q = k t^2/2 from v = 0; C = C0 v(ctl), C0 = 1n,
* v(ctl) = 1 + r t, r = 1e6/s.
*   ca: v = Q/C = k t^2/(2 C0 (1 + r t)); CTYPE=0 gives 23% more at 1 us
*   cb, ca's C with M=2, TC1=1m, DTEMP=10 at .temp 75: the factor is
*     1 + 1m (75 + 10 - 25) = 1.06 from TNOM = 25 degC (Elements and Device
*     Models E-2010.12 p. 35), so v = Q/(2.12 C)
*   cc, the card from e to c, e held at 0.5 V, the ramp into c: the charge
*     follows the card's node order, so v(c) = 0.5 + Q/C
* The 1e12 ohm leaks move v by under 1e-8 relative.
vctl ctl 0 pwl(0 1 2u 3)
ia 0 a pwl(0 0 2u 2m)
ca a 0 c='1n*v(ctl)' ctype=1
ib 0 b pwl(0 0 2u 2m)
cb b 0 c='1n*v(ctl)' ctype=1 m=2 tc1=1m dtemp=10
ve e 0 0.5
ic 0 c pwl(0 0 2u 2m)
cc e c c='1n*v(ctl)' ctype=1
rla a 0 1e12
rlb b 0 1e12
rlc c e 1e12
.temp 75
.option reltol=1e-6 delmax=2n
.tran 1n 2u
.meas tran va1 find v(a) at=1u
.meas tran va2 find v(a) at=1.5u
.meas tran vb1 find v(b) at=1u
.meas tran vb2 find v(b) at=1.5u
.meas tran vc1 find v(c) at=1u
.meas tran vc2 find v(c) at=1.5u
.end
