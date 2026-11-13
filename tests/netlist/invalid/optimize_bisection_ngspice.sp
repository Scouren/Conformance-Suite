* HSPICE bisection (METHOD=BISECTION) over two parameters: the manual's
* ngspice twin of invalid/optimize_bisection.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* AND over several bisected parameters is not specified, so the deck must
* be refused, not run some other way.
* Expected results: optimize_bisection_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rx=opt1(1k, 100, 10k)
.param ry=opt1(1k, 100, 10k)
v1 in 0 5
r1 in out ry
r2 out 0 rx
.model optmod opt method=bisection
.dc v1 0 5 1 sweep optimize=opt1 results=vout model=optmod
.meas dc vout find v(out) at=5 goal=2
.end
