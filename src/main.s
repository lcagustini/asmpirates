.align 2
.arm

.set DISPCNT, 0x4000000
.set VRAM, 0x6000000

.global main

.macro get_input reg
    mov \reg, #0x4000000
    add \reg, #0x130
    ldr \reg, [\reg]
.endm

.text
main:
    mov r0, #DISPCNT                @Display Controller reg
    mov r1, #0x400                  @Mode 3 + BG2 enabled
    add r1, r1, #3
    str r1, [r0]

X .req r5
Y .req r6
    mov X, #0                       @Dot X and Y
    mov Y, #0
forever:
    get_input r0                    @Get user input

input.start:
input.right:
    cmp X, #239                      @If X < 240
    bge input.left
    and r1, r0, #0b00100000         @and "right" bit is set
    cmp r1, #0
    addne X, #1                     @X += 1

input.left:
    cmp X, #0                        @If X > 0
    ble input.up
    and r1, r0, #0b00010000         @and "left" bit is set
    cmp r1, #0
    subne X, #1                     @X -= 1

input.up:
    cmp Y, #0                        @if Y > 0
    ble input.down
    and r1, r0, #0b10000000         @and "up" bit is set
    cmp r1, #0
    subne Y, #1                     @Y -= 1

input.down:
    cmp Y, #159                      @if Y < 160
    bge input.end
    and r1, r0, #0b01000000         @and "down" bit is set
    cmp r1, #0
    addne Y, #1                     @Y += 1
input.end:

wait_vblank:
    mov r0, #0x4000000              @Loads REG_VCOUNT
    add r0, #6
    ldrh r0, [r0]
    cmp r0, #161                    @Waits for first vblank scanline
    bne wait_vblank

    mov r1, #480
    lsl r0, X, #1
    mla r1, Y, r1, r0               @r1 = Y * (240 pixels per line * 2 bytes per pixel) + X * 2 bytes per pixel
    mov r0, #VRAM                   @Base VRAM pointer
    add r0, r1                      @Adds offset in r1 to base pointer

    mov r1, #0                      @r1 = black

    strh r1, [r0, #2]               @Resets area around dot to black
    strh r1, [r0, #-2]
    mov r2, #480
    strh r1, [r0, r2]
    add r2, #2
    strh r1, [r0, r2]
    sub r2, #4
    strh r1, [r0, r2]
    add r2, #2
    rsb r2, #0
    strh r1, [r0, r2]
    add r2, #2
    strh r1, [r0, r2]
    sub r2, #4
    strh r1, [r0, r2]

    mov r1, #0xFF                   @r1 = red
    strh r1, [r0]                   @Stores red to VRAM

    b forever
.unreq X
.unreq Y
