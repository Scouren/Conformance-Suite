VDMOS gate capacitances: ngspice's defaults, its Cgd law, and the instance m
* Expected results: vdmos_gate_caps.expected.json
* Card DFLT gives no capacitance, so ngspice's defaults apply: CGDMIN 20p,
* CGDMAX 2n, CGS 1.4n, A 1, each only when its key is absent
* (vdmosset.c:70-80). Cgd follows devsup.c:654-665: s atan(A vgd) + y for
* vgd <= 0 and s tanh(A vgd) + y above, s = (CGDMAX-CGDMIN)/(1+pi/2),
* y = CGDMAX - s. Each MD<k> and MG<k> drives its drain at AC with gate and
* source at AC ground, so i(vg<k>) is +j w Cgd at vgd = the gate's DC;
* vds = 0 keeps the channel and the body diode out of the gate current.
* MD13, MG5, MS2, MF1 and MF2 are m=2, two parallel copies: ngspice
* master scales every gate capacitance by m (2bc63e, 6bd5c2), where 44.2
* and 45 leave them unscaled (vdmosload.c:71-74), so the golden is 44.2
* running each m=2 instance as two m=1 instances. MS and MS2 drive the gate:
* i(vgs) = -j w (CGS + Cgd(0)), and i(vgs2) twice that.
* Card FLAT has CGDMIN = CGDMAX, where every Cgd law is the constant
* CGDMAX, so MF0-MF2 test m alone: MF0 and MF1 (m=2) drive the drain,
* MF2 (m=2) the gate.
vgd0 gd0 0 -10
vdd0 dd0 0 dc 0 ac 1
md0 dd0 gd0 0 dflt
vgd1 gd1 0 -7
vdd1 dd1 0 dc 0 ac 1
md1 dd1 gd1 0 dflt
vgd2 gd2 0 -5
vdd2 dd2 0 dc 0 ac 1
md2 dd2 gd2 0 dflt
vgd3 gd3 0 -3
vdd3 dd3 0 dc 0 ac 1
md3 dd3 gd3 0 dflt
vgd4 gd4 0 -2
vdd4 dd4 0 dc 0 ac 1
md4 dd4 gd4 0 dflt
vgd5 gd5 0 -1
vdd5 dd5 0 dc 0 ac 1
md5 dd5 gd5 0 dflt
vgd6 gd6 0 -0.5
vdd6 dd6 0 dc 0 ac 1
md6 dd6 gd6 0 dflt
vgd7 gd7 0 0
vdd7 dd7 0 dc 0 ac 1
md7 dd7 gd7 0 dflt
vgd8 gd8 0 0.5
vdd8 dd8 0 dc 0 ac 1
md8 dd8 gd8 0 dflt
vgd9 gd9 0 1
vdd9 dd9 0 dc 0 ac 1
md9 dd9 gd9 0 dflt
vgd10 gd10 0 2
vdd10 dd10 0 dc 0 ac 1
md10 dd10 gd10 0 dflt
vgd11 gd11 0 3
vdd11 dd11 0 dc 0 ac 1
md11 dd11 gd11 0 dflt
vgd12 gd12 0 5
vdd12 dd12 0 dc 0 ac 1
md12 dd12 gd12 0 dflt
vgd13 gd13 0 -7
vdd13 dd13 0 dc 0 ac 1
md13 dd13 gd13 0 dflt m=2
vgg0 gg0 0 -7
vdg0 dg0 0 dc 0 ac 1
mg0 dg0 gg0 0 given
vgg1 gg1 0 -1
vdg1 dg1 0 dc 0 ac 1
mg1 dg1 gg1 0 given
vgg2 gg2 0 0
vdg2 dg2 0 dc 0 ac 1
mg2 dg2 gg2 0 given
vgg3 gg3 0 1
vdg3 dg3 0 dc 0 ac 1
mg3 dg3 gg3 0 given
vgg4 gg4 0 3
vdg4 dg4 0 dc 0 ac 1
mg4 dg4 gg4 0 given
vgg5 gg5 0 -1
vdg5 dg5 0 dc 0 ac 1
mg5 dg5 gg5 0 given m=2
vgf0 gf0 0 -3
vdf0 df0 0 dc 0 ac 1
mf0 df0 gf0 0 flat
vgf1 gf1 0 -3
vdf1 df1 0 dc 0 ac 1
mf1 df1 gf1 0 flat m=2
vgf2 gf2 0 dc 0 ac 1
vdf2 df2 0 0
mf2 df2 gf2 0 flat m=2
vgs gs 0 dc 0 ac 1
vds ds 0 0
ms ds gs 0 dflt
vgs2 gs2 0 dc 0 ac 1
vds2 ds2 0 0
ms2 ds2 gs2 0 dflt m=2
.model dflt vdmos vto=2 kp=1
.model given vdmos vto=2 kp=1 cgdmin=50p cgdmax=500p cgs=300p a=0.5
.model flat vdmos vto=2 kp=1 cgdmin=300p cgdmax=300p cgs=500p
.ac lin 1 1meg 1meg
.end
