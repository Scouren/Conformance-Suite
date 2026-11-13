* K coupling L cards whose values move with temperature, at .temp 60
* Oracle: ngspice 44.2 (expected.json). M = k*sqrt(|L1*L2|) on each L
* after its temperature update (muttemp.c:50-56 on indtemp.c:63-79), so
* M follows both windings' tc1/tc2, dtemp, temp= and model tnom; an L's
* scale counts in M and its m does not (indtemp.c:79, indload.c:111-113).
.temp 60
v1 in 0 ac 1
r1 in a 10
la1 a 0 10u tc1=5e-3 tc2=-2e-5 dtemp=10
la2 b 0 40u tc1=-3e-3 temp=-20
rb b 0 50
ka la1 la2 0.6
v2 in2 0 ac 1
r2 in2 c 10
lb1 c 0 lmod
lb2 d 0 15u scale=3 m=2
rd d 0 50
kb lb1 lb2 -0.4
.model lmod l(ind=20u tc1=-4e-3 tc2=3e-5 tnom=50)
.ac lin 1 100k 100k
.end
