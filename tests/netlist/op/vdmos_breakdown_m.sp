VDMOS body-diode breakdown at m=2: IBV scales with m, as IS does
* Expected results: vdmos_breakdown_m.expected.json
* Each drain sits past BV = 50 V with the gate off, so its current is the
* body diode's breakdown branch -IS exp(-(x_bv + vd)/(NBV Vt)), with x_bv
* solved so that the branch passes through (-BV, -IBV) (vdmostemp.c:130-160).
* MA-MC are m=1 and MD-MF m=2 at the same three biases. m=2 is two parallel
* copies, so IBV scales with m as IS does and as the diode's does
* (diotemp.c:211-213). ngspice 44.2, 45 and master take IBV unscaled (45's
* vdmostemp.c:136), which halves the m=2 breakdown current here, so the
* golden is 44.2 running each m=2 instance as two m=1 instances. RELTOL
* 1e-6 holds ngspice's x_bv, matched to RELTOL*IBV, and its Newton error
* far under the comparison's 1e-3.
.options reltol=1e-6 abstol=1e-15 vntol=1e-9
vda da 0 49.9
ma da 0 0 bk
vdb db 0 50
mb db 0 0 bk
vdc dc 0 50.1
mc dc 0 0 bk
vdd dd 0 49.9
md dd 0 0 bk m=2
vde de 0 50
me de 0 0 bk m=2
vdf df 0 50.1
mf df 0 0 bk m=2
.model bk vdmos vto=2 kp=1 bv=50 ibv=1m is=1e-12
.op
.end
