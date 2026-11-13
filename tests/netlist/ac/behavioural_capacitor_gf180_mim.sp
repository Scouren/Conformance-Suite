* gf180's MIM capacitor (sm141064.ngspice subckt mim_1p0fF, its body as
* written): a voltage-dependent `c='...v(1, 2)...'` with temper inside a
* subcircuit .param, read at a DC bias, and X card m=2.
* Expected results: behavioural_capacitor_gf180_mim.expected.json
* Oracle: ngspice-45, the run recorded in the expected file. It equals the
* closed form: the c= network's small-signal capacitance is m C(V0), so
* i(v) = -j 2 pi f m C(V0) with C(V) = c_c0 (1 + c_vcr1 V + c_vcr2 V^2),
* c_c0 = (c_cox A + c_capsw P) (1 + c_tc1 dT + c_tc2 dT^2), dT = 75 - 25.
.param mim_corner_1p0fF=1 mc_c_cox_1p0fF=0
.subckt mim_1p0fF 1 2  c_length=l c_width=w dtemp=0 par=1
.param
+ c_cox='0.987e-3*mim_corner_1p0fF'
+ c_capsw='3.3e-10*mim_corner_1p0fF'
+ c_tnom=25
+ c_tc1=1.302e-5
+ c_tc2=-4.93e-9
+ c_vcr1=6.079e-6
+ c_vcr2=1.268e-6
+ c_area='c_length*c_width'
+ c_peri='2*(c_length+c_width)'
+ c_c0='(c_cox*c_area+c_capsw*c_peri)*(1+c_tc1*(temper+dtemp-c_tnom)+c_tc2*(temper+dtemp-c_tnom)*(temper+dtemp-c_tnom))'
c_cap 1 2 c='c_c0*(1+ c_vcr1*v(1, 2)+c_vcr2*v(1,2)*v(1,2) )*(1+mc_c_cox_1p0fF)'
.ends mim_1p0fF
vin a 0 dc 3 ac 1
x1 a 0 mim_1p0fF c_length=10u c_width=10u
vin2 b 0 dc -2 ac 1
x2 b 0 mim_1p0fF c_length=20u c_width=5u m=2
.temp 75
.op
.ac lin 1 1meg 1meg
.end
