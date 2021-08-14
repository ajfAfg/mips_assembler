_start:
	# initialization
	addi	$s0, $zero, 2
	add	$s7, $zero, $zero
	
	addi	$t0, $zero, 0
	addi 	$t1, $zero, 1
	addi 	$t2, $zero, 2
	addi 	$t3, $zero, 3
	addi 	$t4, $zero, 4
	addi 	$t5, $zero, 5
	sw	$t0,  0($s7)
	sw   	$t1,  4($s7)
	sw   	$t2,  8($s7)
	sw   	$t3, 12($s7)
	sw   	$t4, 16($s7)
	sw   	$t5, 20($s7)

	# main
	sll	$t0, $s0, 2
	add  	$t0, $s7, $t0
	lw	$s1, 0($t0)
	lw   	$s2, 20($s7)

loop:
	j	loop			# Repeat for safety.
