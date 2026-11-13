* VDMOS noise with THETA against ngspice 45: the channel's thermal noise
* reads gm, and THETA's mobility term is part of it (vdmosload.c:367-387).
* Expected results: ngspice_vdmos_theta.expected.json (ngspice-45)
* ngspice_vdmos_cs.sp's circuit at THETA = 0.1, where the term is 5% of
* gm. The oracle is ngspice 45, whose THETA*(vgs - von) vdmos.va follows;
* 44.2 degrades the mobility by THETA*vgs and sinks 15% less current here.
* M2 (m=2) is two parallel copies, as in ngspice_vdmos_cs.sp, so the golden
* is 45 running M2 as two m=1 instances.
.options reltol=1e-6 abstol=1e-15 vntol=1e-9
vdd vdd 0 dc 10
vg g 0 dc 3 ac 1
rl1 vdd d1 100
m1 d1 g 0 vm
rl2 vdd d2 1k
m2 d2 g 0 vm m=2
.model vm vdmos vto=2 kp=0.05 rd=0.5 rs=0.2 lambda=0.01 theta=0.1 kf=1e-22 af=1.2
.noise v(d1,d2) vg dec 3 10 100meg
.end
