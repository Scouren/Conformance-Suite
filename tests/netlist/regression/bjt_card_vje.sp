* A BJT card's VJE/VJC/VJS and their PE/PC/PS spellings set the junction potentials.
* Expected results: bjt_card_vje.expected.json (ngspice-44.2)
* bjt.c:120-141 takes vje/vjc/vjs (IOPA) and pe/pc/ps (IOPAR) for one
* parameter each. ESPice bound pe/pc/ps and dropped vje/vjc/vjs: the binder's
* alias row named a `vje` field gummel_poon.va does not have, so q1 ran at
* the 0.75 V defaults with no error. q1 and q2 must agree with ngspice and
* with each other.
.options reltol=1e-6 abstol=1e-15 vntol=1e-9

vb b 0 dc 0.6 ac 1
vc c 0 dc 1
vs s 0 dc -1 ac 0.5
vc1 c c1 0
vc2 c c2 0
q1 c1 b 0 s q1m
q2 c2 b 0 s q2m
.model q1m npn is=1e-16 bf=100 cje=1p vje=0.3 mje=0.4 cjc=0.5p vjc=0.4 mjc=0.4 cjs=0.8p vjs=0.5 mjs=0.3 tf=0
.model q2m npn is=1e-16 bf=100 cje=1p pe=0.3 mje=0.4 cjc=0.5p pc=0.4 mjc=0.4 cjs=0.8p ps=0.5 mjs=0.3 tf=0

.ac dec 2 1meg 1g
.end
