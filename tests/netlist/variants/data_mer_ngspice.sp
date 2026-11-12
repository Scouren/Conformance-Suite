* HSPICE external .data, concatenated (MER): three files stacked row-wise.
* ngspice twin of variants/data_mer.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* a.dat gives v1 in column 1 and rl in column 2; b.dat remaps both; c.dat
* names no columns, so it keeps b.dat's, and its short last row reads 0
* for v1. Column rl is a .param, v1 a source.
* Oracle: analytic, v(b) = v1 rl / (1k + rl) per row.
* Expected results: data_mer_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rl=1k
v1 a 0 1
r1 a b 1k
r2 b 0 rl
.data rows MER
+ FILE='data_mer.assets/a.dat' rl=2 v1=1
+ FILE='data_mer.assets/b.dat' rl=1 v1=2
+ FILE='data_mer.assets/c.dat'
.enddata
.dc data=rows
.end
