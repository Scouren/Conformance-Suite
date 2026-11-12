* ngspice .save forms beyond v() and i() (manual 11.6.1), as ngspice 44.2
* saves them: a bare node name is that node, x#branch is i(x), vdb(n) is
* v(n), and v(b)/10 saves v(b). ESPice dropped all four, so this card
* narrowed the output to v(b) alone (ngspice-examples noi-ring51-demo.sp:
* `.save in bufout v(t1)`).
* Expected results: save_forms.expected.json
* Oracle (analytic): a 3 V source over three equal resistors, so
* v(in) = 3, v(b) = 2, v(c) = 1 and i(vcc) = -3 / 3k = -1 mA.
vcc in 0 3
r1 in b 1k
r2 b c 1k
r3 c 0 1k
.save in vcc#branch vdb(c) v(b)/10
.op
.end
