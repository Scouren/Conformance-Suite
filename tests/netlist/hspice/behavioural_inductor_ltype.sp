* HSPICE behavioural inductors: L='equation' under LTYPE=0 (the default)
* is v = L di/dt, under LTYPE=1 the flux L i (User Guide E-2010.12 ch. 8
* pp. 183-185: LTYPE "Default=0", 0 for an L of its own current, 1 for
* any other; the flux is the dual of CTYPE=1's charge q = C v, ch. 31
* pp. 986-988). Built as ngspice's L network, and for LTYPE=1 with the
* flux on the F twin.
* KNOWN GAP: spice2rack writes LTYPE=1, TC1 and DTEMP through on a behavioural L, whose ngspice network drops LTYPE and DTEMP and scales by 1+TC1(T-27); write the flux network and fold TC (SpiceRack row P3-144) (#TBD)
* Expected results: behavioural_inductor_ltype.expected.json
* Oracle (analytic): each inductor takes a current ramp i = k t,
* k = 1e3 A/s; L0 = 1m, v(ctl) = 1 + r t, r = 1e6/s.
*   la, L = L0 (1 + 500 i), i read through a 0 V sense source: v = L k
*   lb, la's L with M=2, TC1=1m, DTEMP=10 at .temp 75: the factor is
*     1 + 1m (75 + 10 - 25) = 1.06 from TNOM = 25 degC (Elements and Device
*     Models E-2010.12 p. 40) and M=2 inductors in parallel: v = 1.06 L k/2
*   lc, L = L0 v(ctl), LTYPE=1: v = d(L i)/dt = L0 k (1 + 2 r t)
*   ld, the same L with no LTYPE: v = L di/dt = L0 k (1 + r t)
* The 1e12 ohm leaks move v by under 1e-8 relative.
vctl ctl 0 pwl(0 1 2u 3)
ia 0 a pwl(0 0 2u 2m)
vsa a a2 0
la a2 0 l='1m*(1+500*i(vsa))'
ib 0 b pwl(0 0 2u 2m)
vsb b b2 0
lb b2 0 '1m*(1+500*i(vsb))' m=2 tc1=1m dtemp=10
ic 0 c pwl(0 0 2u 2m)
lc c 0 l='1m*v(ctl)' ltype=1
id 0 d pwl(0 0 2u 2m)
ld d 0 l='1m*v(ctl)'
rla a 0 1e12
rlb b 0 1e12
rlc c 0 1e12
rld d 0 1e12
.temp 75
.option reltol=1e-6 delmax=2n
.tran 1n 2u
.meas tran va1 find v(a) at=0.5u
.meas tran va2 find v(a) at=1.5u
.meas tran vb1 find v(b) at=0.5u
.meas tran vb2 find v(b) at=1.5u
.meas tran vc1 find v(c) at=0.5u
.meas tran vc2 find v(c) at=1.5u
.meas tran vd1 find v(d) at=0.5u
.meas tran vd2 find v(d) at=1.5u
.end
