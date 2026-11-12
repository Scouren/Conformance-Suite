* R, C and L model cards carrying temp= or dtemp=, alone and under the
* instance's own, and the value written after the model name.
* Expected results: passive_model_temp.expected.json (ngspice 44.2).
* ngspice applies a model card's temp/dtemp as the instance default:
* temp=100 scales by 1+0.01*73, dtemp=50 by 1+0.01*50. An instance temp
* or dtemp wins over the model's, and a given temp (either card) drops
* dtemp. r1-r6 write the value first. r7 and every C and L card write it
* after the model name, the order ngspice 44.2 reads for C and L (it
* refuses `c1 a 0 1n cm`); those read 1 mOhm, 0 F and 0 H before the fix.
v1 n1 0 dc 1 ac 1
r1 n1 0 1k rmt
v2 n2 0 dc 1 ac 1
r2 n2 0 1k rmd
v3 n3 0 dc 1 ac 1
r3 n3 0 1k rmt dtemp=10
v4 n4 0 dc 1 ac 1
r4 n4 0 1k rmd temp=80
v5 n5 0 dc 1 ac 1
r5 n5 0 1k rmd dtemp=10
v6 n6 0 dc 1 ac 1
r6 n6 0 1k rmtd
v7 n7 0 dc 1 ac 1
r7 n7 0 rmd 1k
v8 n8 0 dc 1 ac 1
c8 n8 0 cmt 1n
v9 n9 0 dc 1 ac 1
c9 n9 0 cmd 1n
v10 n10 0 dc 1 ac 1
c10 n10 0 cmd 1n dtemp=10
v11 n11 0 dc 0 ac 1
l11 n11 m11 lmt 1u
rl11 m11 0 1
v12 n12 0 dc 0 ac 1
l12 n12 m12 lmd 1u
rl12 m12 0 1
v13 n13 0 dc 0 ac 1
l13 n13 m13 lmd 1u temp=80
rl13 m13 0 1
.model rmt r(tc1=1e-2 temp=100)
.model rmd r(tc1=1e-2 dtemp=50)
.model rmtd r(tc1=1e-2 temp=100 dtemp=50)
.model cmt c(tc1=1e-2 temp=100)
.model cmd c(tc1=1e-2 dtemp=50)
.model lmt l(tc1=1e-2 temp=100)
.model lmd l(tc1=1e-2 dtemp=50)
.ac lin 1 1e6 1e6
.end
