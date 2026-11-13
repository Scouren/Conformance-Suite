* VDMOS common-source noise against ngspice 44.2 (vdmosnoi.c:102-117): RD
* and RS thermal, channel thermal 4kT*(2/3)|gm| and flicker
* KF*|cd|^AF/(f*cox^2) with the cox of a 1e-7 m oxide, plus the loads.
* Expected results: ngspice_vdmos_cs.expected.json (ngspice-44.2)
* M1 runs saturated with LAMBDA; M2 (m=2) runs linear on its 1k load as
* two parallel copies: m multiplies the conductances, multiplies the gate
* capacitances as ngspice master does (2bc63e, 6bd5c2), and sums the
* copies' flicker. 44.2 divides the flicker by m and leaves the gate caps
* unscaled, so the golden is 44.2 running M2 as two m=1 instances. KF puts
* the 1/f corner near 10 kHz, so the sweep crosses it. The output is
* v(d1, d2).
* THETA stays 0: ngspice 44.2 degrades the mobility by THETA*vgs where 45
* (vdmosload.c:351-367) and vdmos.va use THETA*(vgs - von).
.options reltol=1e-6 abstol=1e-15 vntol=1e-9
vdd vdd 0 dc 10
vg g 0 dc 3 ac 1
rl1 vdd d1 100
m1 d1 g 0 vm
rl2 vdd d2 1k
m2 d2 g 0 vm m=2
.model vm vdmos vto=2 kp=0.05 rd=0.5 rs=0.2 lambda=0.01 kf=1e-22 af=1.2
.noise v(d1,d2) vg dec 3 10 100meg
.end
