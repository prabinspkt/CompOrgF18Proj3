.data

    input_too_long:
    .asciiz "Input is too long."
    input_is_empty:
    .asciiz "Input is empty."
    invalid_number:
    .asciiz "Invalid base-36 number."
    input_storage:
    .space 2000                                 # reserves space memory for user input string
    filtered_input:                             # allocate 4 bytes for filtered out string that doesn't have white spaces
    .space 4

.text
main:

    la $a0, input_storage                       # $a0 points to the starting address of user input
    li $v0, 8                                   # load code into $v0, $v0 is for user string input
    syscall

    # Use a loop to extract string and exclude white spaces

    li $s2, 0                                   # s2 is updated to 1 if a non-NUL, non-space or non-new-line-char is found once
    # The idea is that if these types of characters are found again after loading 4 bytes into filtered_input, the user input has more than four chars
    li $t1, 10                                  # load new line char ASCII into $t1
    li $t2, 32                                  # load space char ASCII into $t2

    filter_loop:
    lb $t0, 0($a0)                              # load byte from $a0, $a0 currently points to first byte of user input and is updated in the loop
    beq $t0, $t1, exit_filter_loop              # exit when new line char found
    beq $t0, $t2, skip                          # if space is found, skip to check another byte
    beqz $t0, exit_filter_loop                  # exit loop when NUL is found
    # If program reaches this point, it has skipped spaces and found a non-space, non-NUL or non-new-line-char
    # If non-space, non-new-line-char or non-NUL char found, put this and next three bytes in filtered_input
    bne $s2, $zero, print_more_than_four        # if a non-NUL, non-space or non-new-line char is found after loading 4 bytes into filtered_input, $s2 will have been updated to 1. Finding such char again means user input is more than 4 char long
    li $s2, 1                                   # once program reaches this point, 1 is loaded into $s2
    la $a1, filtered_input                      # load address of filtered_input
    sb $t0, 0($a1)
    lb $t0, 1($a0)
    sb $t0, 1($a1)
    lb $t0, 2($a0)
    sb $t0, 2($a1)
    lb $t0, 3($a0)
    sb $t0, 3($a1)
    addi $a0, $a0, 3                            # updated address pointed in the loop to skip checking the 4 bytes already loaded into filtered_input

    skip:
    addi $a0, $a0, 1
    jal filter_loop

    exit_filter_loop:
    # If $s2 is still 0, it means that either the user input is empty or the has only spaces
    beqz $s2, print_empty

    # START OF INSTRUCTIONS CALCULATE AND CHECK FOR INVALID CHAR IN FILTERED STRING FROM USER INPUT STRING
    li $s0, 1                                   # number to multiply 36 with after each iteration of valid char
    li $s1, 0                                   # sum number based on calculation in each iteration
    li $s4, 0                                   # loop counter
    li $s6, 0                                   # will be updated to 1 when a non-space, non-NUL or non-new-line-char is found. If this is already 1 and space is found, jump to print_invalid_value
    la $a0, filtered_input                      # $a0 now holds the address of the first byte of filtered_input
    addi $a0, $a0, 4                            # $a0 points to the 5th byte now. It will point to 4th byte after it is decremented by 1 in the loop before loading byte (see below)

    loop:
    # HOW DOES THIS LOOP WORK?
    # Loop starts loading bytes from the 4th position i.e. 3rd offset
    # Exits the loop if invalid value found
    # Ignores NUL and new line char as user string can be less than 4 char long
    # Ignore space char if it is discovered before alphanumerica char has been discovered, else print invalid value

    # Maintain a count of numer of characters read using $s4
    # If count is 4, branch to exit_loop (count starts from 0)
    li $t5, 4
    beq $t5, $s4, loop_exit
    addi $s4, $s4, 1                            # update the value of counter by 1 irrespective of valid/invalid char
    addi $a0, $a0, -1                           # update the value of $a0 so that it points to an address before the previous byte

    lb $t2, 0($a0)                              # get ASCII value of current character
    beqz $t2, loop                              # if the value is NUL, branch to loop start

    li $a1, 10                                  # load new line char in $a1
    beq $a1, $t2, loop                          # go to loop start if it is new line char. this is useful when user input is less than 4 char. if input 3 char, 4th byte will be new line char

    li $s7, 32                                  # load ASCII of space into $s7
    beq $t2, $s7, handle_space                  # if space is found, let handle_space take care of what to do

    # if program reaches this point, it means that a non-NUL, non-new-line-char or non-space char is found
    # update $s6 to 1. if a space if found after $s6 has been updated to 1, jump to print_invalid
    li $s6, 1

    # Now that $t2 does not have NUL or new line char, check if the char is valid in 36-base system
    li $t0, 47
    slt $t1, $t0, $t2
    slti $t4, $t2, 58
    and $s5, $t1, $t4                           # if $t2 has value within range 48 and 57, $s5 will have 1, else 0
    addi $s3, $t2, -48                          # $s3 has required value used for calulation later
    li $t7, 1
    beq $t7, $s5, calculation                   # if $s5 already has 1, calculate the char's value from ASCII and skip other checks and branch to calculation

    li $t0, 64
    slt $t1, $t0, $t2
    slti $t4, $t2, 91
    and $s5, $t1, $t4                           #if $t2 has value within range 65 and 90, $s5 will have 1, else 0
    addi $s3, $t2, -55                          # $s3 has required value used for calulation later
    li $t7, 1
    beq $t7, $s5, calculation                   # if $s5 already has 1, calculate the char's value from ASCII and skip other checks and branch to calculation

    li $t0, 96
    slt $t1, $t0, $t2
    slti $t4, $t2, 123
    and $s5, $t1, $t4                           #if $t2 has value within range 97 and 122, $s5 will have 1, else 0
    addi $s3, $t2, -87                          # $s3 has required value used for calulation later
    li $t7, 1
    beq $t7, $s5, calculation                   # if $s5 already has 1, calculate the char's value from ASCII and skip other checks and branch to calculation

    # If $s5 is still 0, it means that $t2 has an invalid char in base-36 system
    beq $s5, $zero, print_invalid_value         # if $t2 has invalid value, jump to print_invalid_value

    calculation:
    mult $s0, $s3                               # $s0 has the required power of 36 and $s3 is the value of valid char in 36-base number system
    mflo $t3
    add $s1, $s1, $t3                           # add the above multiplication to the value resulting from calculation of previous chars

    # Calculate the value of $s0 for next round of multiplication. Current value should be multiplied by 36, if the previous char was valid and used in calculation
    li $t6, 36
    mult $s0, $t6
    mflo $s0

    # Start the loop again
    jal loop

    handle_space:
    beq $zero, $s6, loop                        # if no alphanumeric char found yet, simply branch to loop
    jal print_invalid_value                     # if alphanumeric char was found already and a space is found again, jump to print_invalid_value

    # Program reaches this point after successful reading of user string and successful calculation of it's unsigned decimal value
    loop_exit:
    li $v0, 1                                   # load code to print integer
    add $a0, $zero, $s1                         # load value calculated in the loop
    syscall
    jal exit

    print_empty:
    la $a0, input_is_empty                      # load address of the string to print
    li $v0, 4                                   # load code to print string
    syscall
    jal exit

    print_invalid_value:
    la $a0, invalid_number                      # load address of the string to print
    li $v0, 4                                   # load code to print string
    syscall
    jal exit

    print_more_than_four:
    la $a0, input_too_long                      # load address of the string to print
    li $v0, 4                                   # load code to print string
    syscall

    exit:
    li $v0, 10                                  # load code to exit the program
    syscall
