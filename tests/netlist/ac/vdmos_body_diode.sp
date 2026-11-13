VDMOS body diode: a .model card's m is the diode grading coefficient
* Expected results: vdmos_body_diode.expected.json
* ngspice reads `m` on a VDMOS .model card as the body diode's grading
* coefficient (vdmos.c:121, IOP "m" VDIO_MOD_MJ; vdmostemp.c:85-87),
* never the multiplier, which is the instance card's `m` (vdmos.c:15).
* The body diode and RB sit on the external source and drain, not
* behind RS and RD (vdmosset.c:378-398, vdmosload.c:723-724 and 888).
* MF and MR are off (vgs = -5 V, VTO = -2.7 V), so each drain source
* reads the body diode alone: forward at vds = -0.5 V, reverse at +2 V.
* D1 and D2 are the same junction on a diode card, whose `m` is its
* grading too (dio.c:71). The 1 kHz AC point reads the reverse
* junction's capacitance CJO/(1 + 2/VJ)^m, where the grading shows.
* Card: IXTP6N100D2 of ngspice examples/vdmos/VDMOS-DIO.sp, its gate
* capacitances zeroed (ngspice defaults them to an IRF540's, vdmosset.c:70-80)
* so the drain current is the body diode's.
vgf gf 0 -5
vdf df 0 dc -0.5 ac 1
mf df gf 0 ixtp
vgr gr 0 -5
vdr dr 0 dc 2 ac 1
mr dr gr 0 ixtp
va a 0 dc 0.5 ac 1
d1 a 0 dio
vb b 0 dc -2 ac 1
d2 b 0 dio
.model ixtp vdmos(kp=2.9 rs=0.1 rd=1.3 rg=1 vto=-2.7 lambda=0.03 tt=1371n is=2.13e-08 n=1.564 rb=0.0038 m=0.548 vj=0.1 cjo=3200p ksubthres=0.1 cgdmin=0 cgdmax=0 cgs=0)
.model dio d(tt=1371n is=2.13e-08 n=1.564 rs=0.0038 m=0.548 vj=0.1 cjo=3200p)
.op
.ac lin 1 1k 1k
.end
