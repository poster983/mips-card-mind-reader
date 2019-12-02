# ============================================
# MACROS
#	Set random seed
.macro 	setseed (%generator)
	#	Get System Time
	li 	$v0, 30
	syscall
	#	High Order Bits to seed
	move 	$a1, $a0
	li	$a0, %generator
	li	$v0, 40
.end_macro

#	Set register to random value
.macro setrandom (%generator, %register, %max)
	li	$a0, %generator
	move	$a1, %max
	li	$v0, 42
	syscall
	move	%register, $a0
.end_macro

#	Print Integer
.macro print_int (%x)
	li $v0, 1
	add $a0, $zero, %x
	syscall
.end_macro

#	Print Constant String
.macro print_str (%str)
	.data
	myLabel: .asciiz %str
	.text
	li $v0, 4
	la $a0, myLabel
	syscall
.end_macro

#	Grow stack by number of bytes
.macro stackgrow (%bytes)
	subi	$sp, $sp, %bytes
	ori	$t9, $0, %bytes
	sw	$t9, -4($sp)
.end_macro

#	Set stack value to register
.macro stackstore (%offset, %register)
	sw	%register, %offset($sp)
.end_macro

#	Get stack value into register
.macro stackload (%offset, %register)
	lw	%register, %offset($sp)
.end_macro

#	Pop stack based on stored width
.macro stackpop
	lw	$t9, -4($sp)
	add	$sp, $sp, $t9
.end_macro

#	Function Start (store $ra)
.macro fstart
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
.end_macro

#	Function Return
.macro freturn (%v0, %v1)
	move	$v0, %v0
	move	$v1, %v1
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr 	$ra
.end_macro
#	Function Return
.macro freturn (%v0)
	move	$v0, %v0
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr 	$ra
.end_macro
#	Function Return
.macro freturn
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr 	$ra
.end_macro
#	Ending Sound
.macro	song
	li $s0, 0
	li $t7, 37
	loop:
	sll $s1, $s0, 1
	lh $t0, calls($s1)
	lh $t1, notes($s1)
	lh $t2, durations($s1)
	lh $t3, instruments($s1)
	lh $t4, volumes($s1)

	move $v0, $t0
	move $a0, $t1
	move $a1, $t2
	move $a2, $t3
	move $a3, $t4
	syscall

	addi $s0, $s0, 1
	bne $s0, $t7, loop
.end_macro
#	Exit program
.macro exit
	li	$v0,10
	syscall
.end_macro
# ============================================
# DATA
.data
magnitude: .word 6
calls: .half 33, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 31, 32, 33, 33, 33, 33, 33, 31, 32, 33
notes: .half 64, 64, 400, 64, 400, 64, 400, 64, 700, 62, 700, 60, 700, 57, 400, 57, 400, 64, 400, 62, 700, 62, 700, 57, 400, 57, 400, 55, 800, 62, 62, 64, 60, 59, 59, 450, 57
durations: .half 900, 300, 0, 300, 0, 300, 0, 600, 0, 600, 0, 600, 0, 300, 0, 300, 0, 300, 0, 600, 0, 600, 0, 300, 0, 300, 0, 300, 0, 1200, 300, 300, 600, 600, 450, 0, 200
instruments: .half 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
volumes: .half 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100
# ============================================
# PROGRAM
.text
.globl main
main:
#	Set 
	setseed(0)
	
	li	$s0, 0
	lw 	$s1, magnitude
	# $s2 = current mask (bit width)
	# $s3 = history (bits covered)
	# $s4 = 1 << max_magnitude
	li 	$s4, 1
	grow_mag_0:
		beq	$t0, $s1, grow_done_0
		addi	$t0, $t0, 1
		sll	$s4, $s4, 1
		j	grow_mag_0
	grow_done_0:
	
	
	# While Loop
	while_main:
	slt	$t0, $s0, $s1
	addi	$s0, $s0, 1
	bnez 	$t0, do_main
	beqz	$s3, do_main
	j	postwhile_main
	do_main:
		# With Generator 0, set $t1 to random value
		# with maximum of $s1
		setrandom(0, $t1, $s1)
		
		# $s2 = mask = 1 << max_magnitude
		li 	$s2, 1
		li	$t2, 0
		grow_mag_1:
			beq	$t2, $t1, grow_done_1
			addi	$t2, $t2, 1
			sll	$s2, $s2, 1
			j	grow_mag_1
		grow_done_1:
		
		# if mask ($s2) in history ($s3), retry
		and 	$t0, $s2, $s3
		bnez	$t0, do_main
		
		# Else, history = history | mask
		or	$s3, $s3, $s2
		
		# Print the card
		move 	$a0, $s2
		move	$a1, $s4
		jal 	print_card
		
		# Prompt input
		print_str("Is your number in this card? (Y/N): ")
		jal 	input_boolean
		
		# If input was y or Y
		beqz	$v0, post_input
			# output($s6) = output | mask
			or	$s7, $s7, $s2
		post_input:
		
		# print new line
		print_str("\n")
		
		# Go back to while conditions
		j 	while_main
	postwhile_main:
	
	# print output
	print_str("Your number is: ")
	print_int($s7)
	print_str("\n")
	song
exit


input_boolean:
	fstart
	li 	$v0, 12
	syscall
	li 	$t0, 89
	beq	$v0, $t0, input_boolean_y
	addi	$t0, $t0, 32
	beq	$v0, $t0, input_boolean_y
	freturn ($0)
	input_boolean_y:
	li	$v0, 1
	freturn
	
print_card: # a0 is mask, a1 is max
	fstart
	# move stored values to stack
	stackgrow(16)
	stackstore(0, $s2)
	stackstore(4, $s4)
	stackstore(8, $s5)
	stackstore(12, $s6)
	# move input to stored
	move	$s2, $a0
	move	$s4, $a1
	
	# print card label
	print_str("\nCard: ")
	print_int($s2)
	print_str("\n")
	
	# while index ($s5) < max ($s4)
	while_print:
	slt 	$t0, $s5, $s4
	bnez	$t0, do_print
	j postwhile_print
	do_print:
		# if index & mask == mask, print number
		and	$t1, $s5, $s2
		bne	$t1, $s2, skip_print
			print_int($s5)
		print_str(",\t")
		
		# increment print count ($s6)
		addi	$s6, $s6, 1
		
		# if print count ($s6) >= 8, newline and reset
		slti	$t1, $s6, 8
		bnez	$t1, skip_print
		print_str("\n")
		li	$s6, 0
		skip_print:
		
		# increment index
		addi	$s5, $s5, 1
		j while_print
	postwhile_print:
	
	# reload stack and return
	stackload(0, $s2)
	stackload(4, $s4)
	stackload(8, $s5)
	stackload(12, $s6)
	stackpop
	freturn
	
