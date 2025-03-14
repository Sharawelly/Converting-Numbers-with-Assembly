.data
    the_current_system: .asciiz "Enter the current system: "
    get_the_number:    .asciiz "Enter the number: "
    the_new_system:   .asciiz "Enter the new system: "
    answer_msg:       .asciiz "The number in new base system "
    answer_msg2:      .asciiz " is: "
    invalid_digit:    .asciiz "There is Digit in input number is invalid for base "
    newline:          .asciiz "\n"
    number:           .space 64
    answer:           .space 64

.text
.globl main

main:
    jal get_current_base_system
    jal get_number
    jal get_new_base
    jal validation
    jal convertFromDecimal
    jal print_message
    jal print_answer

   
get_current_base_system:
    li $v0, 4
    la $a0, the_current_system
    syscall 
    
    li $v0, 5
    syscall
    move $t0, $v0 
    move $s0, $t0      # s0 = fromBase   
    jr $ra


get_number:
    # Get input number
    li $v0, 4
    la $a0, get_the_number
    syscall
    
    li $v0, 8  
    la $a0, number
    li $a1, 64
    syscall
    
    li $t3, 0              # t3 to get the length of number
    # Remove enter effect
    la $t0, number
    remove_newline:
        lb $t1, ($t0)
        beq $t1, 10, replace_newline
        addi $t0, $t0, 1
        addi $t3, $t3, 1
        j remove_newline
        replace_newline:
        sb $zero, ($t0)
    jr $ra

get_new_base:
    # Get toBase
    li $v0, 4
    la $a0, the_new_system
    syscall
    
    li $v0, 5
    syscall
    move $s1, $v0      # s1 = toBase
    jr $ra
    
validation:
    la $t1, number  # pointer to the number
    add $t2, $zero, $s0 # $t2 will contain old base (current base)
    li $t4, 0  # now $t4 will contains 0
    
start_validation:
    beq $t4, $t3, convertToDecimal
    lb $t5, ($t1)
    ble $t5, 57, check_digit  # if $t5 less than or equal 9 
    ble $t5, 70, check_char  # if $t5 less than or equal F 
    j print_error
    
check_digit:
    blt $t5, 48, print_error
    subi $t5, $t5, 48  # if $t5 contains digit subtract '0'     
    j continue_validation
    
check_char:
    blt $t5, 65, print_error
    subi $t5, $t5, 65   # if $t5 contains char subtract 'A' 
    addi $t5, $t5, 10
    
continue_validation:
    bge $t5, $t2, print_error
    addi $t1, $t1, 1
    addi $t4, $t4, 1
    j start_validation
    
print_error:
    li $v0, 4
    la $a0, invalid_digit
    syscall
    j exit
    


convertToDecimal:
    la $a0, number 
    move $t0, $a0          # t0 = string address (number)
    add $t1, $zero, $s0          # t1 = from base
    li $t2, 0              # t2 = decimal result
    
# loop on each char to covert it    
loop_on_chars:
    beqz $t3, loop_done
    lb $t4, ($t0)          # Load character
    ble $t4, 57, handle_digit  # if $t4 less than or equal 9 
    subi $t4, $t4, 65
    addi $t4, $t4, 10 
    j check_value
    
handle_digit:
    subi $t4, $t4, 48    
check_value:
    # Initialize loop counter and prepare for power loop
    li $t5, 0          # t5 acts as the loop counter

power_loop:
    addi $t7, $t3, -1    # Compute t3 - 1
    beq $t5, $t7, exit_power_loop
    mul $t4, $t4, $t1
    addi $t5, $t5, 1
    j power_loop

exit_power_loop:
    add $t2, $t2, $t4
    subi $t3, $t3, 1
    addi $t0, $t0, 1
    j loop_on_chars
    
loop_done:
    move $s2, $t2
    jr $ra


convertFromDecimal:
    move $t0, $s2          # t0 = decimal number
    add $t5, $zero, $t0
    add $t1, $zero, $s1          # t1 = new base
    la $t2, answer         # t2 = result buffer
    add $t3, $zero, $t2              # t3 = hold the address of our answer

	start_converting:
     		slt $t4, $t0, $t1 # set $t4 = 1, if $t0 < $t1 else $t4 = 0
     		bne $t4, $zero, else # branch if $t0 < $t1 (decimal number < base)
     		div $t0, $t1 # if decimal number > base then divide (decimal number / base)
    	        mfhi $t5              # t5 = remainder
     		mflo $t0              # t0 = quotient 
     		slti $t4, $t5, 10 # set $t4 = 1, if $t5 < 10 else $t4 = 0
     		bne $t4, $zero, digit_to_be_stored # branch if $t5 < 10 (remainder < 10)
     		# else the remainder is greater than 10 so we should make it a charcter
     		subi $t5, $t5, 10 # substract 10 to get the right char (A, B, ....)
     		addi $t5, $t5, 65 # Add 65 (char A)
     		sb $t5, ($t2)
     		addi $t2, $t2, 1
    	        j start_converting

		digit_to_be_stored:
     			addi $t5, $t5, 48 # add zero
    		        sb $t5, ($t2)
     			addi $t2, $t2, 1
     			j start_converting
 
     
	        else:
    			slti $t4, $t0, 10 # set $t4 = 1, if $t0 < 10 else $t4 = 0
    			bne $t4, $zero, set_digit_else # branch if $t0 < 10 (quotient < 10)
    			subi $t0, $t0, 10
    			addi $t0, $t0, 65
    			sb $t0, ($t2)
    			jr $ra
    

	        set_digit_else:
    			addi $t0, $t0, 48 # add zero 
   			 sb $t0, ($t2)
   			 jr $ra

print_message:
    li $v0, 4
    la $a0, answer_msg
    syscall
    
    li $v0, 1
    move $a0, $s1
    syscall
    
    li $v0, 4
    la $a0, answer_msg2
    syscall   
    jr $ra
print_answer:
    # Now t3 pionts to first digit, t2 points to the last character
    lb $a0, ($t2)
    li $v0, 11    # Print character syscall
    syscall
    beq $t3, $t2, exit # done printing
    
    subi $t2, $t2, 1 # roh lel el char el 2blo  
    j print_answer
    

exit:
    li $v0, 10
    syscall
