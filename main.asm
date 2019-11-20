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
	#ori	$at, $0, %bytes
	#sw	$at, -4($sp)
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
.macro stackpop(%bytes)
	#lw	$at, -4($sp)
	addi	$sp, $sp, %bytes
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

#	Exit program
.macro exit
	li	$v0,10
	syscall
.end_macro

#	Creates an array of words with n elements. first index contains the length
#	$v0 contains address
.macro newArray(%n)
	li $at, %n
	addi $a0, $at, 1 #add one space for storing length
	sll $a0, $a0, 2 # get number of bytes 
	li  $v0 9
        syscall # address of array is in $v0
        sw $at, ($v0) #store length in first index
.end_macro
#	Sets the %register to the index in the array
.macro setArray(%array, %index, %register)
	li $at, %index
	addi $at, $at, 1 #adding one to line it up and not include length
	sll $at, $at, 2 # get bytes to shift
	addu $at, %array, $at
	sw %register, ($at)	
.end_macro
#	same as set arry but it works wth immidiates
.macro setArrayI(%array, %index, %value)
	li $a0, %value
	setArray(%array, %index, $a0)
.end_macro
#	returns value at index from an array address
#	$v0 contains the word
.macro readArray(%array, %index)
	li $at, %index
	addi $at, $at, 1 #adding one to line it up and not include length
	sll $at, $at, 2 # get bytes to shift
	addu $at, %array, $at
	lw $v0, ($at)	
.end_macro

#===================
#Bitmap macros
.macro bm_drawRectangleI(%leftX, %topY, %width, %height, %colorCode)
	stackgrow(8)
	stackstore(0, $v0)
	stackstore(4, $a0)
		lw $v0, macroDrawRectangleArray
		setArrayI($v0, 0, %leftX)
		setArrayI($v0, 1, %topY)
		setArrayI($v0, 2, %width)
		setArrayI($v0, 3, %height)
		setArrayI($v0, 4, %colorCode)
		move $a0, $v0
		jal bm_drawRectangle
	stackload(0, $v0)
	stackload(4, $a0)
	stackpop(8)
.end_macro

.macro bm_drawRectangle(%leftX, %topY, %width, %height, %colorCode)
	stackgrow(8)
	stackstore(0, $v0)
	stackstore(4, $a0)
		lw $v0, macroDrawRectangleArray
		setArray($v0, 0, %leftX)
		setArray($v0, 1, %topY)
		setArray($v0, 2, %width)
		setArray($v0, 3, %height)
		setArrayI($v0, 4, %colorCode)
		move $a0, $v0
		jal bm_drawRectangle
	
	stackload(0, $v0)
	stackload(4, $a0)
	stackpop(8)
	
.end_macro

# ============================================
# DATA
.data
.align 2
frameBuffer: .space 0x80000 # space for a 512x256 image in the 0x10010000 data range
magnitude: .word 6
# ============================================
# PROGRAM
.text
.globl main
main:
	# Setup Bitmap
	jal bm_setup
	jal bm_buildBackground
	
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
	stackgrow(32)
	stackstore(0, $s2)
	stackstore(4, $s4)
	stackstore(8, $s5)
	stackstore(12, $s6)
	stackstore(16, $s7)
	stackstore(20, $s1)
	stackstore(24, $s0) #BM x
	stackstore(24, $s7) #BM y
	# move input to stored
	move	$s2, $a0
	move	$s4, $a1
	
	li $s0, 30
	li $s7, 75
	
	##find real card number
	move $a0, $s2
	jal log2
	addi $s1, $v0, 1
	
	
	#BM: Reset card number
	bm_drawRectangleI(241,35,15,30,0x654321)
	##BM: Print card number
	
	li $a0, 241
	li $a1, 35
	li $a2, 15
	move $a3, $s1
	jal bm_drawDigit
	# print card label
	print_str("\nCard: ")
	print_int($s1)
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
		######### START BITMAP 	
			li $t8, 10
			li $t9, 20
			bm_drawRectangle($s0,$s7,$t8,$t9,0x654321)
			move $a0, $s0
			move $a1, $s7
			li $a2, 10
			move $a3, $s5
			jal bm_drawNumber
			
		######### end bitmap
		
		# increment print count ($s6)
		addi	$s6, $s6, 1
		
		# Increment BITMAP X axis
		addi 	$s0, $s0, 24
		
		# if print count ($s6) >= 8, newline and reset
		slti	$t1, $s6, 8
		bnez	$t1, skip_print
		print_str("\n")
		li	$s6, 0
		# Increment BITMAP Y axis
		li $s0, 30
		addi 	$s7, $s7, 22
		
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
	stackload(16, $s7)
	stackload(20, $s1)
	stackload(24, $s0) #width
	stackload(24, $s7) #heigth
	stackpop(32)
	freturn
	
log2:
###########
# Finds the log 2 of a number
#I/O:
# $a0 - number (n)
# $v0 - rooted number (x)
###########
	fstart
		# set up vars
		li $v0, -1
		
		log2_loop:
			beqz $a0, log2_loop_exit
			addi $v0, $v0, 1
			srl $a0, $a0, 1
			
				j log2_loop
			
		log2_loop_exit:
		
		
	freturn 
	
digit_length:
############
# Finds the number of digits in $a0 and returns the number in $v0
############
	fstart
		move $v0, $zero
		digit_count_loop:
			div $a0, $a0, 10
			addi $v0, $v0, 1
		
		bnez $a0, digit_count_loop

	freturn

###############
#Bitmap Display Part
#Joseph Hassell
# Possible TODO: Move to own file
###############



#===================
#DATA Constants
.data
macroDrawRectangleArray: .word 0 # array address for the macro that fills the array to be passed to bm_drawRectangle

#===================
# Functions
.text

bm_setup: 
########################
# First time setup for the display. Also prints instructions to see bitmap in console
########################
	fstart
	
		print_str("###########################################################\n")
		print_str("#                MARS Bitmap Display Setup                #\n")
		print_str("# This program makes use of the MARS bitmap display tool! #\n")
		print_str("# To enable the display please follow these instructions. #\n")
		print_str("# 1. Go to \"Tools\" > \"Bitmap Display\"                     #\n")
		print_str("# 2. Ensure the following settings match your tool        #\n")
		print_str("#    The first 2 options are \"1\"                          #\n")
		print_str("#    Width is 512                                         #\n")
		print_str("#    Height is 256                                        #\n")
		print_str("#    Base address is set to 0x10010000                    #\n")
		print_str("# 3. Click on \"Connect to MIPS\"                           #\n")
		print_str("# The cards will still be printed in the console          #\n")
		print_str("###########################################################\n")
	
		newArray(5) # make array for drawRetangle
		sw $v0, macroDrawRectangleArray
	
		#jal bm_buildBackground #go build the background
	freturn
bm_buildBackground:
################
# This function Builds the base of the bitmap image
################
	fstart
		
		bm_drawRectangleI(0,0,512,256,0xadd8e6) # Blue sky
		bm_drawRectangleI(25,25,462,206,0x654321) # brown sign
		#border
		bm_drawRectangleI(0,0,512,5,0x000000) #top
		bm_drawRectangleI(0,0,5,256,0x000000) # left
		bm_drawRectangleI(507,0,5,256,0x000000) #right
		bm_drawRectangleI(0,251,512,5,0x000000) #bottom
		
		li $a0, 30
		li $a1, 75
		li $a2, 50
		li $a3, 234
		jal bm_drawNumber
		#jal bm_drawDigit
		
	freturn

bm_drawRectangle:
#################
# This function draws a rectangle with a solid color
# Temps:
# $t0 - our frame buffer
# $t1 through $t5 - Our params as temps
# $t6 - starting / ending address of rectangle in bitmap 
# Paramater: 
# $a0 - address of array that has the following params: [leftX, topY, width, height, colorCode]
#################
	fstart
	stackgrow(36)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $t3)
	stackstore(16, $t4)
	stackstore(20, $t5)
	stackstore(24, $t6)
	stackstore(28, $t7)
	stackstore(32, $t8)
		# load vars into memory
		la $t0, frameBuffer
		readArray($a0, 0)
		move $t1, $v0
		readArray($a0, 1)
		move $t2, $v0
		readArray($a0, 2)
		move $t3, $v0
		readArray($a0, 3)
		move $t4, $v0
		readArray($a0, 4)
		move $t5, $v0
		
		#got help on this function from stack overflow
		#check if should draw nothing
		beqz $t3, return_bm_drawRectangle 
		beqz $t4, return_bm_drawRectangle
		############
		#Find starting addresses
		add $t3, $t3, $t1 # find right side of rectangle
		add $t4, $t4, $t2 # bottom limit of rectangle
		
		sll $t1, $t1, 2 # convert x values to bytes 
		sll $t3, $t3, 2

		sll $t2,$t2,11 # scale y values to bytes we must multiply it by 512 (width) to get the row
		sll $t4,$t4,11
		
		addu $t6,$t2,$t0 # ending address for the width (add the y value to the starting address of the bitmap
		addu $t4,$t4,$t0 # ending address for height

		addu $t2,$t6,$t1 # collumn vals starting address 
		addu $t4,$t4,$t1

		addu $t6,$t6,$t3 # final ending address for the row
		li $t7,0x800 # bytes per row

		bm_drawRectangleYloop:
			move $t8,$t2 # current pixel in X loop

			bm_drawRectangleXloop:
				sw $t5,($t8) # put color into bitmap!!! (finally)
				addiu $t8,$t8,4 # move pointer one word
			bne $t8,$t6,bm_drawRectangleXloop # loop until we hit the edge

			addu $t2,$t2,$t7 # go down a row
			addu $t6,$t6,$t7 
		bne $t2,$t4,bm_drawRectangleYloop # keep going if not off the bottom of the rectangle
		
	return_bm_drawRectangle: 	
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $t3)
	stackload(16, $t4)
	stackload(20, $t5)
	stackload(24, $t6)
	stackload(28, $t7)
	stackload(32, $t8)
	stackpop(36)
	freturn
	

bm_drawNumber:
##############
# Draws the multi digit number in $a3
# Params: 
# $a0 - x
# $a1 - y
# $a2 - size
# #a3 - the number 
# Vars:
# $t1 - our changable number
# $t2 = 10
# $t0 - ammount to pad between each number

##############
	fstart
	stackgrow(12)
	stackstore(0, $t1)
	stackstore(4, $t2)
	stackstore(8, $t0)
		move $t1, $a3
		li $t2, 10
		srl $t0, $a2, 2
		add $t0, $t0, $a2
		
		jal digit_length
		
		
		#jal digit_length
		#move $t1, $v0
		
		## Loop to find the digits from high to lo
		bm_drawNumber_loop:
			div $t1, $t2
			mfhi $a3
			mflo $t1 # get new number
			#Draw number
			jal bm_drawDigit
			
			add $a0, $a0, $t0 # add padding
			
			
							
		bnez $t1, bm_drawNumber_loop
		
		
	stackload(0, $t1)
	stackload(4, $t2)
	stackload(8, $t0)
	stackpop(12)
	freturn

#############
bm_drawDigit:
#############
# This function prints out any char that matches the char code 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
# #a3 - the digit
#############
	fstart
		bne $a3, 1, bm_drawNumber_next1
			jal bm_drawDigit1 # draw 1
		j bm_drawNumber_return
		bm_drawNumber_next1:
		
		bne $a3, 2, bm_drawNumber_next2
			jal bm_drawDigit2 # draw 2
		j bm_drawNumber_return
		bm_drawNumber_next2:
		
		bne $a3, 3, bm_drawNumber_next3
			jal bm_drawDigit3 # draw 3
		j bm_drawNumber_return
		bm_drawNumber_next3:
		
		bne $a3, 4, bm_drawNumber_next4
			jal bm_drawDigit4 # draw 4
		j bm_drawNumber_return
		bm_drawNumber_next4:
		
		bne $a3, 5, bm_drawNumber_next5
			jal bm_drawDigit5 # draw 5
		j bm_drawNumber_return
		bm_drawNumber_next5:
		
		bne $a3, 6, bm_drawNumber_next6
			jal bm_drawDigit6 # draw 6
		j bm_drawNumber_return
		bm_drawNumber_next6:
		
		bne $a3, 7, bm_drawNumber_next7
			jal bm_drawDigit7 # draw 7
		j bm_drawNumber_return
		bm_drawNumber_next7:
		
		bne $a3, 8, bm_drawNumber_next8
			jal bm_drawDigit8 # draw 8
		j bm_drawNumber_return
		bm_drawNumber_next8:
		
		bne $a3, 9, bm_drawNumber_next9
			jal bm_drawDigit9 # draw 9
		j bm_drawNumber_return
		bm_drawNumber_next9:
		
		jal bm_drawDigit0 # base case draw 0
		
		
	bm_drawNumber_return:
	freturn
	
bm_drawDigit0:
#############
# This function prints out 0 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(28)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	stackstore(24, $t3)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	
		
		srl $t0, $s2, 2 #divide by 4 
		
		bm_drawRectangle($s0,$s1,$s2,$t0,0xffffff) # A
		
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		bm_drawRectangle($t1,$s1,$t0,$s2,0xffffff) # B
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
		add $t3, $s2, $s1# find relative y start value for D
		add $t3, $s2, $t3
		sub $t3, $t3, $t0
		bm_drawRectangle($s0,$t3,$s2,$t0,0xffffff) # D
		
		bm_drawRectangle($s0,$t2,$t0,$s2,0xffffff) # E
		
		bm_drawRectangle($s0,$s1,$t0,$s2,0xffffff) # F
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackload(24, $t3)
	stackpop(28)
	freturn
	

bm_drawDigit1:
#############
# This function prints out 1 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(24)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
		srl $t0, $s2, 2 #divide by 4 
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		bm_drawRectangle($t1,$s1,$t0,$s2,0xffffff) # B
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackpop(24)
	freturn

bm_drawDigit2:
#############
# This function prints out 2 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(28)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	stackstore(24, $t3)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
		srl $t0, $s2, 2 #divide by 4 
		bm_drawRectangle($s0,$s1,$s2,$t0,0xffffff) # A
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		bm_drawRectangle($t1,$s1,$t0,$s2,0xffffff) # B
		
		add $t3, $s2, $s1# find relative y start value for D
		add $t3, $s2, $t3
		sub $t3, $t3, $t0
		bm_drawRectangle($s0,$t3,$s2,$t0,0xffffff) # D
		
		add $t2, $s1, $s2 # find y value for C and E and G
		bm_drawRectangle($s0,$t2,$t0,$s2,0xffffff) # E
		
		
		bm_drawRectangle($s0,$t2,$s2,$t0,0xffffff) # G
		
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackload(24, $t3)
	stackpop(28)
	freturn

bm_drawDigit3:
#############
# This function prints out 3 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(28)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	stackstore(24, $t3)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
		srl $t0, $s2, 2 #divide by 4 
		bm_drawRectangle($s0,$s1,$s2,$t0,0xffffff) # A
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		bm_drawRectangle($t1,$s1,$t0,$s2,0xffffff) # B
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
		add $t3, $s2, $s1# find relative y start value for D
		add $t3, $s2, $t3
		sub $t3, $t3, $t0
		bm_drawRectangle($s0,$t3,$s2,$t0,0xffffff) # D
		
		add $t2, $s1, $s2 # find y value for C and E and F
		
		bm_drawRectangle($s0,$t2,$s2,$t0,0xffffff) # G
		
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackload(24, $t3)
	stackpop(28)
	freturn
	
bm_drawDigit4:
#############
# This function prints out 4 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(24)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
		srl $t0, $s2, 2 #divide by 4 

		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		bm_drawRectangle($t1,$s1,$t0,$s2,0xffffff) # B
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
		
		add $t2, $s1, $s2 # find y value for C and E and F
		
		bm_drawRectangle($s0,$s1,$t0,$s2,0xffffff) # F
		
		bm_drawRectangle($s0,$t2,$s2,$t0,0xffffff) # G
		
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackpop(24)
	freturn
	
bm_drawDigit5:
#############
# This function prints out 5 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(28)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	stackstore(24, $t3)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
		srl $t0, $s2, 2 #divide by 4 
		bm_drawRectangle($s0,$s1,$s2,$t0,0xffffff) # A
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
		add $t3, $s2, $s1# find relative y start value for D
		add $t3, $s2, $t3
		sub $t3, $t3, $t0
		bm_drawRectangle($s0,$t3,$s2,$t0,0xffffff) # D
		
		add $t2, $s1, $s2 # find y value for C and E and F
		
		bm_drawRectangle($s0,$s1,$t0,$s2,0xffffff) # F
		bm_drawRectangle($s0,$t2,$s2,$t0,0xffffff) # G
		
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackload(24, $t3)
	stackpop(28)
	freturn
	
bm_drawDigit6:
#############
# This function prints out 6 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(28)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	stackstore(24, $t3)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
		srl $t0, $s2, 2 #divide by 4 
		bm_drawRectangle($s0,$s1,$s2,$t0,0xffffff) # A
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
		add $t3, $s2, $s1# find relative y start value for D
		add $t3, $s2, $t3
		sub $t3, $t3, $t0
		bm_drawRectangle($s0,$t3,$s2,$t0,0xffffff) # D
		
		add $t2, $s1, $s2 # find y value for C and E and F
		
		bm_drawRectangle($s0,$t2,$t0,$s2,0xffffff) # E
		bm_drawRectangle($s0,$s1,$t0,$s2,0xffffff) # F
		bm_drawRectangle($s0,$t2,$s2,$t0,0xffffff) # G
		
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackload(24, $t3)
	stackpop(28)
	freturn
	
bm_drawDigit7:
#############
# This function prints out 7 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(24)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
		srl $t0, $s2, 2 #divide by 4 
		bm_drawRectangle($s0,$s1,$s2,$t0,0xffffff) # A
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		bm_drawRectangle($t1,$s1,$t0,$s2,0xffffff) # B
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackpop(24)
	freturn
	
bm_drawDigit8:
#############
# This function prints out 8 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(28)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	stackstore(24, $t3)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	
		
		srl $t0, $s2, 2 #divide by 4 
		
		bm_drawRectangle($s0,$s1,$s2,$t0,0xffffff) # A
		
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		bm_drawRectangle($t1,$s1,$t0,$s2,0xffffff) # B
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
		add $t3, $s2, $s1# find relative y start value for D
		add $t3, $s2, $t3
		sub $t3, $t3, $t0
		bm_drawRectangle($s0,$t3,$s2,$t0,0xffffff) # D
		
		bm_drawRectangle($s0,$t2,$t0,$s2,0xffffff) # E
		bm_drawRectangle($s0,$s1,$t0,$s2,0xffffff) # F
		bm_drawRectangle($s0,$t2,$s2,$t0,0xffffff) # G
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackload(24, $t3)
	stackpop(28)
	freturn
	
bm_drawDigit9:
#############
# This function prints out 9 on the bitmap display 
# vars:
# $a0 - x
# $a1 - y
# $a2 - size
#############
	fstart
	stackgrow(24)
	stackstore(0, $t0)
	stackstore(4, $t1)
	stackstore(8, $t2)
	stackstore(12, $s0)
	stackstore(16, $s1)
	stackstore(20, $s2)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	
		
		srl $t0, $s2, 2 #divide by 4 
		
		bm_drawRectangle($s0,$s1,$s2,$t0,0xffffff) # A
		
		add $t1, $s2, $s0 # find x value fror right hand lines
		sub $t1, $t1, $t0
		bm_drawRectangle($t1,$s1,$t0,$s2,0xffffff) # B
		
		add $t2, $s1, $s2 # find y value for C and E
		bm_drawRectangle($t1,$t2,$t0,$s2,0xffffff) # C
		
		
		bm_drawRectangle($s0,$s1,$t0,$s2,0xffffff) # F
		bm_drawRectangle($s0,$t2,$s2,$t0,0xffffff) # G
		
	stackload(0, $t0)
	stackload(4, $t1)
	stackload(8, $t2)
	stackload(12, $s0)
	stackload(16, $s1)
	stackload(20, $s2)
	stackpop(24)
	freturn
