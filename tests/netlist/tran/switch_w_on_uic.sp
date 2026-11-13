* KNOWN GAP: W ON under .tran uic needs the UIC flag in the model (#266)
* Expected results: switch_w_on_uic.expected.json
* A uic transient skips the .op (SpiceRack P8-045 follow-up). ngspice's UIC
* load seeds W's ON as HYST_ON in state0 (cswload.c:39-56), dctran.c:387-392
* copies it to state1, and inside a positive band every later iteration
* reads state1 (cswload.c:65-71, kept by :130): won starts on and stays on.
* woff, wnone and son (S reads state0, which INITTRAN rewrites from the
* unsolved 0 control, swload.c:99-108) start off. The control sits inside
* the band throughout. Each output is 1 V over 1k into ron=1 (on, 1/1001 V)
* or roff=1meg (off).
vs s 0 1
ic 0 x 0.5m
vx x 0 0
vc c 0 0.5
ron s owon 1k
roff s owoff 1k
rnone s ownone 1k
rs s oson 1k
won owon 0 vx cswp ON
woff owoff 0 vx cswp OFF
wnone ownone 0 vx cswp
son oson 0 c 0 swp ON
.model cswp csw(it=0.5m ih=0.2m ron=1 roff=1meg)
.model swp sw(vt=0.5 vh=0.2 ron=1 roff=1meg)
.tran 1u 5u uic
.end
