* gf180's behavioural poly resistor (sm141064.ngspice: `rb 1 2 r='...'`),
* reduced: subcircuit parameters, `temper` read inside one, and an X card
* m=2 that ngspice spreads onto the lowered B (inpcom.c:4253-4300).
* Expected results: behavioural_resistor_gf180.expected.json
* Oracle (analytic): r_n = lr/(wr - 2 r_dw) = 10/1.1,
*   r_temp = 1 + r_tc1 (T - 25) + r_tc2 (T - 25)^2 at T = 75 degC,
*   R(V) = r_temp r_n (7 + 0.01 |V|/r_n + 0.002 V^2/r_n^2);
* v(b) is the root of (Vs - x)/R(Vs - x) = x/100 and v(c) of
* 2 (Vs - y)/R(Vs - y) = y/100, each bisected to the last bit, and
* i(v1) = -(x + y)/100. ngspice-45 on this deck agrees to 1e-12.
.subckt rpoly 1 2 lr=10u wr=1u dtemp=0 r_rsh0=7 r_dw=-5e-8 r_dl=0 r_vc1=0.01 r_vc2=0.002
+ r_tc1=1.36e-3 r_tc2=6.5e-7 r_tnom=25 r_l='lr-2*r_dl' r_w='wr-2*r_dw' r_n='r_l/r_w'
+ r_temp='1+r_tc1*(temper+dtemp-r_tnom)+r_tc2*(temper+dtemp-r_tnom)*(temper+dtemp-r_tnom)'
rb 1 2 r='r_temp*r_n*(r_rsh0+r_vc1*abs(v(1,2))/r_n+r_vc2*abs(v(1,2))*abs(v(1,2))/r_n/r_n)'
.ends rpoly
v1 a 0 dc 0
x1 a b rpoly
rl1 b 0 100
x2 a c rpoly m=2
rl2 c 0 100
.options reltol=1e-6
.temp 75
.dc v1 0 5 1
.end
