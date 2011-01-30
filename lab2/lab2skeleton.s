    area    lab2, code, readwrite   
    export  hamming
    export  div
    
hamming
        stmfd r13!, {r1-r12, r14}

        ; r0 - code
        ; r1 - bit 3 (1st digit)
        ; r2 - bit 5 (2nd digit) ; r3 - bit 6 (3rd digit)
        ; r4 - bit 7 (4th digit)
        ; r5 - checksum
        ; r6 - temp
        ; r7 - correctable boolean

        ; counts the correction parity (8th bit)
        bic r7, r0, #0x7f
        mov r7, r7, lsr #7

        ; isolate each bit
        ; while we're at it, count the number of 1s and ``add'' it to r7.
        ; since we only care about whether or not it is odd, we simply flip it
        ; every time a 1 is encountered.
        ; since only a 1s are counted, flipping is accomplished by xor
        ; (eor in arm asm).
        bic r1, r0, #0xfb ; clear all bits besides the 3rd one
        eor r7, r7, r1, lsr #2
        bic r2, r0, #0xef ; clear all bits besides the 5th one
        eor r7, r7, r2, lsr #4
        bic r3, r0, #0xdf ; clear all bits besides the 6th one
        eor r7, r7, r3, lsr #5
        bic r4, r0, #0xbf ; clear all bits besides the 7th one
        eor r7, r7, r4, lsr #6

        ; boolean operations
        ; the algorithm is the same for all parity bits.
        ; first the parity bit is isolated r6 isn't used for the first one
        ; because r5 will be emptied with the first checksum.
        ; then we simply ``add'' the bits that are to be checked by the
        ; checksum. Just as with r7, since we only care about whether or not
        ; it is odd, we can use xor.
        ; calculate checksum with the first parity bit
        bic r5, r0, #0xfe
        eor r7, r7, r5
        eor r5, r5, r1, lsr #2
        eor r5, r5, r2, lsr #4
        eor r5, r5, r4, lsr #6
        ; calculate checksum with the second parity bit
        bic r6, r0, #0xfd
        eor r7, r7, r6, lsr #1
        eor r6, r6, r1, lsr #1
        eor r6, r6, r3, lsr #4
        eor r6, r6, r4, lsr #5
        add r5, r5, r6
        ; calculate checksum with the third parity bit
        bic r6, r0, #0xf7
        eor r7, r7, r6, lsr #3
        eor r6, r6, r2, lsr #1
        eor r6, r6, r3, lsr #2
        eor r6, r6, r4, lsr #3
        add r5, r5, r6, lsr #1

        ; if the checksum is valid (all checksums == r5 = 0)
        ; the choice in these branches minimizes branching instructions and
        ; allow for the lengthier code to keep the pipeline full.
        ; setting r0 to -1 is a single instruction that doesn't need to utilize
        ; the pipeline.
        cmp r5, #0
        beq recon

        ; is it correctable?
        cmp r7, #0
        beq exf

        ; error correction is placed right before reconstruction, because there
        ; are two times where it may reconstruct the bits:
        ;     1. r5 = 0
        ;     2. there's a single error
        ; xor the original hamming code with 0 everywhere except the bit that
        ; needs to be corrected (1 at the bit that needs to be corrected)
        ; compliments that bit
        sub r5, r5, #1          ; correct the error
        mov r6, #1              ; arm asm doesn't allow an immediate to be shifted, otherwise this could've been skipped
        eor r0, r0, r6, lsl r5
        bic r1, r0, #0xfb
        bic r2, r0, #0xef
        bic r3, r0, #0xdf
        bic r4, r0, #0xbf
recon   mov r0, r1, lsr #2      ; reconstruct
        add r0, r0, r2, lsr #3
        add r0, r0, r3, lsr #3
        add r0, r0, r4, lsr #3

done    ldmfd r13!, {r1-r12, r14}
        bx lr      ; Return to the C program    

exf     mov r0, #-1 ; return(EXIT_FAILURE);
        b done

div
        stmfd r13!, {r1-r12, r14}

        ; assumes the flow chart provided in the division discussion is correct

        ; r0 - dividend
        ; r1 - divisor
        ; r2 - quotient
        ; r3 - remainder
        ; r4 - counter
        mov r2, #0 ; initialize quotient to 0
        mov r3, r0 ; initialize remainder to dividend
        mov r4, #0x10 ; initialize counter to 16
        mov r1, r1, LSL #0x10 ; logical left shift divisor 16 places
cloop   sub r3, r3, r1 ; remainder = remainder - divisor; cloop is the counter loop
        cmp r3, #0 ; remainder < 0
        blt rless
        mov r2, r2, LSL #1 ; left shift quotient
        add r2, r2, #1 ; lsb = 1
shftd   mov r1, r1, LSR #1 ; right shift divisor, msb = 0

        cmp r4, #0 ; counter > 0
        bgt dcnt

        mov r0, r2

        ldmfd r13!, {r1-r12, r14}
        bx lr      ; Return to the C program    

dcnt    sub r4, r4, #1 ; decrement counter
        b cloop

rless   add r3, r3, r1 ; remainder = remainder + divisor
        mov r2, r2, LSL #1 ; left shift quotient, lsb = 0
        b shftd

        end
