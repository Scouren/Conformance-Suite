* `.jitter` is refused: ESPice reads `.meas tran ... jitter`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: jitter.expected.json
v1 clk 0 sffm(0 1 1meg 0.5 10.1meg)
r1 clk 0 1k
.tran 0.1n 2u
.jitter tran trig v(clk) val=0 td=50n
.end
