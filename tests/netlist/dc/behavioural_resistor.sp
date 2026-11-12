* Behavioural resistors: an R whose value reads v() is ngspice's B source
* (inpcom.c:6832-6905), in its quoted, r={...} and braced forms.
* Expected results: behavioural_resistor.expected.json
* Oracle (analytic), over the sweep vin = Vs from -2 to 4 V:
*   r1 reads its own voltage: R = 1k (1 + |v(a)|) under rs1 = 1k, so
*     (Vs - x)(1 + |x|) = x and v(a) = x = sign(Vs) ((|Vs| - 2) + sqrt(Vs^2 + 4))/2
*   r2 reads v(in), a net that is none of its terminals: R = 1k (1 + |Vs|)
*     under rs2 = 1k, so v(b) = Vs (1 + |Vs|)/(2 + |Vs|)
*   r3 at .temp 127, dT = 100 K from the B source's 300.15 K (asrcload.c:41):
*     R = 500 (1 + 1.2) = 1100, times 1 + tc1 dT + tc2 dT^2 = 1.2, and m = 2
*     in parallel: i(vc) = -2 * 1.2/(1100 * 1.2) = -1/550
* reltol=1e-6 keeps Newton's error under the 1e-6 tolerance.
vin in 0 0
rs1 in a 1k
r1 a 0 '1k*(1+abs(v(a)))'
rs2 in b 1k
r2 b 0 r={1k*(1+abs(v(in)))}
vc c 0 1.2
r3 c 0 {500*(1+abs(v(c)))} tc1=1m tc2=10u m=2
.options reltol=1e-6
.temp 127
.dc vin -2 4 1
.end
