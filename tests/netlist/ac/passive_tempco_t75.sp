* C, L and R temperature coefficients at .temp 75
.temp 75
* Oracle: ngspice 44.2 (expected.json). Every C and L value carries
* tc1/tc2 with dtemp, temp= (dtemp then ignored, captemp.c:39-52,
* indtemp.c:35-48), a model card's tc and tnom, or scale and m around
* the temperature factor (captemp.c:94, indtemp.c:79, capload.c:74-79,
* indload.c:111-113); R checks the same order (restemp.c:35-110).
* A C is driven by a 1 V AC source and read as i(v*), an L or R by a
* 1 A AC source and read as v(*).
va a 0 dc 0 ac 1
ca a 0 1n tc1=0.01 tc2=1e-4 dtemp=10
vb b 0 dc 0 ac 1
cb b 0 1n tc1=0.01 tc2=1e-4 temp=-20
vc c 0 dc 0 ac 1
cc c 0 cmod
vd d 0 dc 0 ac 1
cd d 0 1n tc1=0.01 tc2=1e-4 temp=-20 dtemp=10
ve e 0 dc 0 ac 1
ce e 0 cgeo w=20u l=30u scale=2 m=3 tc1=2e-3
vf f 0 dc 0 ac 1
cf f 0 c=1n scale=2 m=3 tc1=0.01 dtemp=-15
.model cmod c(cap=2n tc1=-3e-3 tc2=2e-5 tnom=50)
.model cgeo c(cj=1e-3 cjsw=1e-9 narrow=1u short=2u tc2=1e-5)
i1 0 l1 ac 1
la l1 0 10u tc1=5e-3 tc2=-2e-5 dtemp=10
i2 0 l2 ac 1
lb l2 0 10u tc1=5e-3 tc2=-2e-5 temp=-20
i3 0 l3 ac 1
lc l3 0 lmod
i4 0 l4 ac 1
ld l4 0 10u tc1=5e-3 tc2=-2e-5 temp=-20 dtemp=10
i5 0 l5 ac 1
le l5 0 10u scale=2 m=4 tc1=5e-3 dtemp=-30
i6 0 l6 ac 1
lf l6 0 inductance=10u scale=3 m=2 tc2=1e-4
.model lmod l(ind=20u tc1=-4e-3 tc2=3e-5 tnom=50)
i7 0 r1 ac 1
ra r1 0 1k tc1=3e-3 tc2=1e-5 temp=-20 dtemp=10
i8 0 r2 ac 1
rb r2 0 1k tc1=3e-3 tc2=1e-5 dtemp=10
i9 0 r3 ac 1
rc r3 0 resistance=1k scale=2 m=4 tc1=3e-3
.ac lin 1 1meg 1meg
.end
