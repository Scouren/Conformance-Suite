VDMOS gate charge through a gate step: the Cgd law integrated to a charge
* Expected results: vdmos_gate_charge.expected.json
* A 10 ohm gate resistor charges the gate of M1 from -10 V to 5 V and back
* with drain and source held at 0 V, so vgd sweeps the whole Cgd law
* (devsup.c:654-665) at vds = 0, where the channel and the body diode carry
* no current. i(vd1) is the Cgd charging current and i(vs1) the CGS one.
* Card DFLT gives no capacitance, so ngspice's defaults apply (CGDMIN 20p,
* CGDMAX 2n, CGS 1.4n, vdmosset.c:70-80). M2 is the same circuit at m=2,
* two parallel copies with twice the gate charge, as in ngspice master
* (2bc63e, 6bd5c2); 44.2 and 45 leave the caps unscaled (vdmosload.c:71-74),
* so the golden is 44.2 running M2 as two m=1 instances. RELTOL 1e-4
* makes ngspice an oracle at 1e-3: it then sits within 9e-5 of each
* column's peak of the exact charge ODE, against 7e-4 at its default 1e-3.
vp a 0 pulse(-10 5 10n 10n 10n 100n 1)
rg1 a g1 10
vd1 d1 0 0
vs1 s1 0 0
m1 d1 g1 s1 dflt
rg2 a g2 10
vd2 d2 0 0
vs2 s2 0 0
m2 d2 g2 s2 dflt m=2
.model dflt vdmos vto=2 kp=1
.options reltol=1e-4
.tran 0.1n 250n 0 0.1n
.end
