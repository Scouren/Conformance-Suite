* MOS2 and MOS3 Meyer caps in weak inversion (-phi/2 < vgst <= 0) are
* split between gate-source and gate-drain by vds/vdsat as above threshold
* (ngspice devsup.c DEVqmeyer), not all given to the source. Each gate
* current is j*w times one cap: the drain-driven FET reads Cgd, the
* source-driven one Cgs. With no overlap or junction caps,
* Cgd = 2*cb*(1 - vdsat'^2/(2*vdsat' - vds)^2) and
* Cgs = 2*cb*(1 - (vdsat' - vds)^2/(2*vdsat' - vds)^2), where
* cb = vgst*Cox/(1.5*phi) + Cox/3 and vdsat' = max(vdsat, 0.025).
* Oracle: ngspice 44.2 and 45 agree to every printed digit, and the
* closed form above with ngspice's von and vdsat reproduces them to 1e-4.
* Expected results: mos2_mos3_meyer_weak_inversion.expected.json
.model n2 nmos level=2 vto=0.62249 gamma=0.639243 phi=0.31 tox=225e-10 nsub=1.066e16 nfs=4.55168e12
.model n3 nmos level=3 vto=0.62249 gamma=0.639243 phi=0.31 tox=225e-10 nsub=1.066e16 nfs=4.55168e12
vg2d g2d 0 0.68
vd2d d2d 0 dc 0.01 ac 1
m2d d2d g2d 0 0 n2 l=1.25u w=5u
vg2s g2s 0 0.68
vd2s d2s 0 0.01
vs2s s2s 0 dc 0 ac 1
m2s d2s g2s s2s 0 n2 l=1.25u w=5u
vg3d g3d 0 0.68
vd3d d3d 0 dc 0.01 ac 1
m3d d3d g3d 0 0 n3 l=1.25u w=5u
vg3s g3s 0 0.68
vd3s d3s 0 0.01
vs3s s3s 0 dc 0 ac 1
m3s d3s g3s s3s 0 n3 l=1.25u w=5u
.ac lin 3 1meg 3meg
.end
