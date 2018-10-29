
@{{BLOCK(bg0)

@=======================================================================
@
@	bg0, 512x512@4, 
@	Transparent color : FF,00,FF
@	+ palette 16 entries, not compressed
@	+ 2 tiles (t|f|p reduced) not compressed
@	+ regular map (flat), not compressed, 64x64 
@	Total size: 32 + 64 + 8192 = 8288
@
@	Time-stamp: 2018-10-29, 16:22:12
@	Exported by Cearn's GBA Image Transmogrifier, v0.8.15
@	( http://www.coranac.com/projects/#grit )
@
@=======================================================================

.data
bg0Tiles:
	.word 0x01011101,0x11111000,0x01011111,0x10110101,0x11111111,0x01100100,0x11011111,0x00110110

bg0Pal:
	.hword 0x01A0,0x07E0,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
	.hword 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000

@}}BLOCK(bg0)
