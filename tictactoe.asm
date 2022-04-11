.data
win3s: .word 73, 7, 273, 146, 56, 448, 84, 292 #winning3s (147(73),123(7),159(273),258(146),456(56),789(448),357(84),369(292))
positionKey: .word 1, 2, 4, 8, 16, 32, 64, 128, 256 #array for integer to board key array, i. e. positionkey[0] = 000000001, positionkey[3] = 000001000
# corresponds integer to board position (int n = board position bit string 2^(n-1))
# key: 7 8 9
#      4 5 6
#      1 2 3
position: .word 511, 0, 0	#base address for array position, position[0] = unmarked,  position[1] = x's, position[2] = o's
							#board starts fully unmarked
playerPrompt: .asciiz "Player move: "
newLine: .asciiz "\n"
AIMovePref: .word 16, 64, 256, 1, 4, 128, 8, 32, 2 # (5 > 7 > 9 > 1 > 3 > 8 > 4 > 6 > 2) (center > corners > sides)


.text

	#load position address
	la $s7, position
	
gameLoop:
	#display position
	li $v0, 1 #print integer
	lw $a0, 0($s7) #print unmarked
	syscall
	li $v0, 4 # print string
	la $a0, newLine #load new line
	syscall
	li $v0, 1
	lw $a0, 4($s7) #print print x's
	syscall
	li $v0, 4 # print string
	la $a0, newLine #load new line
	syscall
	li $v0, 1
	lw $a0, 8($s7) #print o's
	syscall

	#player move
	li $v0, 4 # print string
	la $a0, playerPrompt #load player prompt
	syscall

	li $v0, 5 # read integer, will make move for player
	syscall

	# convert number to position
	li $s0, 1 # load 1 into s0
	subi $v0, $v0, 1
	sllv $s0, $s0, $v0 # convert input number into board position, 2^(n - 1)

	#check if position is filled
	lw $t0, 0($s7) # 4($s7) is position[1], which is the unmarked bit string
	and $t1, $s0, $t0 # binary and unmarked and desired move, store result in $t1
	beq $t1, 0, gameLoop # !restarts loop if desired move is unavailable, maybe add message to check if valid/seperate error handling

	#play move
	sub $t0, $t0, $s0 # subtract desired move from unmarked
	sw $t0, 0($s7) # store changed unmarked position
	lw $t0, 4($s7) # load x/player position
	add $t0, $t0, $s0 # add desired move to player position
	sw $t0, 4($s7) # store player position
	
	#computer move
	
	
	j gameLoop #temp end of gameloop
	
	
	j Exit #exit

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
