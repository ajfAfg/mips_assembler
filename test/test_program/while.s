_start:
	# initialization
	add	$s0, $zero, $zero
	add  	$s7, $zero, $zero

	# main
L1:
	slti	$t0, $s0, 10
	beq	$t0, $zero, N1
	sll  	$t0, $s0, 2
	add  	$t0, $s7, $t0
	sw	$s0, 0($t0)
	addi	$s0, $s0, 1
	j	L1
N1:

loop:
	j	loop			# Repeat for safety.

