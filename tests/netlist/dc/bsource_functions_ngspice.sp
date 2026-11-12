* B-source functions of ngspice's B parser (inpptree.c:138-177) that the
* tape runs as its own opcodes (models/bsource.va): sgn, cosh, pwr, sinh,
* asin, acos, asinh, acosh and atanh of a probed voltage, swept over
* x = -0.75..0.75 V, inside every domain (acosh reads x + 1.75, from its
* edge at 1). Run on CPU and GPU: each opcode in both device paths.
* Expected results: bsource_functions_ngspice.expected.json
* Oracle: ngspice-44.2, whose values are the C library's (ptfuncs.c PTsgn,
* PTcosh, PTpwr, PTsinh, PTasin, PTacos, PTasinh, PTacosh, PTatanh);
* pwr(x, 1.5) is sign(x)|x|^1.5, not numparam's |x|^1.5.
v1 a 0 dc 0
b1 o1 0 v=sgn(v(a))
b2 o2 0 v=cosh(v(a))
b3 o3 0 v=pwr(v(a), 1.5)
b4 o4 0 v=sinh(v(a))
b5 o5 0 v=asin(v(a))
b6 o6 0 v=acos(v(a))
b7 o7 0 v=asinh(v(a))
b8 o8 0 v=acosh(v(a) + 1.75)
b9 o9 0 v=atanh(v(a))
.dc v1 -0.75 0.75 0.25
.end
