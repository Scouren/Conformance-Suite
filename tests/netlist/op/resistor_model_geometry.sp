* An R card valued by its model card: ngspice 44.2's defaults and alternate
* spellings for the semiconductor resistor, R = RSH*(L-2*SHORT)/(W-2*NARROW).
* Expected results: resistor_model_geometry.expected.json (ngspice 44.2).
* r1 takes the default length 10u (500 Ohm), r2 both defaults (100 Ohm);
* r3/r4 take dw/dlr for narrow/short (555.6 / 450), r5 res= for r= (1k),
* r6 w= for defw (250), r7 the model's l= as the default length (1k);
* r8's tc1r/tc2r are tc1/tc2 at .temp 50 (r9 the same card spelled tc1/tc2).
* r10 spells every key as ESPice read it before (533.3), the control.
* Each wrong reading misses by 10% or more (1 mOhm for r1, r2, r5, r7).
.temp 50
v1 n1 0 1
r1 n1 0 rs w=2u
v2 n2 0 1
r2 n2 0 rs
v3 n3 0 1
r3 n3 0 rdw l=10u w=2u
v4 n4 0 1
r4 n4 0 rdlr l=10u w=2u
v5 n5 0 1
r5 n5 0 rres
v6 n6 0 1
r6 n6 0 rw l=10u
v7 n7 0 1
r7 n7 0 rl w=2u
v8 n8 0 1
r8 n8 0 rtcr 1k
v9 n9 0 1
r9 n9 0 rtc 1k
v10 n10 0 1
r10 n10 0 rctl l=10u
.model rs r(rsh=100)
.model rdw r(rsh=100 dw=0.1u)
.model rdlr r(rsh=100 dlr=0.5u)
.model rres r(res=1k)
.model rw r(rsh=100 w=4u)
.model rl r(rsh=100 l=20u)
.model rtcr r(tc1r=1e-2 tc2r=1e-4)
.model rtc r(tc1=1e-2 tc2=1e-4)
.model rctl r(rsh=100 narrow=0.1u short=0.2u defw=2u)
.op
.end
