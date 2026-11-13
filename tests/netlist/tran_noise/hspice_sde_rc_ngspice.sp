* HSPICE .trannoise METHOD=SDE TIME= [CR .TRANNOISE; RF Ch.9]: a 1k
* ngspice twin of tran_noise/hspice_sde_rc.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* resistor's thermal noise on 1 pF (tau = 1 ns), from a noiseless start.
* The march takes h = 1/(2 FMAX) = 2.5 ps (FMAX = 1/TSTEP) and lands on
* TIME = 1.001 ns exactly. Oracle: analytic for the backward-Euler scheme
* both METHOD=MC and SDE step: per step Var <- a^2 Var + b^2 2kTG/h with
* a = (C/h)/(G + C/h), b = 1/(G + C/h), at 25 degC, so onoise is the rms of
* the step-by-step recursion. As h -> 0 it is kT/C (1 - exp(-2t/tau)); at
* h/tau = 0.0025 the two differ by under 0.2 %.
* Expected results: hspice_sde_rc_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
r1 out 0 1k
c1 out 0 1p
.tran 5p 3n
.trannoise v(out) method=sde time=1.001n
.end
