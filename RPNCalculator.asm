
.data
prompt:   .asciiz "Enter an RPN equation: "
result:   .asciiz "Result: "
errorMsg: .asciiz "Invalid equation or division by zero.\n"
input:    .space 256
.align 2
stack:    .space 1024

.text
.globl main

main:
    # Read the entire equation first
    li $v0, 4
    la $a0, prompt
    syscall

    li $v0, 8
    la $a0, input
    li $a1, 256
    syscall

    la $s0, input       # Input pointer
    la $s1, stack       # Stack base
    li $s2, 0           # Stack size
    li $s3, 0           # 0 = compact, 1 = spaced

    # Detect whether tokens use spaces
    move $t0, $s0
detect:
    lbu $t1, 0($t0)
    beq $t1, $zero, parse
    li $t2, 32
    beq $t1, $t2, spaced
    addiu $t0, $t0, 1
    j detect

spaced:
    li $s3, 1

parse:
    lbu $t0, 0($s0)
    beq $t0, $zero, finish
    li $t1, 10
    beq $t0, $t1, finish

    # Skip spaces and tabs
    li $t1, 32
    beq $t0, $t1, advance
    li $t1, 9
    beq $t0, $t1, advance

    # Check whether this is a number
    li $t1, 48
    blt $t0, $t1, check_negative
    li $t1, 57
    ble $t0, $t1, number
    j operator

check_negative:
    li $t1, 45
    bne $t0, $t1, operator
    beq $s3, $zero, operator

    # A negative number must have a digit
    lbu $t2, 1($s0)
    li $t1, 48
    blt $t2, $t1, operator
    li $t1, 57
    bgt $t2, $t1, operator

    li $t7, -1
    addiu $s0, $s0, 1
    j read_number

number:
    li $t7, 1

read_number:
    li $t3, 0
number_loop:
    lbu $t0, 0($s0)
    li $t1, 48
    blt $t0, $t1, number_done
    li $t1, 57
    bgt $t0, $t1, number_done

    addiu $t0, $t0, -48
    mul $t3, $t3, 10
    addu $t3, $t3, $t0
    addiu $s0, $s0, 1

    # Compact expressions use single digits
    beq $s3, $zero, number_done
    j number_loop

number_done:
    mul $t3, $t3, $t7
    j push

operator:
    # Operators need two operands
    slti $t1, $s2, 2
    bne $t1, $zero, error

    addiu $s2, $s2, -1
    sll $t1, $s2, 2
    addu $t2, $s1, $t1
    lw $t5, 0($t2)       # Right operand

    addiu $s2, $s2, -1
    sll $t1, $s2, 2
    addu $t2, $s1, $t1
    lw $t4, 0($t2)       # Left operand

    li $t1, 43
    beq $t0, $t1, add_op
    li $t1, 45
    beq $t0, $t1, sub_op
    li $t1, 42
    beq $t0, $t1, mul_op
    li $t1, 47
    beq $t0, $t1, div_op
    j error

add_op:
    addu $t3, $t4, $t5
    j push_result

sub_op:
    subu $t3, $t4, $t5
    j push_result

mul_op:
    mul $t3, $t4, $t5
    j push_result

div_op:
    beq $t5, $zero, error
    div $t4, $t5
    mflo $t3
    j push_result

push_result:
    addiu $s0, $s0, 1

push:
    li $t1, 256
    bge $s2, $t1, error
    sll $t1, $s2, 2
    addu $t2, $s1, $t1
    sw $t3, 0($t2)
    addiu $s2, $s2, 1
    j parse

advance:
    addiu $s0, $s0, 1
    j parse

finish:
    li $t0, 1
    bne $s2, $t0, error

    li $v0, 4
    la $a0, result
    syscall

    li $v0, 1
    lw $a0, 0($s1)
    syscall
    j exit

error:
    li $v0, 4
    la $a0, errorMsg
    syscall

exit:
    li $v0, 10
    syscall
