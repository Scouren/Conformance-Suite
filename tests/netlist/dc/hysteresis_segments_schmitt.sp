* A split .dc over a bistable circuit reruns whole when a seam disagrees
* Expected results: hysteresis_segments_schmitt.expected.json
* A non-inverting Schmitt trigger: gain 50, feedback 1/3. Swept up from
* vin = -5, the output holds near -5 V to the fold at vin = 2.11 and jumps
* to +5 V by vin = 2.15 (ngspice's dctrcurv.c continues each point from the
* last). ESPice cuts a .dc of 201 points into 12 segments, each started cold
* two points before its own (src/analysis/dc/segments.zig). A cold start
* inside the band -2.11 < vin < 2.11 lands on the unstable middle branch, so
* segment 4, cold at vin = -1.75, continues to -1.7 there and disagrees with
* segment 3's continued end: the sweep reruns whole and stderr says
* "note: .dc vin -5 5 0.05 reruns whole: at seam 4 of 11 (-1.750000) ...".
* Stitched anyway, segments 4 to 8 report the middle branch over
* -1.7 < vin < 2.1, where ngspice reports the low one.
vin in 0 0
r1 in p 10k
r2 p out 20k
b1 out 0 v=5*tanh(10*v(p))
.dc vin -5 5 0.05
.end
