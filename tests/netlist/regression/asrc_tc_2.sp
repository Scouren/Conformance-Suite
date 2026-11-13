* ngspice tests/regression/misc/asrc-tc-2.cir without its .control block:
* a behavioural resistor (r3, mapped to a B source by inpcom.c) and a plain
* one (r2), both with tc1 = 1e-3, at .temp 127.
* Expected results: asrc_tc_2.expected.json
* Oracle: ngspice-45 (the run recorded in the expected file). The original
* deck's own check: i(v2) = i(v3) = 100/(1k*(1+100*0.001)) at DC and
* 10/(1k*(1+100*0.001)) in AC, within 1e-9.
v0  9 0  dc=0 ac=0
v1  1 0  dc=100 ac=10
r2  1 2  1k tc1=0.001
v2  2 0  dc=0 ac=0
r3  1 3  r = {1k + v(9)}  tc1=0.001
v3  3 0  dc=0 ac=0
.temp 127.0
.op
.ac dec 1 1kHz 1kHz
.end
