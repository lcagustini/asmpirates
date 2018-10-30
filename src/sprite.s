.arm
.text
.align 2

@ r0 -> x
@ r1 -> y
@ r2 -> shape (0->square, 1->horizontal, 2->vertical)
@ r3 -> size  (0-3)
@ r4 -> tile base
@ r5 -> palette number
create_sprite:
    push { r6, r7, r8 }

    mov r7, #0xF
    and r8, r7, r1
    and r2, #0b11
    lsl r7, r2, #14
    orr r8, r7              @OBJ attrib 0

    mov r7, #0x1F
    and r6, r7, r0
    and r3, #0b11
    lsl r7, r3, #14
    orr r6, r7              @OBJ attrib 1

    mov r7, #0b1111100000
    add r7, #0b11111
    and r4, r7
    and r5, #0b1111
    lsl r5, #12
    mov r7, #0
    orr r7, r4
    orr r7, r5              @OBJ attrib 2

    ldr r0, =sprite_num
    ldr r1, [r0]
    add r1, #1
    str r1, [r0]            @Updates current number of sprites
    sub r1, #1

    lsl r1, #3              @Calculates the memory address of the new sprite
    add r1, #0x7000000

    strh r8, [r1], #2       @Saves the new sprite to OAM
    strh r6, [r1], #2
    strh r7, [r1], #2

    pop { r6, r7, r8 }
    bx lr

.data
.align 2
sprite_num:
    .word 0
