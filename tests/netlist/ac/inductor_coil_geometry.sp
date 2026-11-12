* L valued from a model card's coil geometry: NT, CSECT or DIA, LENGTH, MU
* Oracle: ngspice 44.2 (expected.json). One turn is MU*mu0*CSECT/LENGTH
* times Lundin's correction (indsetup.c:31-85, 142-172), times NT^2 from
* the card or the model; IND wins over the geometry, and the card's tc1,
* dtemp, scale and m apply as to any value (indtemp.c:54-79).
* Each L is driven by a 1 A AC source and read as v(*).
i1 0 n1 ac 1
l1 n1 0 lc1
i2 0 n2 ac 1
l2 n2 0 lc2
i3 0 n3 ac 1
l3 n3 0 lc2 nt=20
i4 0 n4 ac 1
l4 n4 0 lc3
i5 0 n5 ac 1
l5 n5 0 lc4
i6 0 n6 ac 1
l6 n6 0 lc1 scale=2 m=4 tc1=2e-3 dtemp=25
.model lc1 l(nt=100 csect=1e-4 length=1e-2)
.model lc2 l(dia=5e-3 length=5e-2 mu=10 nt=50)
.model lc3 l(ind=3u nt=100 csect=1e-4 length=1e-2)
.model lc4 l(nt=30 csect=2e-5 length=0.5u)
.ac lin 1 100k 100k
.end
