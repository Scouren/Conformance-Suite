* A diode card's VB and IK set BV and IKF, as BV and IKF do.
* Expected results: diode_card_vb.expected.json (ngspice-44.2)
* dio.c takes vb for BV and ik for IKF (IOPR; ngspice 44.2 showmod prints
* bv=5 and ikf=1e-3 for this d1). ESPice bound ik but dropped vb with no
* error, so gf180's dnwps, dnwpw and sc_diode cards (sm141064.ngspice) ran
* without breakdown. d1 and d2 must agree with ngspice and with each other.
.options reltol=1e-6 abstol=1e-15 vntol=1e-9

vin in 0 dc 0
r1 in a1 100
d1 a1 0 dvb
r2 in a2 100
d2 a2 0 dbv
.model dvb d is=1e-14 n=1.02 rs=2 vb=5 ibv=1e-4 ik=1e-3
.model dbv d is=1e-14 n=1.02 rs=2 bv=5 ibv=1e-4 ikf=1e-3

.dc vin -7 1 0.25
.end
