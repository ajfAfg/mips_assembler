_start:
	# initialization
	addi	$t0, $zero, 1
	addi 	$t1, $zero, 2
	sw	$t0, 0($zero)
	sw   	$t1, 4($zero)
	add	$s7, $zero, $zero
	
	# main
	lw	$s0, 0($s7)
	lw   	$s1, 4($s7)
	addi	$t0, $s7, 8
	sw	$s1, 0($t0)

loop:
	j	loop			# Repeat for safety.

