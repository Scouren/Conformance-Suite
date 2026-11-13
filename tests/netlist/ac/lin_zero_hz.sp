* .ac lin 1 0Hz 0Hz: one point at DC (ngspice tests/regression/misc/ac-zero.sp)
* Expected results: lin_zero_hz.expected.json
* At w = 0 the inductor shorts and the capacitor opens: v(2) = v(3) = 1k/(1k+1k).
v1 1 0 dc=0 ac=1
r1 1 2 1k
l1 2 3 1uH
r3 3 0 1k
c3 3 0 1uF
.ac lin 1 0Hz 0Hz
.end
