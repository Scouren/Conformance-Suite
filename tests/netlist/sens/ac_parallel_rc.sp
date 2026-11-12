* AC sensitivity of a current-driven parallel RC (ngspice sens-ac-1.sp), plus a V and an I source with no AC spec
* Expected results: ac_parallel_rc.expected.json
i1  0 1  dc=1.27 ac=42mA
i2  1 0  dc=1m
r1  1 3  1k
v2  3 0  dc=0.5
c1  1 0  100p
.sens v(1) ac lin 1 1e6 1.1e6
.end
