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

    mov r7, #0xFF
    and r8, r7, r1
    and r2, #0b11
    lsl r7, r2, #14
    orr r8, r7              @OBJ attrib 0

    mov r7, #0x100
    add r7, #0xFF
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

@ r0 -> X
@ r1 -> Y
@ r2 -> id
update_sprite:
    push { r3 }

    mov r3, #0xFF           @Truncates Y to 8 bits
    and r1, r3
    add r3, #0x100          @Truncates X to 9 bits
    and r0, r3

    lsl r2, #3
    add r2, #0x7000000      @Calculate OAM address of sprite

    ldrh r3, [r2]           @Loads attrib 0 and updates Y
    and r3, #0xFF00
    orr r3, r1
    strh r3, [r2], #2

    ldrh r3, [r2]           @Loads attrib 1 and updates X
    and r3, #0xFE00
    orr r3, r0
    strh r3, [r2]

    pop { r3 }
    bx lr

.data
.align 2
sprite_num:
    .word 0
