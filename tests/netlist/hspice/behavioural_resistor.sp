* HSPICE behavioural resistors (User Guide E-2010.12 ch. 8 pp. 170-173,
* `Rxxx n1 n2 [R=]'equation'`) in the quoted and R= forms, run as
* ngspice's B source, with HSPICE's TNOM = 25 degC and default NOISE=1.
* KNOWN GAP: spice2rack writes RELV through, which ngspice lacks (reltol), and TC1/TC2 on a behavioural R, which ngspice's B scales from 27 degC, not TNOM (SpiceRack rows P3-144, P3-145) (Scouren/SpiceRack#24)
* Expected results: behavioural_resistor.expected.json
* Oracle (analytic), the circuit of tests/netlist/dc/behavioural_resistor.sp
* over the sweep vin = Vs from -2 to 4 V:
*   r1: v(a) = sign(Vs) ((|Vs| - 2) + sqrt(Vs^2 + 4))/2
*   r2, reading v(in): v(b) = Vs (1 + |Vs|)/(2 + |Vs|)
*   r3 at .temp 125, dT = 100 K from TNOM: R = 1100 times 1.2, m = 2,
*     i(vc) = -1/550
* The noise network NOISE=1 adds carries no DC current.
vin in 0 0
rs1 in a 1k
r1 a 0 '1k*(1+abs(v(a)))'
rs2 in b 1k
r2 b 0 r='1k*(1+abs(v(in)))'
vc c 0 1.2
r3 c 0 '500*(1+abs(v(c)))' tc1=1m tc2=10u m=2
.option relv=1e-6
.temp 125
.dc vin -2 4 1
.end
