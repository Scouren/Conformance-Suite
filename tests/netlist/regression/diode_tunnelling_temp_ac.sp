* A diode's tunnelling currents at 75 degC: XTITUN and KEG scale them on
* both TLEV arms, and the small signal carries their conductance.
* Expected results: diode_tunnelling_temp_ac.expected.json (ngspice-44.2)
* Origin: diode_tunnelling.sp's gf180 np_3p3 card with KEG = 0.8, once on
* TLEV 0 (diotemp.c:130-139) and once on TLEV 2 (diotemp.c:165-174), each
* at 4 V of reverse bias. The card has no junction capacitance, so the AC
* current is the junction's conductance, tunnelling included
* (dioload.c:352-372).
.options reltol=1e-6 abstol=1e-15 vntol=1e-9
.temp 75
v1 a 0 dc 4 ac 1
v2 b 0 dc 4 ac 1
d1 0 a dt0 area=100p pj=40u
d2 0 b dt2 area=100p pj=40u
.model dt0 d level=3 tref=25 is=2.2959e-7 jsw=2.1207e-13 n=1.01 bv=11 ibv=1e-3
+ jtun=1.1223e-5 jtunsw=6.4125e-12 ntun=10 xtitun=-25 keg=0.8
.model dt2 d level=3 tlev=2 tref=25 is=2.2959e-7 jsw=2.1207e-13 n=1.01 bv=11 ibv=1e-3
+ jtun=1.1223e-5 jtunsw=6.4125e-12 ntun=10 xtitun=-25 keg=0.8
.op
.ac dec 1 1k 1k
.end
