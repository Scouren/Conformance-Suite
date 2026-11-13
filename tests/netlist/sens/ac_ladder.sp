* AC sensitivity of a V-driven RLC ladder to every element and the AC drive (ngspice sens-ac-2.sp)
* Expected results: ac_ladder.expected.json
v1  1 0  dc=1.27 ac=42mA acphase=30
r1  1 2  68.0
c2  2 0  1.5n
l3  2 3  12u
c4  3 0  1.8n
r5  3 0  100.0
.sens v(3) ac dec 2 1e5 1e7
.end
