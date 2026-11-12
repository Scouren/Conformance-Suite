* S switch, OFF: the ON/OFF word seeds the in-band .op state (SpiceRack P8-045)
* Expected results: switch_s_off.expected.json
* Controls below (lo), inside (mid) and above (hi) the band vt=0.5 +- 0.2.
* Only mid reads the flag (swload.c:43-60, kept at :69-75). neg sits inside a
* negative band and zero exactly at vt with vh=0: ngspice starts both on
* whatever the flag (swload.c:76-88 read the .op's never-written CKTstate1).
* Each output is 1 V over 1k into ron=1 (on, 1/1001 V) or roff=1meg (off).
vs s 0 1
vlo clo 0 0.1
vmid cmid 0 0.5
vhi chi 0 0.9
vzero czero 0 0
rlo s olo 1k
rmid s omid 1k
rhi s ohi 1k
rneg s oneg 1k
rzero s ozero 1k
slo olo 0 clo 0 swp OFF
smid omid 0 cmid 0 swp OFF
shi ohi 0 chi 0 swp OFF
sneg oneg 0 cmid 0 swn OFF
szero ozero 0 czero 0 swz OFF
.model swp sw(vt=0.5 vh=0.2 ron=1 roff=1meg)
.model swn sw(vt=0.5 vh=-0.2 ron=1 roff=1meg)
.model swz sw(ron=1 roff=1meg)
.op
.end
