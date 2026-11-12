* HSPICE W element: a resistive line (50 ohm/m, 0.2 m) under a held step
* ngspice twin of hspice/w_settle.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* must settle to its DC divider and stay there.
* Expected results: w_settle_ngspice.expected.json
* Oracle (analytic): the DC limit of the fitted model. G0 = 0, so the fit
* adds the floor G = 2 pi lo C0 = 2e-4 S/m (lo = R0/(2 pi L0)/100, see
* dev/devices/w-s-elements.md) and the line's exact DC ABCD with that G
* gives v(b) = 0.62410020 V; without the floor it would be 100/160 = 0.625.
* A laplace_nd realization that loses a slow section's DC gain drifts off
* it (0.6217 V by 2 us on VerA before 6355aaf1).
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
Vin in 0 DC 0 PULSE(0 1 0.2n 0.1n 0.1n 1 2)
Rs in a 50
W1 a 0 b 0 rlgcmodel=line n=1 l=0.2
RL b 0 100
.model line w modeltype=rlgc n=1 lo=300n co=120p ro=50
.tran 0.1n 2u
.end
