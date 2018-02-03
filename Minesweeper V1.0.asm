##############################################################
# Author Haiqi Wu

##############################################################
.text

.macro push (%reg) #into sp.
	addi $sp, $sp, -4
	sw %reg, 0($sp)
.end_macro


#this macro overides: $t2~$t4
.macro getData (%row, %col) #(reg. %row  , reg col )
	move $t2, $s0 #base addr. of cell array
	li $t3, 10
	mul $t3, %row, $t3 # i*10 = t3
	add $t3, $t3, %col # +j
	add $t3, $t3, $s0 #+addr => t3 => addr. of this.row and col. in incell_array_
	
	lb $t4, ($t3) #8 bit data
	#this sets $t4 to the 8 bit data.
.end_macro

.macro setBackBG
	
	li $t0, 10
	mul $t0, $s2, $t0
	add $t0, $t0, $s3
	add $t0, $t0, $s0# +base
	lb $t0, ($t0) #now t0 contains the info 8bits
	##1. is that reavealed?
	srl $t0, $t0, 6 #....1 /....0
	andi $t0, $t0, 1 #00001/ 00000
	beq $t0, 0, fillGrey #gray (not reaveled case)
	#else it is revealed:
	#check is there a flag>?
	li $t0, 10
	mul $t0, $s2, $t0
	add $t0, $t0, $s3
	add $t0, $t0, $s0 # +base
	lb $t0, ($t0) #info 8 bits
	srl $t0, $t0, 4 #....1 /,,...0
	andi $t0, $t0, 1
	beq $t0, 1, fillGrey
	#else: fill with black:
	#1. get current addr. for modifiey color
	
	li $t0, 0xffff0000 #base addr. ( changed )
	li $t1, 10
	mul $t1, $s2, $t1 #
	add $t1, $t1, $s3 #
	li $t3, 2
	mul $t1, $t1, $t3 #
	add $t0, $t0, $t1 #new_addr.   =>t0
	
	addi $t0, $t0, 1 #move to color info addr.   =>t0
	
	lb $t1, ($t0)
	sll $t1, $t1, 28
	srl $t1, $t1, 28 #....0000xxxx?
	
	#fill with black to bg
	li $t9, 0x0 #0000 0000
	or $t9, $t9, $t1
	
	sb $t9, ($t0) #store color info into t0
	
	#done with setting color
	#universial flag  s4
	beq $s4, 1, back_caseW
	beq $s4, 2, back_caseA
	beq $s4, 3, back_caseS
	beq $s4, 4, back_caseD
	
fillGrey: #gray
	#1. get current addr. for modifiey color
	
	li $t0, 0xffff0000 #base addr. ( changed )
	li $t1, 10
	mul $t1, $s2, $t1 #
	add $t1, $t1, $s3 #
	li $t3, 2
	mul $t1, $t1, $t3 #
	add $t0, $t0, $t1 #new_addr.   =>t0
	
	addi $t0, $t0, 1 #move to color info addr.   =>t0
	
	lb $t1, ($t0)
	sll $t1, $t1, 28
	srl $t1, $t1, 28 #....0000xxxx?
	
	#fill with grey to bg
	li $t9, 0x70 #0111 0000
	or $t9, $t9, $t1
	
	sb $t9, ($t0) #store color info into t0
	
	#done with setting color
	
.end_macro

.macro setInfo

	move $a2, $t0 #char
	move $a0, $s0    #row
    	move $a1, $s1   #col
    	move $a3, $t2   #fg
    	
    	addi $sp, $sp, -4
    	sw $t1, 0($sp)  #bg in stack
    	
    	jal set_cell
    	
    	addi $sp, $sp, 4 #release stack
.end_macro

.macro preserveT
addi $sp, $sp, -40 # 4*10  10spaces 
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $t4, 16($sp)
	sw $t5, 20($sp)
	sw $t6, 24($sp)
	sw $t7, 28($sp)
	sw $t8, 32($sp)
	sw $t9, 36($sp)
	
	jal setAdjBomb 
	
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	lw $t4, 16($sp)
	lw $t5, 20($sp)
	lw $t6, 24($sp)
	lw $t7, 28($sp)
	lw $t8, 32($sp)
	lw $t9, 36($sp)
	addi $sp, $sp, 40
.end_macro

##############################
# PART 1 FUNCTIONS
##############################

smiley:
	li $t3, 0xffff0000 #base addr. (not changing_)
	
	li $t0, 0xffff0000 #staring addr.  = > moving addr.
	li $t1, 0xffff00c8 #ending addr.+1
	li $t2, 0xf #back: 0000(black) fore:1111(white) #00001111= 0xf
	for:
		beq $t0, $t1  out_for_loop
		sb $0, ($t0) #set the char to null
		addi $t0, $t0, 1
		sb $t2, ($t0) #store the color info into moving addr.
		addi $t0, $t0, 1		
		j for

	out_for_loop:
	#part 1: (3,3 ) bomb
		addi $t0, $t3, 66 # (2 , 3) => base+66 in t0(char addr.)
		li $t1, 0xb7 #1011 0111 (yellow , gray) in t1
		li $t2, 'b'   #load t2 with 'b'  
		sb $t2, ($t0)
		addi $t0,$t0,1 # color addr
		sb  $t1, ($t0) #store color to t0
		
	#part2:	(2,3) bomb  //constants : [ t1: color t2:char 'b' t3:base addr ]
	addi $t0, $t3, 46
	
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)
	
	
	#part3: (2,6) bomb  26*2= 52
	
	addi $t0, $t3, 52
	
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)
	#part4: (3,6) bomb   36*2 = 72
	addi $t0, $t3, 72
	
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)
	#bomb done
		
	#start to fill the mouth :
	# 0 001 1 111 =>   in hex: 0x1F
	# background  Red (an),  foreground white
	
	#cons:  t3:base addr t1:color  t2:char 'e'
	li $t1, 0x1f
	li $t2, 'e'
	#1:
	addi $t0, $t3, 124  #base +   x  = t0 (char addr. tobe written in)
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)
	
	#2:	
	addi $t0, $t3, 146   #base +   x  = t0 (char addr. tobe written in)
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)
	#3:
	addi $t0, $t3, 168  #base +   x  = t0 (char addr. tobe written in)
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)
	#4:
	addi $t0, $t3, 170  #base +   x  = t0 (char addr. tobe written in)
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)
	#5:
	addi $t0, $t3, 152  #base +   x  = t0 (char addr. tobe written in)
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)
	#6:
	addi $t0, $t3, 134  #base +   x  = t0 (char addr. tobe written in)
	sb $t2, ($t0)
	addi $t0, $t0, 1
	sb $t1, ($t0)	
	
	jr $ra
	
##############################
# PART 2 FUNCTIONS
##############################

open_file:
	
	#$a0 = filename's addr.
	
	li $v0, 13
	li $a1, 0
	li $a2, 0
	syscall
	
    ############################################
    # DELETE THIS CODE. Only here to allow main program to run without fully implementing the function
    #li $v0, -200
    ###########################################
    jr $ra

close_file:

	li $v0, 16
	syscall

    #Define your code here
    ############################################
    # DELETE THIS CODE. Only here to allow main program to run without fully implementing the function
    #li $v0, -200
    ###########################################
    jr $ra
	
load_map:

	addi $sp, $sp, -28 # 4*  7spaces 
	
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	sw $ra, 12($sp) #line 166
	
	sw $s3, 16($sp)
	sw $s6, 20($sp)
	sw $s7, 24($sp)
	
	#exlude : s4 s5 
	####

	#a0 is id, a1 is cell_array's addr.
	#a1 is The "cells array"'s addr.
	
	#step1: setting all of the cells in cell_array to 0(inicilize cell array)
	
	move $t0, $a1 #moving addr.
	li $t7, 0x0 #cons
	
	li $t2, 0 #counter
	
	loop_inicilize:
		bgt $t2, 99, doneWithIni #will run from 0~ 99 (100 times)
		
		sb $t7, ($t0) #store 0000 0000 to curr cell
		
		addi $t0, $t0 ,1 #increment the moving addr.
		addi $t2, $t2, 1 #inc       counter
		j loop_inicilize
	
	doneWithIni: 
	
	move $t9, $a1 #t9 now is the cell array's addr
	li $t8, 0 #counter
	
	la $a1, buffer #a1 should be loaded with addr of buffer. 
	 			#a1 should not (do not need) be changed(or add 1) while processing
	 			# the whole file reading.
	li $a2, 1  # 1char read at a time 
	#!!!  a0 is user passed in	
	
	li $v0, 14
	syscall #first call(reading in first char)
	
	#flags:
	li $s0, 0 #general           flag(dealing leading 0's)
	li $s7, 0 #out_while         flag
	li $s6, 1 #space ----------  flag
	li $t7, 0 #num/spce          flag
	li $t6, 0 #row/col indicator-flag
	
while:
	bltz $v0, invalid_char #sharing label 
	
	beq $s7, 1, out_while 
	
	beq $v0, $0, eof #set s7 to 1 , set eof as a space, and cont the last interation's process
	
	lb $t0, ($a1) #load cursor byte to $t0
	#now t0 will contain each byte in the file
	
	cont1: #came back from eof
	
	beq $s6, 1, deal_space_case #also deal with the case that the file starting with a space.
	
	cont3: 
	li $s6, 0 #set back s6 flag
	
	#it is the first spce that we have met or it is anything other than spce
	
	beq $s0, 1, generalFlag1 #it should must be a spce
	
	goProcess:
	
	#beq $t0, 32, goProcess #cases of (000000\s)
	#beq $t0, 13, goProcess #
	#beq $t0, 10, goProcess
	#beq $t0, 9,  goProcess
	li $s0, 0 #inicilize the general flag
	
	#step2: check if it  is a valid char
		beq $t0, 32, validChar
		beq $t0, 10, validChar
		beq $t0, 9, validChar
		beq $t0, 13, validChar
		
		bge $t0, 48, gteChar0
		
		#else
		j invalid_char
	
	validChar:
	
	#now it woule be any 0-9 or any spces.
	#now the flag t7 has been set:  0 => spce  1=> num.
	
	beq $t7, 1, numCase
	#else: it is a space.
	#process the one in s1.(prev.)
	#deal spce:
	beq $t6, 1, nextI#we have just save the row, but no col value yet
	#else: t6==0
	# collect cordinates & save bomb :
		li $t3, 0x20 #0010 0000  
		li $t4, 10
		#(i,j) == (t1, s1) with chars
		 	li $t2, 48 #'0'
	     		sub $t1, $t1, $t2
	     		sub $s1, $s1, $t2
		#(i,j) == (t1, s1) with nums now
			mul $t4, $t4, $t1  #t4= 10*i
	     		add $t4, $t4, $s1 #t4 = t4 + j
			
			add $t4, $t9, $t4 #t4 = baseAddr. +t4
			#now t4 is the addr. of  bomb pos. in cellArray
			sb $t3, ($t4) #put the bomb in ()
			
			####TEST#####Printing test #this used s2 s3
			
			#move $s2, $v0#rc
			#move $s3, $a0#rc
			
		#	move $a0, $t1
		#	li $v0, 1
		#	syscall
			
		#	move $a0, $s1
		#	syscall
	
		#	move $v0, $s2
		#	move $a0, $s3
			#####TEST#######
			
	nextI:
	
	beq $t0, 32, setSFto1 #if what we are processing is any kind of spce then,
		#we set SF to 1, to skip next spce.
	beq $t0, 13, setSFto1
	beq $t0, 10, setSFto1
	beq $t0, 9, setSFto1
	
	nextIter:
	#move $s1, $t0 
	
	beq $s7, 1, while #if this is the last iteration... j to while and it will be out of while
	
	li $v0, 14   # read next byte
	syscall      # ##############
	
	cont2:
	j while
	
deal_space_case:
	beq $t0, 32, nextIter
	beq $t0, 13, nextIter
	beq $t0, 10, nextIter
	beq $t0, 9, nextIter
	j cont3

eof:
	li $s7, 1
	li $t0, 32 #set eof as a space char
	j cont1
	
setSFto1:
	li $s6, 1
	j nextIter
	
out_while: 
	
	li $t2, 2
	div $t8, $t2 #counter /2 
	mfhi $t2 #remainder of c/2  => t2
	
	bnez $t2, invalid_char # odd number of input #s#if odd# of int => invalid 
	beqz $t8, invalid_char# else if counter is 0, => invalid
	#else valid: and set adj:
#####################################################	
	#used: $t9 : cell_array_addr
	li $t3, 0 #the number + to addr.
	#move $t0, $t9 #moving addr.
	
	li $t0, -10
	li $t1, 10
	li $t2, -1
	li $t5, 1
	li $t6, -11
	li $t7, -9
	li $t8, 11
	li $s0, 9
	
	#li $s1, 0
	
	loop_set_num:
	beq $t3, 100, out_loop_set_num
	 
	add $t4, $t3, $t9
	#t4 has the addr. of current now.
	beq $t3, 0, cornerA
	beq $t3, 9, cornerB
	beq $t3, 90, cornerC
	beq $t3, 99, cornerD
	#next case: 0x x0 x9 9x (case of line)
	addi $s1, $t3, -10
	blt $s1, 0, line0x
	
	li $s1, 10
	div $t3, $s1
	mfhi $s1
	beqz $s1, linex0
	
	li $s2, 10
	addi $s1, $t3, 1
	div $s1, $s2
	mfhi $s2
	beqz $s2, linex9
	
	bgt $t3, 90, line9x
	
	#last case (regular case)
	
	move $a0, $t4
	
	add $s1, $t4, $t0
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t1
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t2
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t5
	move $a1, $s1
	preserveT
	
	
	add $s1, $t4, $t6
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t7
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t8
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $s0
	move $a1, $s1
	preserveT
	
	backA:
	addi $t3, $t3 , 1 #increse t3
	
	j loop_set_num
	
	cornerA: #R B BR  { $t5 $t1 $t8 }
	#	li $s1, 0 #inicilize counter
		add $s1, $t5, $t4 
		add $s2, $t1, $t4
		add $s3, $t8, $t4
		
		move $a0, $t4
		
		move $a1, $s1 #setAdjBomb($t4, $s1)
		preserveT
		
		move $a1, $s2
		preserveT 	#setAdjBomb($t4, $s2)
		
		move $a1, $s3
		preserveT   #setAdjBomb($t4, $s3)
		j backA
	cornerB: #t2, t1, s0
		add $s1, $t4, $t2
		add $s2, $t4, $t1
		add $s3, $t4, $s0
		
		move $a0, $t4
		
		move $a1, $s1 
		preserveT
		
		move $a1, $s2
		preserveT 	
		
		move $a1, $s3
		preserveT  
		j backA
	cornerC: #t0, t5, t7
		add $s1, $t0, $t4
		add $s2, $t4, $t5
		add $s3, $t4, $t7
		
		move $a0, $t4
		
		move $a1, $s1 
		preserveT
		
		move $a1, $s2
		preserveT 	
		
		move $a1, $s3
		preserveT  
		j backA
	cornerD: #t2, t0, t6
		add $s1, $t2, $t4
		add $s2, $t0, $t4
		add $s3, $t4, $t6
		
		move $a0, $t4
		
		move $a1, $s1 
		preserveT
		
		move $a1, $s2
		preserveT 	
		
		move $a1, $s3
		preserveT  
		j backA
		
		
	line0x: #exlude : t0, t6, t7
	move $a0, $t4
	
	#add $s1, $t4, $t0
	#move $a1, $s1
	#jal setAdjBomb
	
	add $s1, $t4, $t1
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t2
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t5
	move $a1, $s1
	preserveT
	
	
	#add $s1, $t4, $t6
	#move $a1, $s1
	#preserveT
	
	#add $s1, $t4, $t7
	#move $a1, $s1
	#preserveT
	
	add $s1, $t4, $t8
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $s0
	move $a1, $s1
	preserveT
	
		j backA
	linex0: #ex: t6, t2, s0
		
	move $a0, $t4
	
	add $s1, $t4, $t0
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t1
	move $a1, $s1
	preserveT
	
	#add $s1, $t4, $t2
	#move $a1, $s1
	#preserveT
	
	add $s1, $t4, $t5
	move $a1, $s1
	preserveT
	
	#add $s1, $t4, $t6
	#move $a1, $s1
	#preserveT
	
	add $s1, $t4, $t7
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t8
	move $a1, $s1
	preserveT
	
	#add $s1, $t4, $s0
	#move $a1, $s1
	#preserveT
		j backA
	linex9: #exlude : t5, t7, t8
	
	move $a0, $t4
	
	add $s1, $t4, $t0
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t1
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t2
	move $a1, $s1
	preserveT
	
	#add $s1, $t4, $t5
	#move $a1, $s1
	#preserveT
	
	
	add $s1, $t4, $t6
	move $a1, $s1
	preserveT
	
	#add $s1, $t4, $t7
	#move $a1, $s1
	#preserveT
	
	#add $s1, $t4, $t8
	#move $a1, $s1
	#preserveT
	
	add $s1, $t4, $s0
	move $a1, $s1
	preserveT
	
	
		j backA
	line9x:#exlude: t1, s0, t8
	
	move $a0, $t4
	
	add $s1, $t4, $t0
	move $a1, $s1
	preserveT
	
	#add $s1, $t4, $t1
	#move $a1, $s1
	#preserveT
	
	add $s1, $t4, $t2
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t5
	move $a1, $s1
	preserveT
	
	
	add $s1, $t4, $t6
	move $a1, $s1
	preserveT
	
	add $s1, $t4, $t7
	move $a1, $s1
	preserveT
	
	#add $s1, $t4, $t8
	#move $a1, $s1
	#preserveT
	
	#add $s1, $t4, $s0
	#move $a1, $s1
	#preserveT
	
		j backA
	
	out_loop_set_num:
	
	#cursor_row   .word  -1
	#cursor_col  .word   -1
	li $t0, 0
	sw $t0, cursor_row
	sw $t0, cursor_col
	
	
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	
	lw $ra, 12($sp)
	
	lw $s3, 16($sp)
	lw $s6, 20($sp)
	lw $s7, 24($sp)
	addi $sp, $sp, 28 # 4*  7spaces 
	
	li $v0, 0  #return 0 as success. done everyTHING in p2
	jr $ra 
	
invalid_char:#return -1
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	
	lw $ra, 12($sp)
	
	lw $s3, 16($sp)
	lw $s6, 20($sp)
	lw $s7, 24($sp)
	addi $sp, $sp, 28 # 4*  7spaces 
	
	li $v0, -1
	jr $ra
	
generalFlag1:
	beq $t0, 32, goProcess
	beq $t0, 13, goProcess
	beq $t0, 10, goProcess
	beq $t0, 9,  goProcess
	j invalid_char
	
gteChar0:
		ble $t0, 57, validCharB
		j invalid_char
validCharB:
		li $t7, 1 #num/spce flag => it is a num
		j validChar
numCase:
	bne $t0, 48, setGenFlagTo1
      pc0: 
      
	li $t7, 0 #inilize t7
	#deal num. here:
	beq $t6, 0, saveRow
	#else: if t6==1
	li $t6, 0
	move $s1, $t0 #save col to s1
	addi $t8, $t8, 1 #increment the counter 
	j nextIter

saveRow: 
	move $t1, $t0 # save row
	li $t6, 1  #set flag
	addi $t8, $t8, 1 #increment the counter 
	j nextIter

setGenFlagTo1:
	li $s0, 1 #set gen flag to 1
	j pc0

#Helper FUNCTION ######################################
setAdjBomb: # void setAdjBomb(a0, a1 )  {a0: currentAddr which may need to add 1
					#a1: the address that needed to be
					#looked at which is one of the surroundings}
	lb $t1, ($a1)
	
	srl $t1, $t1, 5
	
	addi $t0, $t1, 1
	
	sll $t0, $t0, 31
	srl $t0, $t0, 31
	beqz $t0, bombAround
	#else: there is no bomb around
	b001:
	jr $ra
	
	bombAround:
		lb $t2, ($a0)
		addi $t2, $t2, 1 #add 1 to it
		sb $t2, ($a0)
		j b001
		
##############################
# PART 3 FUNCTIONS
##############################

init_display:

	addi $sp, $sp, -36 #  9 spaces     
	
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	
	sw $ra, 32($sp)
	
	
	
	li $s0, 0 # i  = row
    
    for_1:
    	bgt $s0, 9, out_for_1
    	  li $s1, 0 # j  = col
    	  
    	  for_2: 
    	  bgt $s1, 9, out_for2
    	  #########
    	  
    	  li $s2, 0x7 #0000 0111   / color info
    	  #char: $0
    	  move $a2, $0 #char
    	  move $a0, $s0  #set row
    	  move $a1, $s1 #set col
    	  move $a3, $s2 #set fg
    	  
    	  addi $sp, $sp, -4  #pull stack
    	  sw $s2, 0($sp)
    	  
    	  jal set_cell
    	  
    	  addi $sp, $sp, 4 #release stack
    	  
    	  #########
    	  addi $s1, $s1, 1
    	  j for_2
    	  
    	  out_for2:
    	addi $s0, $s0, 1
    	j for_1
    out_for_1:
    lw $s3, cursor_row
    lw $s4, cursor_col
    
    #
    		#base_addr +  2*( i*10+j )
	li $s5, 0xffff0000 #base addr. ( changed )
	li $s6, 10
	mul $s6, $s6, $s3 #
	add $s6, $s6, $s4 #
	li $s7, 2
	mul $s6, $s6, $s7 #
	add $s5, $s5, $s6 #new_addr.   => s5
	
	addi $s5, $s5, 1 #move to color info addr.
	
	lb $s6, ($s5)
	sll $s6, $s6, 28
	srl $s6, $s6, 28
	
	
	li $s7, 0xb0 #1011 0000
	or $s7, $s7, $s6
	
	sb $s7, ($s5) #store color info into s5
	 
	#done
	
	
	  
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $s7, 28($sp)
	
	lw $ra, 32($sp)
	
	addi $sp, $sp, 36 #  9 spaces   
    	
    	jr $ra       

set_cell:

	lw $t0, 0($sp) # bg => $t0
			#$a0 =>row  a1=> col  a2=> char a3=> fg
	#step 0: check validation(check 4 args)
	#1.a0
	bltz $a0, invalid
	bge $a0, 10, invalid
	#2. a1
	bltz $a1, invalid
	bge $a1, 10, invalid
	#3.a3
	bltz $a3, invalid
	bgt $a3, 15, invalid
	#4.t0
	bltz $t0, invalid
	bgt $t0, 15, invalid
	
	#else: all valid:
			
	#1. find the addr. (to save)
		#base_addr +  2*( i*10+j )
	li $t3, 0xffff0000 #base addr. ( changed )
	li $t4, 10
	mul $t4, $t4, $a0 #10*i = t4
	add $t4, $t4, $a1 #j+10*i  =t4
	li $t5, 2
	mul $t4, $t4, $t5 #2* (j+10*i ) = t4
	add $t3, $t3, $t4 #base+ t4 = new_addr.   => t3
	
	sb $a2, ($t3) #store the char in
	
	addi $t3, $t3, 1 #move to color info addr.
	
		sll $t0, $t0, 4
		or $t0, $t0, $a3
		
		sb $t0, ($t3) #store color info into t3 
	#done
	
	li $v0, 0 #for valid info provided and success
        jr $ra 
        
 	invalid:
		li $v0, -1
		jr $ra        

	
reveal_map:
	##reg. conv.
	
	addi $sp, $sp, -24 #  6 spaces     
	
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)

	sw $ra, 20($sp)



    move $s3, $a1  #addr. of cell_array(not changing)

    beqz $a0, done_rm
    beq $a0, 1, reveal_win
    #else: lost the game:
    
    	li $s4, 0 #
    	
	li $s0, 0 # i  = row
    
    for_1a:
    	bgt $s0, 9, out_for_1a
    	  li $s1, 0 # j  = col
    	  
    	  for_2a: 
    	  bgt $s1, 9, out_for2a
    	  #########
    	  add $s2, $s4, $s3 #s2 will have the addr. of cell_array(moving addr.)
    	  lb $s2, ($s2) #first byte => s2
    	  # then, info (cell_array) will be in s2
    	  #0.check cursor case
    	  lw $t0, cursor_row #i
    	  lw $t1, cursor_col #j
    	  
    	  beq $t0, $s0, checkJ
    	  backcj:
    	  #1. check flag case:
    	  move $t0, $s2
    	  srl $t0, $t0, 4
    	  #......0  / ,,,,,1
    	  andi $t0, $t0, 1
    	  beq $t0, 1, flagCase  # it is  ......1
    	  
    	  #2. check bomb?
    	  move $t0, $s2
    	  srl $t0, $t0, 5
    	  #....0  / .....1
    	  andi $t0, $t0, 1
    	  beq $t0, 1, bombCase #it is ...1 
    	  
    	  #last case: #number case
    	  move $t0, $s2
    	  sll $t0, $t0, 28
    	  srl $t0, $t0, 28
    	  #it becomes a number now
    	  beq $t0, $0, zeroNumCase
    	  #else: it is a number (1-8) (non Zero) (not ascii)
    	  # number is in $t0
    	  li $t1, '0'
    	  add $t0, $t0, $t1
    	  # number is in ascii now
    	  move $t1, $0
    	  li $t2, 0xd
    	  #t0 t1 t2 set
    	  setInfo
    	  #set finished
    	  
    	  
    	  nextIteration:
    	  addi $s4, $s4, 1
    	  #########
    	  addi $s1, $s1, 1
    	  j for_2a
    	  
    	  out_for2a:
    	addi $s0, $s0, 1
    	j for_1a
  out_for_1a:
  j done_rm
    
    
reveal_win:
	jal smiley 
   	j done_rm
done_rm:
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)

	lw $ra, 20($sp)
	
	addi $sp, $sp, 24 #  6 spaces    

        jr $ra

checkJ:
	beq $s1, $t1, caseCursor
	j backcj
	
	
#cases:
caseCursor: #exploded bomb
	
	li $t0, 'e'
	li $t1, 0x9 #bg
	li $t2, 0xf #fg
	#set start
	setInfo
    	#set finished
	j nextIteration

flagCase:
	#check to see   is there a bomb?
	move $t0, $s2
	srl $t0, $t0, 5
	#......1 /.....0 indicating if there is a bomb
	andi $t0, $t0, 1
	beq $t0, 1, correctFlag 		#it is .....1
	
	li $t0, 'f'
	li $t1, 0x9
	li $t2, 0xc
	#set start
	setInfo
	#set finished
	j nextIteration
	 
	  
	   
correctFlag:#1
	li $t0, 'f'
	li $t1, 0xa
	li $t2, 0xc
	#set start
	setInfo
	#set finished
	j nextIteration
	           
bombCase:
	li $t0, 'b'
	move $t1, $0
	li $t2, 0x7
	setInfo
	j nextIteration

zeroNumCase:
	move $t0, $0
	move $t1, $0
	li $t2, 0xf
	setInfo
	j nextIteration

##############################
# PART 4 FUNCTIONS
##############################

perform_action:
	addi $sp, $sp, -36 
	sw $ra, 0($sp)

	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	
    #a0=> array,  a1 => char action
    li $s4, -1 #universial flag
    li $s5, 0xffff0000 #base addr. ( not changing)
    
    move $s0, $a0
    move $s1, $a1
    lw $s2, cursor_row
    lw $s3, cursor_col
    beq $s1, 'w', caseW
    beq $s1, 'W', caseW
    beq $s1, 'a', caseA
    beq $s1, 'A', caseA
    beq $s1, 's', caseS
    beq $s1, 'S', caseS
    beq $s1, 'd', caseD
    beq $s1, 'D', caseD
    
    beq $s1, 'f', caseF
    beq $s1, 'F', caseF
    
    beq $s1, 'r', caseR
    beq $s1, 'R', caseR
    
	
    finished:
	lw $ra, 0($sp)

	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	
	addi $sp, $sp, 36 
	
    li $v0, 0 #success
    jr $ra
    
    notValid:
    
    	lw $ra, 0($sp)

	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	
	addi $sp, $sp, 36 
	
    li $v0, -1
    jr $ra


caseW: # flag s4 set to => 1
	beq $s2, $0, notValid
	#1. re-fill back the current:
	li $s4, 1 #set flag
	setBackBG #macro call
	back_caseW: #done with setting back bg
	#2. move up by 1
	#row -1
	move $t0, $s2 #row
	addi $t0, $t0, -1 # new row=> t0
	#set the new row in memory (label data)
	sw $t0, cursor_row
	#next, find addr. to set bg color info:
	
	li $t1, 10
	mul $t1, $t1, $t0
	add $t1, $t1, $s3 #j+
	li $t2, 2
	mul $t2, $t2, $t1 
	add $t2, $t2, $s5 #new addr.
	
	addi $t2, $t2, 1 #move to color info addr. => t2
	
	lb $t1, ($t2) #color info in t1
	#set background to yellow
	
	sll $t1, $t1, 28
	srl $t1, $t1, 28
	
	li $t3, 0xb0 #1011 0000 #yellow
	or $t3, $t3, $t1
	
	sb $t3, ($t2) #store color info 
	#done
	
	j finished

caseA:#flag s4 =>2
	
	beq $s3, $0, notValid
	#1. re-fill back the current:
	li $s4, 2 #set flag
	
	setBackBG #macro call
	
	back_caseA: #done with setting back bg
	#2. move left by 1
	#col -1
	
	move $t0, $s3 #col
	addi $t0, $t0, -1 # new col=> t0
	#next, set the data(label)
	sw $t0, cursor_col
	
	#next, find addr. to set bg color info:
	
	li $t1, 10
	mul $t1, $t1, $s2 #
	add $t1, $t1, $t0 #j+
	li $t2, 2
	mul $t2, $t2, $t1 
	add $t2, $t2, $s5#new addr.
	
	addi $t2, $t2, 1 #move to color info addr. => t2
	
	lb $t1, ($t2) #color info in t1
	#set background to yellow
	
	sll $t1, $t1, 28
	srl $t1, $t1, 28
	
	li $t3, 0xb0 #1011 0000 #yellow
	or $t3, $t3, $t1
	
	sb $t3, ($t2) #store color info 
	#done
	
	j finished
caseS:
	#flag s4 =>3
	beq $s2, 9, notValid
	
	#1. re-fill back the current:
	li $s4, 3 #set flag
	
	setBackBG #macro call
	
	back_caseS: #done with setting back bg
	#2. move down by 1
	#row+1
	
	move $t0, $s2 #row
	addi $t0, $t0, 1 # new row=> t0
	#next, set the data(label)
	sw $t0, cursor_row
	
	#next, find addr. to set bg color info:
	
	li $t1, 10
	mul $t1, $t1, $t0 # 10*i
	add $t1, $t1, $s3 #j+
	li $t2, 2
	mul $t2, $t2, $t1 
	add $t2, $t2, $s5#new addr.
	
	addi $t2, $t2, 1 #move to color info addr. => t2
	
	lb $t1, ($t2) #color info in t1
	#set background to yellow
	
	sll $t1, $t1, 28
	srl $t1, $t1, 28
	
	li $t3, 0xb0 #1011 0000 #yellow
	or $t3, $t3, $t1
	
	sb $t3, ($t2) #store color info 
	
	j finished
caseD:
	#flag s4 =>4
	beq $s3, 9, notValid
	
	#1. re-fill back the current:
	li $s4, 4 #set flag
	
	setBackBG #macro call
	
	back_caseD: #done with setting back bg
	#2. move right by 1
	#col +1
	
	move $t0, $s3 #col
	addi $t0, $t0, 1 # new col=> t0
	#next, set the data(label)
	sw $t0, cursor_col
	
	#next, find addr. to set bg color info:
	
	li $t1, 10
	mul $t1, $t1, $s2 # 10*i
	add $t1, $t1, $t0 #j+
	li $t2, 2
	mul $t2, $t2, $t1
	add $t2, $t2, $s5#new addr.
	
	addi $t2, $t2, 1 #move to color info addr. => t2
	
	lb $t1, ($t2) #color info in t1
	#set background to yellow
	
	sll $t1, $t1, 28
	srl $t1, $t1, 28
	
	li $t3, 0xb0 #1011 0000 #yellow
	or $t3, $t3, $t1
	
	sb $t3, ($t2) #store color info 
	
	j finished
caseF:
	li $t0, 10
	mul $t0, $t0, $s2
	add $t0, $t0, $s3
	add $t0, $t0, $s0 #addr of cell array
	move $s7, $t0
	lb $s6, ($t0)  #cell array ' info 8bits 
	move $t0, $s6
	srl $t0, $t0, 6 #revealed? in right most digit
	andi $t0, $t0, 1
	beq $t0, 1, notValid
	move $t0, $s6
	srl $t0, $t0, 4 #flagged? in r m d
	andi $t0, $t0, 1
	beq $t0, 1, removeFlag
	#else , put a flag in:
	li $t0, 'f'
	li $t2, 0xc
	li $t1, 0xb #yellow bg.!!!!
	
	move $a2, $t0 #char
	move $a0, $s2    #row
    	move $a1, $s3   #col
    	move $a3, $t2   #fg
    	
    	addi $sp, $sp, -4
    	sw $t1, 0($sp)  #bg in stack
    	
    	jal set_cell
    	
    	addi $sp, $sp, 4 #release stack
    	#next, set data to be 1 as the pos. of flag
	move $t0, $s6 #data (cell arrays) 's content(8 bits)
	srl $t0, $t0, 4
	addi $t0, $t0, 1
	sll $t0, $t0, 4 #shift back  t0 now: xxxx0000
	
	move $t1, $s6
	sll $t1, $t1, 28
	srl $t1, $t1, 28
	
	or $t0, $t0, $t1
	#now it is the correct bits (new)
	#save it back to the addr.
	sb $t0, 0($s7)	
	
	flagRe:
	
	j finished
	
removeFlag:
	move $t0, $0
	li $t1, 0xb #bg yellow!
	li $t2, 0x7
	
	
	move $a2, $t0 #char
	move $a0, $s2    #row
    	move $a1, $s3   #col
    	move $a3, $t2   #fg
    	
    	addi $sp, $sp, -4
    	sw $t1, 0($sp)  #bg in stack
    	
    	jal set_cell
    	
    	addi $sp, $sp, 4 #release stack
    	#finished set the color and char..
    	#next, set the data array: (remove the flag )
	li $t0, 10
	mul $t0, $t0, $s2
	add $t0, $t0, $s3
	add $t0, $s0, $t0 #addr.
	move $s6, $t0
	lb  $t0, ($t0) # 8 bits~ in t0
	move $s7, $t0
	
	srl $t0, $t0, 5
	sll $t0, $t0, 5
	
	move $t1, $s7
	sll $t1, $t1, 28
	srl $t1, $t1, 28
	
	or $t1, $t1, $t0
	
	sb $t1, ($s6)	
	
	j flagRe

####################################
caseR: 
	#1. get addr. of cell_array  - data pos of the cursor.
	move $t0, $s2 #i
	move $t1, $s3 #j
	li $t2, 10
	
	mul $t3, $t0, $t2 # 10*i = t3
	add $t3, $t3, $t1 #+j
	
	add $t3, $t3, $s0 # +base addr. = data pos of the cursor(cell array) 
	move $s6, $t3
	
	lb $t3, ($t3) # t3 => the data (from cell_array) (8-bits)
	
	#2. check if it is revealed already
	move $t0, $t3
	srl $t0, $t0, 6 #right most => revealed? bit
	andi $t0, $t0, 1 #revealed ?
	beq $t0, 1, notValid #return -1
	#else: it is not revealed 
	#3. check if it is flagged
	move $t0, $t3
	srl $t0, $t0, 4 #r m => flag? bit
	andi $t0, $t0, 1 #flagged?
	beq $t0, 1, removeFlagR
	removeFlagDone:
	
	
	#change reveal bit to 1:
	#move $t9, $t3 #t9 : 8-bits data
	#srl $t9, $t9, 6 #....R
	
	#addi $t9, $t9, 1
	
	#sll $t9, $t9, 6 #t9
	
	#move $t8, $t3
	#sll $t8, $t8, 26
	#srl $t8, $t8, 26
	
	#or $t8, $t8, $t9
	
	#sb $t8, ($s6)
	
	move $a0, $s0
	move $a1, $s2
	move $a2, $s3
	jal search_cells # a0= byte[] array, a1 = int row, a2 = int col
	
	j finished
removeFlagR:
	#only data in cell array is changed:
	move $t0, $t3
	srl $t0, $t0, 5
	sll $t0, $t0, 5
	
	move $t1, $t3
	sll $t1, $t1, 28
	srl $t1, $t1, 28
	
	or $t1, $t1, $t0
	
	sb $t1, ($s6) #s6 is the addr. of data info(C.A.)
	
	j removeFlagDone
############################################################################
game_status:
	# $a0 => addr. cell array
	lw $t0, cursor_row #i
	lw $t1, cursor_col #j
	
	li $t2, 10
	mul $t0, $t0, $t2 #10*i
	add $t0, $t0, $t1 #+j
	
	add $t0, $t0, $a0 # + base addr.  
	
	lb $t0, ($t0) #t0 is 8bit - info 
	
	#1. lose check:
	srl $t1, $t0, 6 # lsb is revealed? or not 
	andi $t1, $t1, 1 # 00001 / 00000
	beq $t1, 1, revealedCase
	notDied:
	#2. win check:
	#check every cell in cell array
	move $t0, $a0 #cell array addr.(moving addr.)
	li $t1, 0 # counter
	li $t2, 0 #flag
	
	loop_check_win:
	bgt $t1, 99, out_lcw #will run from 0~ 99 (100 times)
	beq $t2, 1, onGoing #if the flag changed to 1, meaning on-going
		
	#get addr.	
	add $t3, $t1, $a0  #current addr.
	lb $t3, ($t3) #      8 bits-info => t3
	
	#A
	move $t4, $t3
	srl $t4, $t4, 5
	andi $t4, $t4, 1
	beq $t4, 1, bomb1 #there is a bomb.
	
	#else bomb == 0 
	#check if reveal ==1     (B)
	move $t4, $t3
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beq $t4, 0, flagTo1
	#else rev = 1, which passed the test
			
	backB1:	
	
	addi $t1, $t1, 1 #increment counter;
	j loop_check_win
	
	out_lcw: #win
	li $v0, 1
	jr $ra
flagTo1:
	li $t2, 1
	j loop_check_win
bomb1:
	move $t4, $t3
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beq $t4, 0, flagTo1
	#else , passed the test.
	j backB1
	
onGoing:
	li $v0, 0
	jr $ra
gameLost:
	li $v0, -1
	jr $ra

revealedCase:
	#check bomb
	move $t1, $t0
	srl $t1, $t1, 5
	andi $t1, $t1, 1
	beq $t1, 1, gameLost
	j notDied
##############################
# PART 5 FUNCTIONS
##############################

search_cells: #s6 not used, s7 not used
	addi $sp, $sp, -28 
	sw $ra, 0($sp) 
	
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	


	# a0: byte[] array,a1:  int row, a2 : int col
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	
	move $fp, $sp
	
	addi $sp, $sp, -4
	
	sw $s1, ($sp) #row
	
	addi $sp, $sp, -4
	sw $s2, ($sp) #col
	
	while_loop:
	beq $sp, $fp, out_while_loop
	
	##################
	lw $s2, ($sp) #col   j
	addi $sp, $sp, 4
	lw $s1, ($sp) #row  i
	

	addi $sp, $sp, 4
	
	move $t2, $s0 #base addr. of cell array
	li $t3, 10
	mul $t3, $s1, $t3 # i*10 = t3
	add $t3, $t3, $s2 # +j
	add $t3, $t3, $s0 #+addr = t3 #addr. of this.row and col. in incell_array_
	
	lb $t4, ($t3) #8 bit data
	
	move $t5, $t4
	
	srl $t5, $t5, 4 #flag bit on the LSB
	andi $t5, $t5, 1
	beq $t5, 0, notIsFlag # if (!cell[row][col].isFlag())
	
	backnotIsFlag:
	#second  if: (big if)
	
	move $t2, $s0 #base addr. of cell array
	li $t3, 10
	mul $t3, $s1, $t3 # i*10 = t3
	add $t3, $t3, $s2 # +j
	add $t3, $t3, $s0 #+addr = t3 #addr. of this.row and col. in incell_array_
	
	lb $t4, ($t3) #8 bit data
	li $t8, 15
	and $t8, $t8, $t4 #get the number bits => t8
	beqz $t8, bigIf
	backbigIf:
	j while_loop
	
	
	#################
	
	out_while_loop:
	#make the cursor color(bg) yellow back:
	
	lw $t0, cursor_row
	lw $t1, cursor_col
	
	li $t2, 0xffff0000 #base addr. 
	li $t3, 10
	mul $t3, $t0, $t3 #
	add $t3, $t3, $t1 #
	li $t9, 2
	mul $t3, $t9, $t3 # *2
	add $t2, $t2, $t3 #new_addr.   : t2
	
	addi $t2, $t2, 1 #move to color info addr.  
	
	lb $t1, ($t2)
	#set bg to yellow

	sll $t1, $t1, 28
	srl $t1, $t1, 28 #  .......xxxx
	
	
	li $t9, 0xb0  #1011 0000  - yellow bg
	or $t9, $t9, $t1
	
	sb $t9, ($t2) #store color info back to $t2, 
	#done//

	#reg. conv.
	
	lw $ra, 0($sp)
	
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	
	addi $sp, $sp, 28 
	
	jr $ra
notIsFlag:
	#cell[row][col].reveal() :
	#1. change the cell-array data to revealed.
	# 8 bit data in t4
	li $t9, 0x40 #1000000
	or $t9, $t9, $t4
	
	sb $t9, ($t3)
	#2. change the colors &chars
	
	li $t8, 15
	and $t8, $t8, $t4 #get the number bits
	#Now, t8 is how many bombs around. 
	beq $t8, 0, setCharToNull
	
	addi $t8, $t8, 48 #char now
	move $a2, $t8
	
	backsetCharToNull:
	#   set $a2      #char
	move $a0, $s1    #row
    	move $a1, $s2   #col
    	li $t7, 0xd
    	move $a3, $t7   #fg
    	
    	addi $sp, $sp, -4
    	sw $0, 0($sp)  #bg in stack
    	
    	jal set_cell
    	
    	addi $sp, $sp, 4 #release stack
	
	j backnotIsFlag
setCharToNull:
	move $a2, $0
	j backsetCharToNull
bigIf:
	#getData(reg row, reg col)  => sets $t4 to the 8 bit data.
	#getData macro overides: $t2~$t4
	li $s3, 10
	#1. hidden:  srl by 6, lsb be revealed?-bit
	#2. isFlag:  srl by 4, lsb be flag?-bit
	#if[1]:
	addi $t0, $s1, 1 #row +1
	blt $t0, $s3, condi01
	
	condi01b:
	#else: next  if[2]:
	addi $s4, $s2, 1
	blt $s4, $s3, condi2
	
	condi2b:
	#else: next if[3]
	addi $s4, $s1, -1
	bge $s4, 0, condi3
	
	#else: next =>if statement[4]
	condi3b:
	addi $s4, $s2, -1
	bge $s4, 0, condi4
	
	#else: next : if [5] (last page of pdf)
	condi4b:
	addi $s4, $s1, -1 #new row
	addi $s5, $s2, -1 #new col
	
	bge $s4, 0, condi5
	#else: next: [6]
	condi5b:
	#6:
	addi $s4, $s1, -1
	addi $s5, $s2, 1
	bgez $s4, condi6
	#else: next [7]
	condi6b:
	#7:
	addi $s4, $s1, 1
	addi $s5, $s2, -1
	blt $s4, 10, condi7
	#else: next[8]
	condi7b:
	#8:
	addi $s4, $s1, 1
	addi $s5, $s2, 1
	
	blt $s4, 10, condi8
	#else: 
	condi8b:
	
	j backbigIf
condi01:
	addi $t0, $s1, 1 #r+1
	getData($t0, $s2)
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beqz $t4, nextCheck01
	j condi01b
nextCheck01:
	addi $t0, $s1, 1#r+1
	getData($t0, $s2)
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beqz $t4, allTrue01
	j condi01b
allTrue01:
	addi $sp, $sp, -4
	addi $t0, $s1, 1
	sw $t0, ($sp)
	addi $sp, $sp, -4
	sw $s2, ($sp)
	j condi01b
	
condi2:
	getData($s1, $s4)
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beqz $t4, nextCheck2
	j condi2b
nextCheck2:
	getData($s1, $s4)
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beqz $t4, allTrue2
	j condi2b
allTrue2:
	push($s1)
	push($s4)
	j condi2b
condi3:
	getData($s4, $s2)
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beqz $t4, checkNext3
	j condi3b
checkNext3:
	getData($s4, $s2)
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beqz $t4, allTrue3
	j condi3b
allTrue3:
	push($s4)
	push($s2)
	j condi3b
condi4:
	getData($s1, $s4)
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beqz $t4, checkNext4
	j condi4b
checkNext4:
	getData($s1, $s4)
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beqz $t4, allTrue4
	j condi4b
allTrue4:
	push($s1)
	push($s4)
	j condi4b
condi5:
	bge $s5, 0, checkNext5
	j condi5b
checkNext5:
	getData($s4, $s5)
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beqz $t4, checkNN5
	j condi5b
checkNN5:
	getData($s4, $s5)
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beqz $t4, allTrue5
	j condi5b
allTrue5:
	push($s4)
	push($s5)
	j condi5b

condi6:	
	blt $s5, 10, next6
	j condi6b
next6:
	getData($s4, $s5)
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beqz $t4, checkNext6
	j condi6b
checkNext6:
	getData($s4, $s5)
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beqz $t4, allTrue6
	j condi6b
allTrue6:
	push($s4)
	push($s5)
	j condi6b
condi7:
	bge $s5, 0, cn7
	j condi7b
cn7:
	getData($s4, $s5)
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beqz $t4, cnn7
	j condi7b
cnn7:
	getData($s4, $s5)
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beqz $t4, allTrue7
	j condi7b
allTrue7:
	push($s4)
	push($s5)
	j condi7b

condi8:	
	blt $s5, 10, cn8
	j condi8b
cn8:
	getData($s4, $s5)
	srl $t4, $t4, 6
	andi $t4, $t4, 1
	beqz $t4, cnn8
	j condi8b
	
cnn8:
	getData($s4, $s5)
	srl $t4, $t4, 4
	andi $t4, $t4, 1
	beqz $t4, allTrue8
	j condi8b
	
allTrue8:
	push($s4)
	push($s5)
	j condi8b
#################################################################
# data section           ########################################
.data
.align 2  # Align next items to word boundary
cursor_row: .word -1
cursor_col: .word -1
buffer: .byte 0
