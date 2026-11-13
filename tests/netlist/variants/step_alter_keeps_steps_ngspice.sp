* HSPICE .step with .alter (#66): the base run keeps its step rows, and the .alter
* ngspice twin of variants/step_alter_keeps_steps.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* run steps again with its own change. i(v1) = -v/rv.
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rv=1k
V1 a 0 1
R1 a 0 'rv'
.step param rv list 1k 2k
.op
.alter
V1 a 0 2
.end
