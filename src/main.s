.align 2
.arm

.set DISPCNT, 0x4000000
.set VRAM, 0x6000000
.set PALRAM, 0x5000000

.macro dma0_copy src dest size
    mov r0, #0x4000000              @DMA0 source
    add r0, #0xB0
    str \src, [r0]

    mov r0, #0x4000000              @DMA0 destination
    add r0, #0xB4
    str \dest, [r0]

    mov r0, #0x4000000              @DMA0 word count
    add r0, #0xB8
    strh \size, [r0]

    mov r0, #0x4000000              @DMA0 control reg
    add r0, #0xBA
    mov r1, #0b1000010000000000     @Increment src and dest addr; no repeat; tranfer type = 32bits; start immediately; won't cause an IRQ; enables channel
    strh r1, [r0]
.endm

.global main

.text
main:
    mov r0, #DISPCNT                @Display Controller reg
    mov r1, #0b100000000            @Mode 0 + BG0 enabled
    str r1, [r0]

    mov r0, #0x4000000              @Setting up BG0 with:
    add r0, #8
    mov r1, #0b11100010000000000    @Priority = 0; TileBase = 0; Mosaic = false; palette = 16/16; MapBase = 4; Size = 256x256
    str r1, [r0]

    ldr r3, =test_tile              @Tile source
    mov r4, #VRAM                   @VRAM base pointer + TileBase * 0x4000
    mov r5, #8                      @Tile size is 8 words
    dma0_copy r3, r4, r5

    ldr r3, =test_pal               @Test palette
    mov r4, #PALRAM                 @Palette memory
    mov r5, #1                      @For now needs only two colors, which is a word long for both
    dma0_copy r3, r4, r5

    mov r6, #0
    mov r7, #0
forever:
    mov r0, #0x4000000              @r0 = KEYINPUT
    add r0, #0x130
    ldr r0, [r0]                    @Load user input

input.start:
input.right:
    and r1, r0, #0b00100000         @and "right" bit is set
    cmp r1, #0
    addne r6, #1                    @if "right" scrolls bg accordingly
input.left:
    and r1, r0, #0b00010000         @and "left" bit is set
    cmp r1, #0
    subne r6, #1                    @if "left" scrolls bg accordingly

    mov r1, #0x4000000              @Stores current x scroll to BG0 X-offset reg
    add r1, #0x10
    strh r6, [r1]

input.up:
    and r1, r0, #0b10000000         @and "up" bit is set
    cmp r1, #0
    subne r7, #1                    @if "up" scrolls bg accordingly

input.down:
    and r1, r0, #0b01000000         @and "down" bit is set
    cmp r1, #0
    addne r7, #1                    @if "down" scrolls bg accordingly

    mov r1, #0x4000000              @Stores current y scroll to BG0 Y-offset reg
    add r1, #0x12
    strh r7, [r1]
input.end:

wait_vblank:
    mov r0, #0x4000000              @Loads REG_VCOUNT
    add r0, #6
    ldrh r0, [r0]
    cmp r0, #161                    @Waits for first vblank scanline
    bne wait_vblank

    b forever

.data
test_tile:
    .byte 0x00, 0x00, 0x00, 0x00
    .byte 0x00, 0x00, 0x00, 0x00
    .byte 0x00, 0x00, 0x00, 0x00
    .byte 0x00, 0x10, 0x01, 0x00
    .byte 0x00, 0x10, 0x01, 0x00
    .byte 0x00, 0x00, 0x00, 0x00
    .byte 0x00, 0x00, 0x00, 0x00
    .byte 0x00, 0x00, 0x00, 0x00

test_pal:
    .byte 0x03, 0xE0
    .byte 0x57, 0xE0
