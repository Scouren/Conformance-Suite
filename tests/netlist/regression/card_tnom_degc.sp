* A model card's TNOM/TREF is in degC, and a card key a device does not take is ignored.
* Expected results: card_tnom_degc.expected.json (ngspice-44.2)
* ngspice adds CONSTCtoK to a BJT or diode card's TNOM/TREF (bjtmpar.c:41-43,
* diompar.c), so q1 (tref=50) and q2 (tnom=50) scale IS, BF and VJ over
* 27 - 50 = -23 K, and d1 likewise. HFET1, HFET2 and MESA have no model TNOM
* (hfettemp.c:71-73, hfet2temp.c:48, mesatemp.c:60): 44.2 prints
* "unrecognized parameter (tnom) - ignored" and refers every tempco to
* .options tnom. BSIM1's model TEMP is degC, stored and never read
* (b1.c:97, b1set.c:190-192). ESPice read every one of these as kelvin.
.options reltol=1e-6 abstol=1e-15 vntol=1e-9

vin in 0 dc 0.7
vc c 0 dc 2
rb1 in b1 1k
q1 c b1 0 qa
rb2 in b2 1k
q2 c b2 0 qb
rd in a 1k
d1 a 0 da
.model qa npn is=1e-16 bf=100 vaf=50 xti=3 eg=1.11 xtb=1.5 cje=1p cjc=0.5p tref=50
.model qb npn is=1e-16 bf=100 vaf=50 xti=3 eg=1.11 xtb=1.5 cje=1p cjc=0.5p tnom=50
.model da d is=1e-14 n=1.05 cjo=1p vj=0.7 xti=3 eg=1.11 tref=50

vg g 0 dc 0.3
vdz dz 0 dc 1
z1 dz g 0 h1 l=1u w=20u
z2 dz g 0 h2 l=1u w=20u
z3 dz gm 0 ma l=1u w=20u
vgm gm 0 dc -0.5
.model h1 nhfet level=5 vto=0.15 kvto=-1e-3 kmu=10 tnom=50
.model h2 nhfet level=6 vto=0.15 kvto=-1e-3 tnom=50
.model ma nmf level=2 vto=-1.2 tvto=1e-3 rd=31 rs=31 tnom=50

vdm dm 0 dc 3
vgg gg 0 dc 1.5
m1 dm gg 0 0 nb w=10u l=1u
.model nb nmos level=4 vfb=-0.3 phi=0.65 k1=0.5 k2=-0.1 eta=0.02 muz=600 u0=0.05 u1=0.01 tox=40n temp=27

.dc vin 0.5 0.9 0.05
.end
