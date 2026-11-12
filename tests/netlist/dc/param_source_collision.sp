* .dc sweeps the V card V1, not the .param v1 of the same name (SpiceRack P3-056)
* Expected results: param_source_collision.expected.json
.param v1=5
V1 a 0 1
R1 a 0 1k
V2 b 0 {v1}
R2 b 0 1k
.dc V1 1 3 1
.end
