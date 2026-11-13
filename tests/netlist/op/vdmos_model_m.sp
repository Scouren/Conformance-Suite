* VDMOS model card M is the body diode's grading coefficient, not the multiplier.
* Expected results: vdmos_model_m.expected.json
* ngspice reads `m` on a VDMOS .model card as the body diode grading
* coefficient (vdmos.c:121, IOP "m" VDIO_MOD_MJ) and `m` on the instance
* card as the multiplier (vdmos.c:15, IOPU "m" VDMOS_M). M1's model sets
* m=0.5, a reverse-biased junction's grading, which leaves its DC current
* alone; M2's instance sets m=2, which doubles it.
* Oracle (derived): saturation, LAMBDA=0, KSUBTHRES at its 0.1 default
* (vdmosload.c:356-379): id = KP/2 * (0.1*ln(1+exp((vgs-VTO)/0.1)))^2.
vg g 0 4.5
vd1 d1 0 5
vd2 d2 0 5
m1 d1 g 0 graded
m2 d2 g 0 plain m=2
.model graded vdmos (vto=4 kp=5.9 cjo=1n m=0.5)
.model plain vdmos (vto=4 kp=5.9)
.op
.end
