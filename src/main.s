.align 2
.arm

.set DISPCNT, 0x4000000
.set VRAM, 0x6000000
.set PALRAM, 0x5000000
.set OBJVRAM, 0x06010000
.set OAM, 0x07000000

.include "src/bg0.s"
.include "src/obj0.s"

.include "src/dma.s"
.include "src/sprite.s"

.text
.global main
main:
    mov r0, #DISPCNT                @Display Controller reg
    mov r1, #0b1000101000000        @Mode 0 + BG0 enabled + OBJ enabled + 1D OBJ mapping
    str r1, [r0]

    mov r0, #0x4000000              @Setting up BG0 with:
    add r0, #8
    mov r1, #0b11100010000000000    @Priority = 0; TileBase = 0; Mosaic = false; palette = 16/16; MapBase = 4; Size = 512x512
    str r1, [r0]

    ldr r0, =bg0Tiles               @Tile source
    mov r1, #VRAM                   @VRAM base pointer + TileBase * 0x4000
    mov r2, #3*8                    @4bpp tile size is 8 words
    bl dma0_copy

    ldr r0, =bg0Map                 @GRIT generated map
    mov r1, #VRAM                   @VRAM + MapBase*0x800
    add r1, #0x2000
    mov r2, #2048                   @512x512 bg uses 4 base maps (4*0x800 bytes/4bytes per word)
    bl dma0_copy

    ldr r0, =bg0Pal                 @GRIT palette
    mov r1, #PALRAM                 @Palette memory
    mov r2, #8                      @Each color is 16bit
    bl dma0_copy

    ldr r0, =obj0Tiles
    mov r1, #0x6000000
    add r1, #0x10000                @OBJ tile vram location
    add r1, #32                     @Tile base 1 -> 32 bytes offset
    mov r2, #8
    bl dma0_copy

    ldr r0, =obj0Pal
    mov r1, #0x05000000             @OBJ palette pointer
    add r1, #0x200                  @Copies a couple colors to the first palette slot
    mov r2, #8
    bl dma0_copy

    mov r0, #10                     @X = 10
    mov r1, #10                     @Y = 10
    mov r2, #0                      @Square
    mov r3, #0                      @8x8
    mov r4, #1                      @Tile base = 1
    mov r5, #0                      @Palette slot = 0
    bl create_sprite

X_offset .req r6
Y_offset .req r7
    mov X_offset, #0
    mov Y_offset, #0
forever:
    mov r0, #0x4000000              @r0 = KEYINPUT
    add r0, #0x130
    ldr r0, [r0]                    @Load user input

input.start:
input.right:
    and r1, r0, #0b00100000         @and "right" bit is set
    cmp r1, #0
    addne X_offset, #1              @if "right" scrolls bg accordingly
input.left:
    and r1, r0, #0b00010000         @and "left" bit is set
    cmp r1, #0
    subne X_offset, #1              @if "left" scrolls bg accordingly

    mov r1, #0x4000000              @Stores current x scroll to BG0 X-offset reg
    add r1, #0x10
    strh X_offset, [r1]

input.up:
    and r1, r0, #0b10000000         @and "up" bit is set
    cmp r1, #0
    subne Y_offset, #1              @if "up" scrolls bg accordingly

input.down:
    and r1, r0, #0b01000000         @and "down" bit is set
    cmp r1, #0
    addne Y_offset, #1              @if "down" scrolls bg accordingly

    mov r1, #0x4000000              @Stores current y scroll to BG0 Y-offset reg
    add r1, #0x12
    strh Y_offset, [r1]
input.end:

wait_vblank:
    mov r0, #0x4000000              @Loads REG_VCOUNT
    add r0, #6
    ldrh r0, [r0]
    cmp r0, #161                    @Waits for first vblank scanline
    bne wait_vblank

    b forever

.data
.align 2
test_pal:
    .hword 0xFF00, 0xFFFF

test_tile:
    .word 0x00011000
    .word 0x00111100
    .word 0x01111110
    .word 0x11111111
    .word 0x11111111
    .word 0x01111110
    .word 0x00111100
    .word 0x00011000
