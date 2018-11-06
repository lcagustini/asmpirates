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
    mov r2, #25*8                   @4bpp tile size is 8 words
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

    mov r0, #88                     @X = SCREEN_WIDTH/2 - SPRITE_SIZE/2
    mov r1, #48                     @Y = SCREEN_HEIGHT/2 - SPRITE_SIZE/2
    mov r2, #0                      @Square
    mov r3, #11                     @64x64
    mov r4, #1                      @Tile base = 1
    mov r5, #0                      @Palette slot = 0
    bl sprite.create

angle .req r6
speed .req r7
    mov angle, #0
    mov speed, #0
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
    add angle, #20                  @if "right" rotates sprite accordingly
input.left:
    mov r1, #1
    lsl r1, #5
    and r1, r0                      @and "left" bit is set
    cmp r1, #0
    beq input.up
    sub angle, #20                  @if "left" rotates sprite accordingly

input.up:
    mov r1, #1
    lsl r1, #6
    and r1, r0                      @and "up" bit is set
    cmp r1, #0
    beq input.down
    mov r1, #1
    lsl r1, #6
    cmp speed, r1
    beq input.down
    add speed, #1                   @if "up" increases speed

input.down:
    mov r1, #1
    lsl r1, #7
    and r1, r0                      @and "down" bit is set
    cmp r1, #0
    beq input.end
    cmp speed, #0
    beq input.end
    sub speed, #1                   @if "down" decreases speed
input.end:

    mov r0, #0x4                    @Loads REG_VCOUNT
    lsl r0, #24
    add r0, #6
wait_vblank:
    ldrh r1, [r0]
    cmp r1, #161                    @Waits for first vblank scanline
    bne wait_vblank

    ldr r0, =sprite_rotate          @Loads rotate struct and updates the angle
    strh angle, [r0, #4]

rotate_sprite:
    mov r1, #0x7                    @Address of first affine matrix
    lsl r1, #24
    add r1, #0x6
    mov r2, #1                      @1 matrix wanted
    mov r3, #8                      @OBJ matrix update
    push { r1 }
    swi 0xF                         @Syscall to generate affine matrix from rotate struct
    pop { r1 }

load_start:
load_cos:
    ldrh r2, [r1]                   @Loads cos from OBJ affine matrix
    mov r0, #1
    lsl r0, #15
    and r0, r2                      @Checks for negative number (last bits)
    mov r4, #0
    cmp r0, #0
    beq load_sin                    @If positive, r4 = 0
    mov r4, #1                      @Else, r4 = 1
    mov r0, #0x1
    lsl r0, #16
    sub r0, r2                      @Converts negative number to positive
    mov r2, r0

load_sin:
    ldrh r3, [r1, #8]               @Loads sin from OBJ affine matrix
    mov r0, #1
    lsl r0, #15
    and r0, r3                      @Checks for negative number (last bits)
    mov r5, #0
    cmp r0, #0
    beq load_end                    @If positive, r5 = 0
    mov r5, #1                      @Else, r5 = 1
    mov r0, #0x1
    lsl r0, #16
    sub r0, r3                      @Converts negative number to positive
    mov r3, r0
load_end:

get_dx:
    mov r0, speed
    mul r2, r0                      @Speed * cos
    asr r2, #8                      @Converts back to integer
    cmp r4, #1
    bne update_x                    @If cos was negative, negate the result here
    neg r2, r2

update_x:
    mov r0, #0
    bl sprite.get_x
    add r2, r0                      @Adds dx to x
    mov r0, #0
    mov r1, r2
    bl sprite.set_x                 @Updates x on the sprite array

get_dy:
    mov r0, speed
    mul r3, r0                      @Speed * sin
    asr r3, #8                      @Converts back to integer
    cmp r5, #1
    bne update_y                    @If sin was negative, negate the result here
    neg r3, r3

update_y:
    mov r0, #0
    bl sprite.get_y
    add r3, r0                      @Adds dy to y
    mov r0, #0
    mov r1, r3
    bl sprite.set_y                 @Updates y on the sprite array

update_bg:
    mov r0, #0x4                    @Should be updated only on vblank to avoid tearing
    lsl r0, #24
    add r0, #0x10                   @BG0 x offset reg
    asr r2, #8                      @Converts fixed point to integer
    strh r2, [r0]                   @Stores scroll x

    mov r0, #0x4
    lsl r0, #24
    add r0, #0x12                   @BG0 x offset reg
    asr r3, #8                      @Converts fixed point to integer
    strh r3, [r0]                   @Stores scroll y

    b forever

.section .iwram
.align 2
sprite_rotate:
    .hword 0b100000000              @X scale (8bit fractional part)
    .hword 0b100000000              @Y scale (8bit fractional part)
    .hword 0x0                      @angle
