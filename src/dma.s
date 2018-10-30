@ r0 -> src
@ r1 -> dest
@ r2 -> size
.text
dma0_copy:
    push { r3 }

    mov r3, #0x4000000              @DMA0 source
    add r3, #0xB0
    str r0, [r3]

    mov r3, #0x4000000              @DMA0 destination
    add r3, #0xB4
    str r1, [r3]

    mov r3, #0x4000000              @DMA0 word count
    add r3, #0xB8
    strh r2, [r3]

    mov r3, #0x4000000              @DMA0 control reg
    add r3, #0xBA
    mov r1, #0b1000010000000000     @Increment src and dest addr; no repeat; tranfer type = 32bits; start immediately; won't cause an IRQ; enables channel
    strh r1, [r3]

    pop { r3 }
    bx lr