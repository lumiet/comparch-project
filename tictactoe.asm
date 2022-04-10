.data
win3s: .word 73, 7, 273, 146, 56, 448, 84, 292 #winning3s (147(73),123(7),159(273),258(146),456(56),789(448),357(84),369(292))
positionkey: .word 1, 2, 4, 8, 16, 32, 64, 128, 256 #array for integer to board key array, i. e. positionkey[1] = 000000001, positionkey[4] = 000001000
# corresponds integer to board position
# key: 7 8 9
#      4 5 6
#      1 2 3
position: .word 511, 0, 0	#base address for array position, position[1] = unmarked,  position[2] = x's, position[3] = o's



.text


	#andCount test
	li $a0, 420
	li $a1, 235
	jal andCount 
	
	
	j Exit

andCount: # takes bit string (of length 9) in a0 and a1, returns number of 1s they have in common
	subu $sp, $sp, 32 #allocate stack
	sw $ra, 20($sp) #save return address
	sw $fp, 16($sp) #save frame pointer
	addiu $fp, $sp, 28
	
	and $t1, $a0, $a1 # set $t1 to the result of and ( a0, a1 )
	li $v0, 0 #initialize final count
	
	li $t0, 1 #set starting index (i) at 1 
andCLoop:
	and $t2, $t1, 1 # check if last digit is 1
	bne $t2, 1, countSkip # if last digit is 1, increment final count (v0)
	addi $v0, $v0, 1 # increment v0
countSkip:
	srl $t1, $t1, 1 # shift result right by 1
	beq $t0, 9, andCExit # if t0 = 9 ( 9 loops ), exit
	addi $t0, $t0, 1 #increment t0
	j andCLoop # restart loop
andCExit:
	lw $ra, 20($sp) # restore return address
	lw $fp, 16($sp) # restore frame pointer
	addiu $sp, $sp, 32 # pop stack
	jr $ra # $v0 has result of count


Exit: