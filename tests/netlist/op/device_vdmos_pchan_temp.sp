* A P-channel VDMOS away from TNOM, once as `vdmos pchan` and once as the
* `vdmosp` kind (inpdomod.c:195-197).
* Expected results: device_vdmos_pchan_temp.expected.json (ngspice-44.2)
* TCVTH does not flip with the polarity: von = type*(VTO - type*TCVTH*dT)
* (vdmostemp.c:50, vdmosload.c:351), so at 77 degC both sit at |Vth| =
* 1 - 4m*50 = 0.8 V and sink 0.5*KP*(T/TNOM)^-1.5*(3 - 0.8)^2 = 1.921 A.
* Flipping TCVTH with the type gives |Vth| = 1.2 V and 1.286 A.
.temp 77
vd1 d1 0 -5
vd2 d2 0 -5
vg g 0 -3
m1 d1 g 0 vp1
m2 d2 g 0 vp2
.model vp1 vdmos pchan vto=-1 kp=1 tcvth=4m
.model vp2 vdmosp vto=-1 kp=1 tcvth=4m
.op
.end
