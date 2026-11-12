* W switch, OFF: the ON/OFF word never reaches the in-band .op state (SpiceRack P8-045)
* Expected results: switch_w_off.expected.json
* Controls below (lo), inside (mid) and above (hi) the band it=0.5m +- 0.2m.
* ngspice parses the word (cswparam.c:24-31), but at the .op mid reads
* CKTstate1, which no .op iteration writes, so it starts off (cswload.c:65-71);
* neg (negative band) and zero (ih=0, control at it) start on (:72-88).
* Each output is 1 V over 1k into ron=1 (on, 1/1001 V) or roff=1meg (off).
vs s 0 1
ilo 0 xlo 0.1m
vxlo xlo 0 0
rlo s olo 1k
imid 0 xmid 0.5m
vxmid xmid 0 0
rmid s omid 1k
ihi 0 xhi 0.9m
vxhi xhi 0 0
rhi s ohi 1k
ineg 0 xneg 0.5m
vxneg xneg 0 0
rneg s oneg 1k
izero 0 xzero 0
vxzero xzero 0 0
rzero s ozero 1k
wlo olo 0 vxlo cswp OFF
wmid omid 0 vxmid cswp OFF
whi ohi 0 vxhi cswp OFF
wneg oneg 0 vxneg cswn OFF
wzero ozero 0 vxzero cswz OFF
.model cswp csw(it=0.5m ih=0.2m ron=1 roff=1meg)
.model cswn csw(it=0.5m ih=-0.2m ron=1 roff=1meg)
.model cswz csw(ron=1 roff=1meg)
.op
.end
