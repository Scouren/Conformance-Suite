* A BJT's current-crowding base resistance (IRB) stamps gx = 1/rbb with no
* d(rbb)/dV term in DC and AC, as ngspice does.
* Expected results: bjt_rbb_irb_ac.expected.json (ngspice-44.2)
* ngspice bjtload.c and bjtacld.c stamp gx = 1/rbb at the operating point
* and drop rbb's bias derivative. gummel_poon.va's exact Jacobian kept it,
* so the operating point agreed and the AC base current did not.
.options reltol=1e-6 abstol=1e-15 vntol=1e-9
vb b 0 dc 0.85 ac 1
vc c 0 dc 2
q1 c b 0 qn
.model qn npn is=1e-15 bf=100 rb=100 irb=1e-4 rbm=20
.op
.ac dec 1 1meg 1meg
.end
