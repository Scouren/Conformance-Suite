* MOS2 and MOS3 Meyer caps in weak inversion are split by vds as above
* threshold (ngspice devsup.c DEVqmeyer), so cgs = cgd at vds = 0.
* Each FET has equal caps on both floating channel nodes, so vds stays
* near 0 while the gate ramp sweeps it through -phi/2 < vgst <= 0. With
* cgd = 0 in that band the caps swapped at every vds sign flip, Newton
* 2-cycled on the gate source's current at any dt, and the run stopped
* with TimestepTooSmall at 11 ps (circuitsim90 pump, nand, slowlatch,
* arom, gm19, jge, pchip).
* Oracle: ngspice 44.2 and 45 print the same eight values; their spread
* over reltol 1e-3..1e-5, trtol 1 and a 1 ps step cap is 0.26% at 0.1 ns
* and 0.11% at 1 ns, which sets each rtol.
* Expected results: mos2_mos3_meyer_weak_inversion.expected.json
.model n2 nmos level=2 nfs=4.55168e12
.model n3 nmos level=3 nfs=4.55168e12
vg g 0 pwl(0 0 0.2n 5)
m2 d2 g s2 0 n2 l=1.25u w=5u
c2d d2 0 2f
c2s s2 0 2f
m3 d3 g s3 0 n3 l=1.25u w=5u
c3d d3 0 2f
c3s s3 0 2f
.tran 0.01n 1n
.options maxord=1
.meas tran vd2_mid find v(d2) at=0.1n
.meas tran vs2_mid find v(s2) at=0.1n
.meas tran vd2_end find v(d2) at=1n
.meas tran vs2_end find v(s2) at=1n
.meas tran vd3_mid find v(d3) at=0.1n
.meas tran vs3_mid find v(s3) at=0.1n
.meas tran vd3_end find v(d3) at=1n
.meas tran vs3_end find v(s3) at=1n
.end
