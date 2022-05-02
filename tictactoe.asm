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
xVict: .asciiz "X wins!"
oVict: .asciiz "O wins!"
tieMessage: .asciiz "It's a tie...."
oChar: .asciiz "O"
xChar: .asciiz "X"
blankChar: .asciiz "_"
spaceChar: .asciiz " "
dividerChar: .asciiz "|"
AIMovePref: .word 16, 64, 256, 1, 4, 128, 8, 32, 2 # (5 &gt; 7 &gt; 9 &gt; 1 &gt; 3 &gt; 8 &gt; 4 &gt; 6 &gt; 2) (center &gt; corners &gt; sides)
errorMessage: .asciiz "Invalid move, try again."

.text
	#load position address
	la $s7, position
	
	#load winning 3s address
	la $s6, win3s
	
	#load AI move preference
	la $s5, AIMovePref
	
gameLoop:
	# -- display position --
	li $t3, 0 #loop index
	displayLoop:
		lw $t0, ($s7) #unmarked
		srlv $t0,$t0,$t3 #shift left by # of loop counter
		andi $t1, $t0, 1 #binary and unmarked with one
		beq $t1, 1, printBlank #if result = 1, print blank
		beqz $t1, printChar #if result = 0, check X/O's
		printChar:
			lw $t0, 4($s7) #load X's
			sllv $t0,$t0,$t3 #shift left by # of loop counter
			andi $t1, $t0, 1 #binary and X's with one
			beq $t1, 1, printX #if result = 1, print X char
			beqz $t1, printO #if not X and not unmarked, print O
				printX:
					li $v0, 4 #print string
					la $a0, xChar #print X
					syscall
					la $a0, spaceChar #print space
					syscall
					addi $t3, $t3, 1 #increment loop counter
					div $t4, $t3, 3
					mfhi $t5 #if $t5=0, then i%3 = 0
					beq $t5, 0, printNewline #if i%3 = 0, print newline
					bgtz $t5, printDivider #else print divider
					
				printO:
					li $v0, 4 #print string
					la $a0, oChar #print O
					syscall
					la $a0, spaceChar #print space
					syscall
					addi $t3, $t3, 1 #increment loop counter
					div $t4, $t3, 3
					mfhi $t5 #if $t5=0, then i%3 = 0
					beq $t5, 0, printNewline #if i%3 = 0, print newline
					bgtz $t5, printDivider #else print divider
		printBlank:			
			li $v0, 4 #print string
			la $a0, blankChar #print _
			syscall
			la $a0, spaceChar #print space
			syscall
			addi $t3, $t3, 1 #increment loop counter
			div $t4, $t3, 3
			mfhi $t5 #if $t5=0, then i%3 = 0
			beq $t5, 0, printNewline #if i%3 = 0, print newline
			bgtz $t5, printDivider #else print divider
			
		printNewline:
			li $v0, 4 #print string
			la $a0, newLine #print \n
			syscall
			blt $t3, 9, displayLoop
			bge $t3, 9, exitDisplay
			
		printDivider:
			li $v0, 4 #print string
			la $a0, dividerChar #print |
			syscall
			la $a0, spaceChar #print space
			syscall
			blt $t3, 9, displayLoop
			bge $t3, 9, exitDisplay
		
	
	exitDisplay:
	
	
	#li $v0, 1 #print integer
	#lw $a0, ($s7) #print unmarked
	#syscall
	#li $v0, 4 # print string
	#la $a0, newLine #load new line
	#syscall
	#li $v0, 1
	#lw $a0, 4($s7) #print print x's
	#syscall
	#li $v0, 4 # print string
	#la $a0, newLine #load new line
	#syscall
	#li $v0, 1
	#lw $a0, 8($s7) #print o's
	#syscall

	# -- player move --
	
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
	lw $t7, ($s7) # ($s7) is position[0], which is the unmarked bit string
	and $t1, $s0, $t7 # binary and unmarked and desired move, store result in $t1
	beq $t1, 0, invalidChoice # !restarts loop if desired move is unavailable, maybe add message to check if valid/seperate error handling

	#play move
	sub $t7, $t7, $s0 # subtract desired move from unmarked
	sw $t7, ($s7) # store changed unmarked position
	lw $t0, 4($s7) # load x/player position
	add $t0, $t0, $s0 # add desired move to player position
	sw $t0, 4($s7) # store player position
	
	# -- computer move --
	
	#checks if computer is 1 move away from winning
	
	lw $a0, 8($s7) # load computer position into a0
	li $s0, 0 # set starting index to 0 (iterating through win3s)
mateCheckLoop: 
	sll $t1, $s0, 2 # index * 4
	add $t2, $s6, $t1 # win3s[index] = win3s + (index * 4)
	lw $a1, ($t2) # load winning 3 in $a1
	
	#find moves that win
	jal andCount # andCount(win3s[index], computer position) = $v0
	bne $v0, 2, mateSkip # if result = 2, check if final move is playable
	
	#check if move is playable
	lw $t7, ($s7) # load unmarked position into t7
	and $t3, $a0, $a1 # binary and win3s[index] and computer position
	sub $t3, $a1, $t3 # t3 = missing move for computer to win
	and $t4, $t3, $t7 # t4 = binary and of desired move and unmarked position
	bne $t4, $t3, mateSkip # if desired move is not part of unmarked position, move is unavailable
	
	#play move
	sub $t7, $t7, $t3 # subtract desired move from unmarked
	sw $t7, ($s7) # store changed unmarked position
	lw $t6, 8($s7) # load computer position
	add $t6, $t6, $t3 # add desired move to computer position
	sw $t6, 8($s7) # store computer position
	j compMoveExit # now that move is made, exit
	
mateSkip:

	addi $s0, $s0, 1 # increment $s0/index
	bne $s0, 8, mateCheckLoop # if index = 8, every winning 3 has been checked. otherwise, restart loop with new index
	
	# checks if player is 1 move away from winning
	
	lw $a0, 4($s7) # load player position into a0
	li $s0, 0 # set starting index to 0 (iterating through win3s)
loseCheckLoop: 
	sll $t1, $s0, 2 # index * 4
	add $t2, $s6, $t1 # win3s[index] = win3s + (index * 4)
	lw $a1, ($t2) # load winning 3 in $a1
	
	#find moves that win
	jal andCount # andCount(win3s[index], player position) = $v0
	bne $v0, 2, loseSkip # if result = 2, check if final move is playable
	
	#check if move is 
	lw $t7, ($s7) # load unmarked position into t7
	and $t3, $a0, $a1 # binary and win3s[index] and player position
	sub $t3, $a1, $t3 # t3 = missing move for player to win
	and $t4, $t3, $t7 # t4 = binary and of desired move and unmarked position
	bne $t4, $t3, loseSkip # if desired move is not part of unmarked position, move is unavailable
	
	#play move
	sub $t7, $t7, $t3 # subtract desired move from unmarked
	sw $t7, ($s7) # store changed unmarked position
	lw $t6, 8($s7) # load computer position
	add $t6, $t6, $t3 # add desired move to computer position
	sw $t6, 8($s7) # store computer position
	j compMoveExit # now that move is made, exit
	
loseSkip:

	addi $s0, $s0, 1 # increment $t0/index
	bne $s0, 8, loseCheckLoop # if index = 8, every winning 3 has been checked. otherwise, restart loop with new index
	
	# if no move is found, use simple move prio
	
	li $s0, 0 #set starting index to 0 (iterating through AIMovePref
simpleMovePref:
	sll $t1, $s0, 2 # index * 4
	add $t2, $s5, $t1 # AIMovePref[index] = AIMovePref + (index * 4)
	lw $s1, ($t2) # load desired move in $s1
	
	#check if position is filled
	lw $t7, ($s7) # ($s7) is position[0], which is the unmarked bit string
	and $t1, $s1, $t7 # binary and unmarked and desired move, store result in $t1
	beq $t1, 0, simpleSkip

	#play move
	sub $t7, $t7, $s1 # subtract desired move from unmarked
	sw $t7, ($s7) # store changed unmarked position
	lw $t0, 8($s7) # load computer position
	add $t0, $t0, $s1 # add desired move to computer position
	sw $t0, 8($s7) # store computer position
	j compMoveExit # now that move is made, exit
	
simpleSkip:
	addi $s0, $s0, 1 #increment index
	bne $s0, 9, simpleMovePref #if index = 9, all moves have been iterated through, so no need to make any move
	
compMoveExit:

	
	# -- check if won --
	
	li $s0, 0 # set starting index to 0 (iterating through win3s)
winCheckLoop:
	sll $t1, $s0, 2 # index * 4
	add $t2, $s6, $t1 # win3s[index] = win3s + (index * 4)
	lw $t3, ($t2) # load winning 3 in $t3
	
	lw $t4, 4($s7) # load player/x position
	and $t5, $t3, $t4 # binary and player position with winning 3
	beq $t5, $t3, xWin # if result of and is the same as winning 3, player has won
	
	lw $t4, 8($s7) # load computer/o position
	and $t5, $t3, $t4 # binary and computer position with winning 3
	beq $t5, $t3, oWin # if result of and is the same as winning 3, computer has won
	
	addi $s0, $s0, 1 # increment $t0/index
	bne $s0, 8, winCheckLoop # if index = 8, every winning 3 has been checked and can move on
	
	# -- check if tied --
	
	lw $t0, ($s7) # load unmarked position
	beq $t0, 0, tie # if unmarked = 0, print tie message
	j gameLoop # otherwise, restart loop
	
xWin: 
	#display final position ! temporary !
	
	li $v0, 1 #print integer
	lw $a0, ($s7) #print unmarked
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
	
	li $v0, 4 #print string
	la $a0, xVict # load x victory message
	syscall
	j Exit #exit program
	
oWin: 
	#display final position ! temporary !
	
	li $v0, 1 #print integer
	lw $a0, ($s7) #print unmarked
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
	
	li $v0, 4 #print string
	la $a0, oVict # load o victory message
	syscall
	j Exit #exit program
	
tie:
	#display final position ! temporary !
	
	li $v0, 1 #print integer
	lw $a0, ($s7) #print unmarked
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
	
	li $v0, 4 #print string
	la $a0, tieMessage # load tie message
	syscall
	j Exit #exit program
	
invalidChoice:
	#li $v0, 4
	#la $a0, errorMessage
	#syscall
	j gameLoop


	
# Procedure section
# ! Below code should only ever be accessed through procedure calls !

#andCount procedure
andCount: # takes bit string (of length 9) in a0 and a1, returns number of 1s they have in common in $v0
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
