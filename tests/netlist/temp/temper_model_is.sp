* A model parameter over temper: ngspice tests/regression/temper/temper-1.cir,
* is='temper+1000', which is 1027 at 27 C. Its own check reads @dplain[is];
* a 1 mA source here lets the operating point read it:
* v(1) = Vt ln(1 + 1m/1027).
* Expected results: temper_model_is.expected.json
.model dplain d is='temper+1000'
I1 0 1 dc 1m
D1 1 0 dplain
.op
.end
