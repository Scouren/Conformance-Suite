* B and E expressions past one bsource tape: 64 ops, 32 constants, stack
* depth 16, 8 control ports. Each splits into chained bsources (SpiceRack #7;
* cases from SpiceRack espice-issues/5-7/bound.py and P3-070's chain2.py).
* Expected results: bsource_split.expected.json
* Oracle (analytic), over the sweep v1 = x from -0.5 to 9.5 V, every point
* 0.5 V from any threshold or table point:
*   s1 = 33 v(1) summed left-deep (65 ops), s2 the same nested right-deep
*     (depth 33): both 33x
*   s3 = sum of i*v(ki), ki driven at i*x, i = 1..33 (33 ports, 33
*     constants, 131 ops): x * sum i^2 = 12529x; weights catch a permuted port
*   s4 = bound.py's 7-point ternary chain through (0,1) (1,3) (2,2) (3,5)
*     (4,4) (5,7) (6,6), 1 below 0 and 6 from 6 on
*   s5 = v(1) <= 1 ? 1 : ... v(1) <= 8 ? 8 : 0, eight nested conditions
*   s6 = pwl and s7 = TABLE over the 21 points (k, k^2), k = -1..19: at
*     x = k + 1/2, a segment midpoint, (k^2 + (k+1)^2)/2 = x^2 + 1/4. The
*     tables split at x = 8.5, a sweep point.
*   i(vx) = -1/R, R = 1k + sum i*v(ni) over n1..n8 at i V = 1204 ohm: the
*     behavioural R reads x as well, nine rows
v1 1 0 dc 0
ek1 k1 0 1 0 1
ek2 k2 0 1 0 2
ek3 k3 0 1 0 3
ek4 k4 0 1 0 4
ek5 k5 0 1 0 5
ek6 k6 0 1 0 6
ek7 k7 0 1 0 7
ek8 k8 0 1 0 8
ek9 k9 0 1 0 9
ek10 k10 0 1 0 10
ek11 k11 0 1 0 11
ek12 k12 0 1 0 12
ek13 k13 0 1 0 13
ek14 k14 0 1 0 14
ek15 k15 0 1 0 15
ek16 k16 0 1 0 16
ek17 k17 0 1 0 17
ek18 k18 0 1 0 18
ek19 k19 0 1 0 19
ek20 k20 0 1 0 20
ek21 k21 0 1 0 21
ek22 k22 0 1 0 22
ek23 k23 0 1 0 23
ek24 k24 0 1 0 24
ek25 k25 0 1 0 25
ek26 k26 0 1 0 26
ek27 k27 0 1 0 27
ek28 k28 0 1 0 28
ek29 k29 0 1 0 29
ek30 k30 0 1 0 30
ek31 k31 0 1 0 31
ek32 k32 0 1 0 32
ek33 k33 0 1 0 33
bs1 s1 0 v=v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)+v(1)
bs2 s2 0 v=v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)+(v(1)))))))))))))))))))))))))))))))))
bs3 s3 0 v=1*v(k1)+2*v(k2)+3*v(k3)+4*v(k4)+5*v(k5)+6*v(k6)+7*v(k7)+8*v(k8)+9*v(k9)+10*v(k10)+11*v(k11)+12*v(k12)+13*v(k13)+14*v(k14)+15*v(k15)+16*v(k16)+17*v(k17)+18*v(k18)+19*v(k19)+20*v(k20)+21*v(k21)+22*v(k22)+23*v(k23)+24*v(k24)+25*v(k25)+26*v(k26)+27*v(k27)+28*v(k28)+29*v(k29)+30*v(k30)+31*v(k31)+32*v(k32)+33*v(k33)
echain s4 0 value={V(1) < 0 ? 1 : V(1) < 1 ? 1 + (V(1) - 0) * ((3 - 1) / (1 - 0)) : V(1) < 2 ? 3 + (V(1) - 1) * ((2 - 3) / (2 - 1)) : V(1) < 3 ? 2 + (V(1) - 2) * ((5 - 2) / (3 - 2)) : V(1) < 4 ? 5 + (V(1) - 3) * ((4 - 5) / (4 - 3)) : V(1) < 5 ? 4 + (V(1) - 4) * ((7 - 4) / (5 - 4)) : V(1) < 6 ? 7 + (V(1) - 5) * ((6 - 7) / (6 - 5)) : 6}
bs5 s5 0 v=v(1) <= 1 ? 1 : v(1) <= 2 ? 2 : v(1) <= 3 ? 3 : v(1) <= 4 ? 4 : v(1) <= 5 ? 5 : v(1) <= 6 ? 6 : v(1) <= 7 ? 7 : v(1) <= 8 ? 8 : 0
bs6 s6 0 v=pwl(v(1), -1,1, 0,0, 1,1, 2,4, 3,9, 4,16, 5,25, 6,36, 7,49, 8,64, 9,81, 10,100, 11,121, 12,144, 13,169, 14,196, 15,225, 16,256, 17,289, 18,324, 19,361)
etab s7 0 table {v(1)} = (-1,1) (0,0) (1,1) (2,4) (3,9) (4,16) (5,25) (6,36) (7,49) (8,64) (9,81) (10,100) (11,121) (12,144) (13,169) (14,196) (15,225) (16,256) (17,289) (18,324) (19,361)
vx x 0 1
vn1 n1 0 1
vn2 n2 0 2
vn3 n3 0 3
vn4 n4 0 4
vn5 n5 0 5
vn6 n6 0 6
vn7 n7 0 7
vn8 n8 0 8
rb x 0 r={1k+1*v(n1)+2*v(n2)+3*v(n3)+4*v(n4)+5*v(n5)+6*v(n6)+7*v(n7)+8*v(n8)}
.dc v1 -0.5 9.5 1
.end
