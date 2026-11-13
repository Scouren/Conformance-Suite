* HSPICE pass/fail bisection through LEVEL=3: the WHEN measure has a value
* ngspice twin of optimize/passfail_level3.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* only while the divider output reaches 2 V somewhere in the sweep, so the
* search finds the smallest rx that still passes.
* Oracle: analytic, max v(out) = 5 rx / (1k + rx) >= 2 V for
* rx >= 2k/3 = 666.67 ohm; the last passing value is within RELIN * 9900
* ohm above it.
* Expected results: passfail_level3_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rx=opt1(5k, 100, 10k)
v1 in 0 5
r1 in out 1k
r2 out 0 rx
.model optmod opt level=3 relin=1e-8 itropt=60
.dc v1 0 5 0.1 sweep optimize=opt1 results=vcross model=optmod
.meas dc vcross when v(out)=2 goal=5
.end
