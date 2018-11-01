.include "src/dma.s"
.include "src/sprite.s"

.include "src/bg0.s"
.include "src/obj0.s"

.text
.align 2
.thumb_func
.global main
.type main, %function
main:
    mov r0, #0x4                    @Display Controller reg
    lsl r0, #24
    mov r1, #0b1000101              @Mode 0 + BG0 enabled + OBJ enabled + 1D OBJ mapping
    lsl r1, #6
    strh r1, [r0]

    mov r0, #0x4                    @Setting up BG0 with:
    lsl r0, #24
    add r0, #8
    mov r1, #0b110001               @Priority = 0; TileBase = 0; Mosaic = false; palette = 16/16; MapBase = 4; Size = 512x512
    lsl r1, #10
    strh r1, [r0]

    ldr r0, =bg0Tiles               @Tile source
    mov r1, #0x6                    @VRAM base pointer + TileBase * 0x4000
    lsl r1, #24
    mov r2, #3*8                    @4bpp tile size is 8 words
    bl dma3_copy

    ldr r0, =bg0Map                 @GRIT generated map
    mov r1, #0x6                    @VRAM + MapBase*0x800
    lsl r1, #24
    mov r2, #0x20
    lsl r2, #8
    add r1, r2
    mov r2, #1                      @512x512 bg uses 4 base maps (4*0x800 bytes/4bytes per word)
    lsl r2, #11
    bl dma3_copy

    ldr r0, =bg0Pal                 @GRIT palette
    mov r1, #0x5                    @Palette memory
    lsl r1, #24
    mov r2, #8                      @Each color is 16bit
    bl dma3_copy

    ldr r0, =obj0Tiles
    mov r1, #0x6
    lsl r1, #8
    add r1, #0x1                    @OBJ tile vram location
    lsl r1, #16
    add r1, #32                     @Tile base 1 -> 32 bytes offset
    mov r2, #1
    lsl r2, #9                      @64x64 sprite is 8x8 tiles -> 64 tiles * 8 word per tile
    bl dma3_copy

    ldr r0, =obj0Pal
    mov r1, #0x5                    @OBJ palette pointer
    lsl r1, #24
    mov r2, #0x2
    lsl r2, #8
    add r1, r2                      @Copies colors to the first palette slot
    mov r2, #8
    bl dma3_copy

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
    mov r0, #0x4                    @r0 = KEYINPUT
    lsl r0, #24
    mov r1, #0x13
    lsl r1, #4
    add r0, r1
    ldr r0, [r0]                    @Load user input
    mvn r0, r0                      @Makes pressed button = 1 (default is = 0)

input.start:
input.right:
    mov r1, #1
    lsl r1, #4
    and r1, r0                      @and "right" bit is set
    cmp r1, #0
    beq input.left
    add X, #1                       @if "right" scrolls bg accordingly
input.left:
    mov r1, #1
    lsl r1, #5
    and r1, r0                      @and "left" bit is set
    cmp r1, #0
    beq input.up
    sub X, #1                       @if "left" scrolls bg accordingly

input.up:
    mov r1, #1
    lsl r1, #6
    and r1, r0                      @and "up" bit is set
    cmp r1, #0
    beq input.down
    sub Y, #1                       @if "up" scrolls bg accordingly

input.down:
    mov r1, #1
    lsl r1, #7
    and r1, r0                      @and "down" bit is set
    cmp r1, #0
    beq input.end
    add Y, #1                       @if "down" scrolls bg accordingly
input.end:

    mov r0, #0x4                    @Loads REG_VCOUNT
    lsl r0, #24
    add r0, #6
wait_vblank:
    ldrh r1, [r0]
    cmp r1, #161                    @Waits for first vblank scanline
    bne wait_vblank

    mov r0, X                       @OAM should be updated only on vblank to avoid tearing
    mov r1, Y
    mov r2, #0
    bl update_sprite                @Updates sprite 0 with X and Y

    ldr r0, =sprite_rotate          @Loads rotate struct and updates the angle
    ldr r1, [r0, #4]
    add r1, #0x10                   @Makes sprite rotate forever
    str r1, [r0, #4]

    mov r1, #0x7                    @Address of first affine matrix
    lsl r1, #24
    add r1, #0x6
    mov r2, #1                      @1 matrix wanted
    mov r3, #8                      @OBJ matrix update
    swi 0xF                         @Syscall to generate affine matrix from rotate struct

    b forever

.section .iwram
.align 2
sprite_rotate:
    .hword 0b100000000              @X scale
    .hword 0b100000000              @Y scale
    .hword 0x0                      @angle
