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
.align 2
.arm
main:
    mov r0, #DISPCNT                @Display Controller reg
    mov r1, #0b1000101000000        @Mode 0 + BG0 enabled + OBJ enabled + 1D OBJ mapping
    strh r1, [r0]

    mov r0, #0x4000000              @Setting up BG0 with:
    add r0, #8
    mov r1, #0b1100010000000000     @Priority = 0; TileBase = 0; Mosaic = false; palette = 16/16; MapBase = 4; Size = 512x512
    strh r1, [r0]

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
    mov r2, #512                    @64x64 sprite is 8x8 tiles -> 64 tiles * 8 word per tile
    bl dma0_copy

    ldr r0, =obj0Pal
    mov r1, #0x05000000             @OBJ palette pointer
    add r1, #0x200                  @Copies colors to the first palette slot
    mov r2, #8
    bl dma0_copy

    mov r0, #10                     @X = 10
    mov r1, #10                     @Y = 10
    mov r2, #0                      @Square
    mov r3, #11                     @64x64
    mov r4, #1                      @Tile base = 1
    mov r5, #0                      @Palette slot = 0
    bl create_sprite

X .req r6
Y .req r7
    mov X, #0
    mov Y, #0
forever:
    mov r0, #0x4000000              @r0 = KEYINPUT
    add r0, #0x130
    ldr r0, [r0]                    @Load user input
    mvn r0, r0                      @Makes pressed button = 1 (default is = 0)

input.start:
input.right:
    and r1, r0, #0b00010000         @and "right" bit is set
    cmp r1, #0
    addne X, #1                     @if "right" scrolls bg accordingly
input.left:
    and r1, r0, #0b00100000         @and "left" bit is set
    cmp r1, #0
    subne X, #1                     @if "left" scrolls bg accordingly

input.up:
    and r1, r0, #0b01000000         @and "up" bit is set
    cmp r1, #0
    subne Y, #1                     @if "up" scrolls bg accordingly

input.down:
    and r1, r0, #0b10000000         @and "down" bit is set
    cmp r1, #0
    addne Y, #1                     @if "down" scrolls bg accordingly
input.end:

wait_vblank:
    mov r0, #0x4000000              @Loads REG_VCOUNT
    add r0, #6
    ldrh r0, [r0]
    cmp r0, #161                    @Waits for first vblank scanline
    bne wait_vblank

    mov r0, X                       @OAM should be updated only on vblank to avoid tearing
    mov r1, Y
    mov r2, #0
    bl update_sprite                @Updates sprite 0 with X and Y

    ldr r0, =sprite_rotate          @Loads rotate struct and updates the angle
    ldr r1, [r0, #4]
    add r1, #0x10                   @Makes sprite rotate forever
    str r1, [r0, #4]

    mov r1, #0x7000000              @Address of first affine matrix
    add r1, #0x6
    mov r2, #1                      @1 matrix wanted
    mov r3, #8                      @OBJ matrix update
    swi 0xF0000                     @Syscall to generate affine matrix from rotate struct

    b forever

.data
.align 2
sprite_rotate:
    .hword 0b100000000              @X scale
    .hword 0b100000000              @Y scale
    .hword 0x0                      @angle
