.text
.align 2
.thumb_func

@ r0 -> x
@ r1 -> y
@ r2 -> shape (0->square, 1->horizontal, 2->vertical)
@ r3 -> size  (0-3)
@ r4 -> tile base
@ r5 -> palette number
create_sprite:
    push { r6, r7 }

    mov r7, #0xFF           @Truncates Y
    and r1, r7
    mov r7, #0b11           @Truncates shape
    and r2, r7
    lsl r2, #14             @Shifts shape to correct bits
    mov r7, #0b11           @Affine sprite with double size box
    lsl r7, #8
    orr r1, r7
    orr r1, r2              @OBJ attrib 0

    mov r7, #0x1
    lsl r7, #8
    add r7, #0xFF
    and r0, r7              @Truncates X
    mov r7, #0b11
    and r3, r7              @Truncates size
    lsl r3, #14             @Shifts size to correct bit
    orr r0, r3              @OBJ attrib 1

    mov r7, #0b11111
    lsl r7, #5
    add r7, #0b11111
    and r4, r7              @Truncates tile base
    mov r7, #0b1111
    and r5, r7              @Truncates palette number
    lsl r5, #12
    orr r4, r5              @OBJ attrib 2

    ldr r2, =sprite_num
    ldr r3, [r2]
    add r3, #1
    str r3, [r2]            @Updates current number of sprites
    sub r3, #1

    lsl r3, #3              @Calculates the memory address of the new sprite
    mov r2, #0x7
    lsl r2, #24
    add r3, r2

    strh r1, [r3]           @Saves the new sprite to OAM
    add r3, #2
    strh r0, [r3]
    add r3, #2
    strh r4, [r3]

    pop { r6, r7 }
    bx lr

@ r0 -> X
@ r1 -> Y
@ r2 -> id
.align 2
.thumb_func
update_sprite:
    push { r3, r4 }

    mov r3, #0xFF           @Truncates Y to 8 bits
    and r1, r3

    mov r4, #1
    lsl r4, #8
    add r3, r4              @Truncates X to 9 bits
    and r0, r3

    lsl r2, #3              @ID * 32 is the position in OAM
    mov r4, #0x7
    lsl r4, #24             @0x7000000 is OAM base address
    add r2, r4              @Calculate OAM address of sprite

    ldrh r3, [r2]           @Loads attrib 0 and updates Y
    mov r4, #0xFF
    lsl r4, #8
    and r3, r4              @Clears Y bits
    orr r3, r1              @OR the current Y to attrib 0
    strh r3, [r2]           @Stores attrib 0 back
    add r2, #2

    ldrh r3, [r2]           @Loads attrib 1 and updates X
    mov r4, #0xFE
    lsl r4, #8
    and r3, r4              @Clears X bits
    orr r3, r0              @OR the current X to attrib 1
    strh r3, [r2]           @Stores attrib 1 back

    pop { r3, r4 }
    bx lr

.data
.align 2
sprite_num:
    .word 0
