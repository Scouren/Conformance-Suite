* A BJT card's linear/quadratic tempcos and TLEVC=1 move its parameters with T - TNOM.
* Expected results: bjt_card_tempco.expected.json (ngspice-44.2)
* q1 carries gf180 vnpn's tempcos (sm141064.ngspice, bjt_typical) and the
* rest of bjttemp.c's t*1/t*2 set: BF, BR, IKF, IKR, NF, NR, NE, NC, VAF,
* VAR, RB, RC, RE, MJE, MJC each scale by 1 + t1*dT + t2*dT^2
* (bjttemp.c:95-158). q2 is a vertical pnp with TLEVC=1: CJE/CJC/CJS by 1 + CTE*dT
* and VJE/VJC/VJS by -TVJ*dT (bjttemp.c:274-325). dT = 125 - 25 = 100 K.
* ESPice ignored every one of these keys with no error; gf180's tbf1=0.0058
* alone moves BF by 58% at 125 degC. IRB is left out: ESPice's AC
* differentiates the IRB-modulated base resistance and ngspice's holds gx
* fixed (bjtload.c:622-630), a separate gap. pe/pc/ps keep the vje
* spellings out of this deck.
.temp 125
.options tnom=25 reltol=1e-6 abstol=1e-15 vntol=1e-9

vb b 0 dc 0.7 ac 1
vc1 c1 0 dc 2
vc2 pe 0 dc 2
q1 c1 b 0 qn
epb pb pe b 0 -1
vss ss 0 dc 1 ac 0.5
q2 0 pb pe ss qp
.model qn npn is=1e-16 bf=100 br=2 ikf=0.02 ikr=0.01 nf=1.002 nr=1.001 ise=1e-15
+ ne=1.5 isc=1e-15 nc=2 vaf=40 var=20 rb=100 rc=10 re=2
+ cje=1p mje=0.33 cjc=0.5p mjc=0.33 xtb=0 xti=3 eg=1.17
+ tbf1=0.0057737 tbf2=2.2189e-06 tbr1=0.0007104 tbr2=1e-6 tikf1=-0.003 tikf2=1e-6
+ tikr1=2e-3 tnf1=5.2528e-05 tnf2=1e-8 tnr1=1e-4 tne1=0.00034324 tnc1=1e-4
+ tvaf1=-1e-3 tvaf2=1e-6 tvar1=2e-3 trb1=2e-3 trb2=1e-6
+ trc1=1e-3 tre1=0.0035596 tmje1=1e-3 tmjc1=-1e-3
.model qp pnp is=1e-16 bf=50 vaf=80 rb=40 re=1 rc=10 cje=7p pe=0.44 mje=0.14
+ cjc=20p pc=0.44 mjc=0.23 cjs=10p ps=0.6 mjs=0.2 subs=1 xtb=0 xti=3 eg=1.17
+ tlevc=1 cte=0.001 ctc=0.0028626 cts=0.002 tvje=0.0019314 tvjc=0.0024779 tvjs=0.002

.dc vb 0.5 0.9 0.05
.ac dec 2 1meg 1g
.end
