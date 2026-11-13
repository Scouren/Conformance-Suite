* A Q card's dtemp and temp set its device temperature (gf180 vnpn/vpnp, reduced).
* Expected results: bjt_instance_dtemp.expected.json
* Origin: reduced from cmcqa/gf180 gf180_beta_vnpn_0p54x16_14.sp: the
* vnpn_0p54x16 and vpnp_0p42x10 cards of sm141064.ngspice (bjt_typical), with
* each corner/mismatch expression replaced by the value ngspice-44.2 `showmod`
* printed for it. Those decks put `dtemp=dtemp` on the Q card and ESPice
* refused them with `unknown instance parameter 'dtemp'`.
* ngspice: the device runs at CKTtemp + dtemp unless `temp` (degC) is given,
* which then wins (bjt.c:76-77, bjtparam.c:46-53, bjttemp.c:86-91). tref is the
* card's tnom in degC (bjt.c:93, bjtmpar.c:41-43); every t*1/t*2 tempco, tlev
* 1/3 and tlevc 1 map their parameter over T - tnom (bjttemp.c:95-325).
* q1 vnpn at 135 degC; q2 vpnp at 105 degC (tlevc=1 caps); q3 vnpn at 60 degC
* (temp wins over dtemp); q4 tlev=1 with the remaining tempcos at 150 degC;
* q5 tlev=3 at 125 degC; q6 a three-terminal pnp with no subs, which ngspice
* makes lateral (bjtsetup.c:40-46), so cjs sits base to substrate and i(epb6)
* carries it.
* The cards carry no irb and no rbm: with either, rbb depends on bias, and
* ngspice's AC holds gx = 1/rbb fixed (bjtload.c:622-630) while ESPice's
* differentiates it, a separate gap this deck does not test.
.temp 125
.options tnom=125 reltol=1e-6 abstol=1e-15 vntol=1e-9

vb b 0 dc 0.8 ac 1
vc1 c1 0 dc 3
vc3 c3 0 dc 3
vc4 c4 0 dc 3
vc5 c5 0 dc 3
q1 c1 b 0 0 qn dtemp=10
q3 c3 b 0 0 qn temp=60 dtemp=10
q4 c4 b 0 qt1 dtemp=25
q5 c5 b 0 qt3
vpe pe 0 dc 3
epb pb pe b 0 -1
q2 0 pb pe qp dtemp=-20
vpe6 pe6 0 dc 3
epb6 pb6 pe6 b 0 -1
q6 0 pb6 pe6 qps dtemp=5

.model qn npn level=1 tref=25 is=2.8872e-18 bf=8.4987 nf=1.002 vaf=37.389
+ ikf=0.013121 ise=5.2003e-16 ne=1.4678 br=0.079582 nr=1 var=23.969
+ ikr=0.0038951 isc=1.0425e-16 nc=1.284 rb=137.43
+ re=14.121 rc=12.9 cje=1.354e-14 vje=0.70172 mje=0.32071 cjc=3.54e-14
+ vjc=0.63391 mjc=0.31113 xcjc=1 cjs=8.211e-14 vjs=0.35175 mjs=0.14716
+ xtb=0 eg=1.17 xti=3 iss=3.95e-16 nkf=0.584 tbf1=0.0057737 tbf2=2.2189e-06
+ tbr1=0.0007104 tikf1=-0.003 tne1=0.00034324 tnf1=5.2528e-05 tnr1=0.0001
+ tre1=0.0035596
.model qp pnp level=1 tref=25 is=9.02656e-19 bf=1.6836 nf=1 vaf=80
+ ikf=0.00063375 ise=2.7e-16 ne=1.64 br=0.0036 nr=1 var=23 ikr=0.1 isc=1e-18
+ nc=2 rb=41 re=1 rc=10 cje=6.88e-15 vje=0.43905 mje=0.14469
+ tf=1e-10 xtf=1 vtf=10 itf=0.1 cjc=2.04e-14 vjc=0.43905 mjc=0.22711 xcjc=1
+ xtb=0.0001 eg=1.17 xti=3 nkf=0.4 tlevc=1 tbf1=0.0061 tikf1=-0.0043
+ ctc=0.0028626 cte=0.001 tvjc=0.0024779 tvje=0.0019314
.model qt1 npn level=1 tref=25 tlev=1 is=1e-16 bf=100 vaf=50 var=20 ikf=0.02
+ ise=1e-15 ne=1.5 isc=1e-15 nc=2 iss=1e-17 ns=1.1 rb=100 rc=10 re=2
+ cje=1p mje=0.4 cjc=0.5p mjc=0.3 cjs=1p mjs=0.2 tf=50p xtf=2 itf=0.01 tr=1n
+ xtb=1.5 tvaf1=-1e-3 tvar1=2e-3 titf1=2e-3 ttf1=1e-3 ttr1=-1e-3
+ tmje1=1e-3 tmjc1=-1e-3 tmjs1=1e-3 tnc1=1e-4 tns1=1e-4 tbr1=1e-3 trb1=2e-3
+ trc1=1e-3 tikr1=1e-3 ikr=0.01
.model qt3 npn level=1 tref=25 tlev=3 is=1e-16 bf=100 vaf=50 ise=1e-15 ne=1.5
+ isc=1e-15 nc=2 tis1=1e-3 tise1=2e-3 tisc1=-1e-3 cje=1p cjc=0.5p rb=50
.model qps pnp is=1e-16 bf=50 cjs=1p mjs=0.3 rb=10 rc=10

.dc vb 0.3 1.0 0.02
.ac dec 4 1meg 10g
.end
