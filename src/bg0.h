
//{{BLOCK(bg0)

//======================================================================
//
//	bg0, 512x512@4, 
//	Transparent color : FF,00,FF
//	+ palette 16 entries, not compressed
//	+ 3 tiles (t|f|p reduced) not compressed
//	+ regular map (in SBBs), not compressed, 64x64 
//	Total size: 32 + 96 + 8192 = 8320
//
//	Time-stamp: 2018-10-31, 20:38:04
//	Exported by Cearn's GBA Image Transmogrifier, v0.8.15
//	( http://www.coranac.com/projects/#grit )
//
//======================================================================

#ifndef GRIT_BG0_H
#define GRIT_BG0_H

#define bg0TilesLen 96
extern const unsigned int bg0Tiles[24];

#define bg0MapLen 8192
extern const unsigned short bg0Map[4096];

#define bg0PalLen 32
extern const unsigned short bg0Pal[16];

#endif // GRIT_BG0_H

//}}BLOCK(bg0)
