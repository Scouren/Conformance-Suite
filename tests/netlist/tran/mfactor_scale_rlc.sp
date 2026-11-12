* m= and scale= on R, C and L cards, against closed forms (SpiceRack report).
* ngspice: C stamps m*C*scale (captemp.c:94, capload.c:74-79), L integrates
* L*scale/m (indtemp.c:79, indload.c:111-113), R conducts m/(R*scale).
* Before the fix C and L dropped both, so o1 read 0.8647, o5 0.5819, o9 0.6065.
* Expected results: mfactor_scale_rlc.expected.json
* A 1 V step (1 ns edge) drives each branch:
*   o1: 1k into C 1u m=2 = 2u; tau 2 ms, 1 - e^-1 at 2 ms
*   o2: 1k + R 1k m=2 (500) in series into C 1u m=2; tau 3 ms,
*       v(o2) = 1 - (2/3) e^-t/tau, at 3 ms
*   o3: 1k into C 1u m=2 parallel R 2k m=2 (1k); 0.5 (1 - e^-t/1ms) at 1 ms
*   o4: 1k into C 1u m=2 parallel C 0.5u m=2 = 3u; 1 - e^-1 at 3 ms
*   o5: 1k, L 100m m=2 (50m) and C 1u m=2 (2u) in series; v(o5) = 1 - R i,
*       the overdamped series RLC current, at 1 ms
*   o7: 10 ohm into L 20m m=2 (10m); e^-t/1ms at 0.5 ms
*   o8: R 500 scale=2 (1k) into C 0.5u scale=2 m=2 (2u); 1 - e^-1 at 2 ms
*   o9: 10 ohm into L 10m scale=2 m=4 (5m); e^-1 at 0.5 ms
V1 in 0 PULSE(0 1 0 1n 1n 1 2)
R1 in o1 1k
C1 o1 0 1u m=2
R2 in o2 1k
RC2_ser o2 s2 1k m=2
C2 s2 0 1u m=2
R3 in o3 1k
C3 o3 0 1u m=2
RC3_par o3 0 2k m=2
R4 in o4 1k
C4 o4 0 1u m=2
CC4_par o4 0 0.5u m=2
R5 in o5 1k
LC5_ser o5 t5 100m m=2
C5 t5 0 1u m=2
R7 in o7 10
L7 o7 0 20m m=2
R8 in o8 500 scale=2
C8 o8 0 0.5u scale=2 m=2
R9 in o9 10
L9 o9 0 10m scale=2 m=4
.tran 10u 5m 0 10u
.meas tran o1 find v(o1) at=2m
.meas tran o2 find v(o2) at=3m
.meas tran o3 find v(o3) at=1m
.meas tran o4 find v(o4) at=3m
.meas tran o5 find v(o5) at=1m
.meas tran o7 find v(o7) at=0.5m
.meas tran o8 find v(o8) at=2m
.meas tran o9 find v(o9) at=0.5m
.end
