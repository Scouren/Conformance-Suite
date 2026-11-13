* HSPICE behavioural capacitors, CTYPE=0 (the default): C='equation' is
* i = C dv/dt, never a charge (User Guide E-2010.12 ch. 8 pp. 176-183:
* CTYPE "Default=0"; p. 183 "Capacitor equations are not implicitly
* converted to charge equations"; under CTYPE=0 the amplitude of ch. 31
* pp. 986-988 keeps v as C steps). Built as ngspice's c= network.
* KNOWN GAP: spice2rack writes M, TC1 and DTEMP through on a behavioural C, whose ngspice network drops DTEMP and scales by 1/(1+TC1(T-27)); fold M(1+TC1 dT) into the equation (SpiceRack row P3-144) (#TBD)
* Expected results: behavioural_capacitor_ctype0.expected.json
* Oracle (analytic): each node takes a current ramp i = k t, k = 1e3 A/s,
* the charge Q = k t^2/2 from v = 0; C0 = 1n, v(ctl) = 1 + r t, r = 1e6/s.
*   ca, C = C0 (1 + v/2) of its own voltage: C0 (v + v^2/4) = Q, so
*     v = 2 (sqrt(1 + Q/C0) - 1)
*   cb (CTYPE=0) and cd (no CTYPE), C = C0 v(ctl): dv/dt = k t/C, so
*     v = (k/(C0 r^2)) (r t - ln(1 + r t)); CTYPE=1 gives 19% less at 1 us
*   cc, ca's C with M=2, TC1=1m, DTEMP=10 at .temp 75: the factor is
*     1 + 1m (75 + 10 - 25) = 1.06 from TNOM = 25 degC (Elements and Device
*     Models E-2010.12 p. 35), so v = 2 (sqrt(1 + Q/(2.12 C0)) - 1)
* The 1e12 ohm leaks move v by under 1e-8 relative.
vctl ctl 0 pwl(0 1 2u 3)
ia 0 a pwl(0 0 2u 2m)
ca a 0 '1n*(1+0.5*v(a))'
ib 0 b pwl(0 0 2u 2m)
cb b 0 c='1n*v(ctl)' ctype=0
ic 0 c pwl(0 0 2u 2m)
cc c 0 c='1n*(1+0.5*v(c))' m=2 tc1=1m dtemp=10
id 0 d pwl(0 0 2u 2m)
cd d 0 c='1n*v(ctl)'
rla a 0 1e12
rlb b 0 1e12
rlc c 0 1e12
rld d 0 1e12
.temp 75
.option reltol=1e-6 delmax=2n
.tran 1n 2u
.meas tran va1 find v(a) at=1u
.meas tran va2 find v(a) at=1.5u
.meas tran vb1 find v(b) at=1u
.meas tran vb2 find v(b) at=1.5u
.meas tran vc1 find v(c) at=1u
.meas tran vc2 find v(c) at=1.5u
.meas tran vd1 find v(d) at=1u
.meas tran vd2 find v(d) at=1.5u
.end
