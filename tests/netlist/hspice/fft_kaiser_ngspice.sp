* HSPICE .fft with WINDOW=KAISER ALFA=3 [CR .FFT] (#82). Oracle: the DFT of
* ngspice twin of hspice/fft_kaiser.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* the exact samples 0.5 sin(2 pi 2k t) at t = 1m + 4m k/256, weighted by the
* standard symmetric Kaiser window I0(pi ALFA sqrt(1 - (2n/(NP-1) - 1)^2)) /
* I0(pi ALFA) (Harris 1978; numpy's kaiser(NP, pi ALFA)), scaled by
* 2/sum(w), sine phase, normalized to the largest bin.
* Expected results: fft_kaiser_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
vin out 0 sin(0 0.5 2k)
r1 out 0 1k
.tran 1u 6m
.fft v(out) start=1m stop=5m np=256 window=kaiser alfa=3
.end
