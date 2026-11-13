* HSPICE .dc var DEC np start stop [CR .DC]: np points per decade.
* ngspice twin of hspice/dc_dec_grid.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* Oracle: analytic divider, v(out) = v(in)/4 at 1, 3.162, 10, 31.62, 100 V.
* Expected results: dc_dec_grid_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
v1 in 0 1
r1 in out 3k
r2 out 0 1k
.dc v1 dec 2 1 100
.end
