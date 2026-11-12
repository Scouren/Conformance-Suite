* HSPICE LFSR is refused naming the card, not run as DC 0 (#72).
* ngspice twin of invalid/source_lfsr_refused.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
V1 a 0 lfsr(0 1 0 1n 1n 10n 7 1)
R1 a 0 1k
.tran 1n 10n
.end
