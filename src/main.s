.align 2
.arm

.set DISPCNT, 0x4000000
.set VRAM, 0x6000000
.set PALRAM, 0x5000000
.set OBJVRAM, 0x06010000
.set OAM, 0x07000000

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

.include "src/bg0.s"

.text
.global main
main:
    mov r0, #DISPCNT                @Display Controller reg
    mov r1, #0b100000000            @Mode 0 + BG0 enabled
    str r1, [r0]

    mov r0, #0x4000000              @Setting up BG0 with:
    add r0, #8
    mov r1, #0b11100010000000000    @Priority = 0; TileBase = 0; Mosaic = false; palette = 16/16; MapBase = 4; Size = 512x512
    str r1, [r0]

    ldr r3, =bg0Tiles              @Tile source
    mov r4, #VRAM                  @VRAM base pointer + TileBase * 0x4000
    mov r5, #8                     @4bpp tile size is 8 words
    dma0_copy r3, r4, r5

    ldr r3, =bg0Pal               @Test palette
    mov r4, #PALRAM               @Palette memory
    mov r5, #8                    @Each color is 16bit
    dma0_copy r3, r4, r5

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
    addne X_offset, #1                    @if "right" scrolls bg accordingly
input.left:
    and r1, r0, #0b00010000         @and "left" bit is set
    cmp r1, #0
    subne X_offset, #1                    @if "left" scrolls bg accordingly

    mov r1, #0x4000000              @Stores current x scroll to BG0 X-offset reg
    add r1, #0x10
    strh X_offset, [r1]

input.up:
    and r1, r0, #0b10000000         @and "up" bit is set
    cmp r1, #0
    subne Y_offset, #1                    @if "up" scrolls bg accordingly

input.down:
    and r1, r0, #0b01000000         @and "down" bit is set
    cmp r1, #0
    addne Y_offset, #1                    @if "down" scrolls bg accordingly

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
