_start:
	# initialization
	addi	$sp, $zero, 1
	sll	$sp, $sp, 10		# Assume that data memory size is 16B.

	addi	$a0, $zero, 5		# n
	addi	$a1, $zero, 1		# a (from)
	addi	$a2, $zero, 2		# b (tmp)
	addi	$a3, $zero, 3		# c (to)
	jal	hanoi

loop:
	j	loop			# Repeat for safety.


	# main
hanoi:
	addi	$sp, $sp, -20
	sw	$a0, 0($sp)
	sw	$a1, 4($sp)
	sw	$a2, 8($sp)
	sw	$a3, 12($sp)
	sw	$ra, 16($sp)
	slti	$t0, $a0, 2
	beq	$t0, $zero, L1
	add	$a2, $a3, $zero
	jal	move
	lw	$a2, 8($sp)
	lw	$ra, 16($sp)
	addi	$sp, $sp, 20
	jr		$ra
L1:
	addi	$a0, $a0, -1
	lw	$a2, 12($sp)
	lw	$a3, 8($sp)
	jal	hanoi
	lw	$a0, 0($sp)
	jal	move
	addi	$a0, $a0, -1
	lw	$a1, 8($sp)
	lw	$a2, 4($sp)
	lw	$a3, 12($sp)
	jal	hanoi
	lw	$a0, 0($sp)
	lw	$a1, 4($sp)
	lw	$a2, 8($sp)
	lw	$a3, 12($sp)
	lw	$ra, 16($sp)
	addi	$sp, $sp, 20
	jr	$ra

# In the textbook definition, this subroutine performs standard output.
# However, since we have not implemented the system call,
# we cannot reproduce it completely.
# Therefore, we will check the value stored in the variable
# by outputting the value as the result of the calculation of the instruction.
move:
	add	$t0, $a0, $zero
	add	$t1, $a1, $zero
	add	$t2, $a2, $zero
	jr	$ra
