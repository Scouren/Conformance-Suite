* `.acphasenoise` is refused: ESPice reads `.noise`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: acphasenoise.expected.json
vref in 0 dc 0 ac 1
r1 in out 1k
c1 out 0 1n
.ac dec 1 1k 1meg
.acphasenoise v(out) vref carrier=1g
.end
