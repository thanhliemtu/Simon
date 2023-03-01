.data
count:            .word 1

red:              .byte 0,0,255
.align             4
green:            .byte 0,255,0
.align             4
blue:             .byte 255,0,0
.align             4
yellow:           .byte 0,255,255
.align             4
black:            .byte 0,0,0
.align             4
white:            .byte 255,255,255
.align             4
pink:             .byte 203,82,217
.align             4
purple:           .byte 237,102,127
.align             4

sequence:         .byte 0,0,0,0

.globl main
.text

main:    
    # TODO: Before we deal with the LEDs, we need to generate a random
    # sequence of numbers that we will use to indicate the button/LED
    # to light up. For example, we can have 0 for UP, 1 for DOWN, 2 for
    # LEFT, and 3 for RIGHT. Store the sequence in memory. We provided 
    # a declaration above that you can use if you want.
    # HINT: Use the rand function provided to generate each number
    
    lw s3, count # s3 = count
    la s4, sequence # s4 = sequence[] 
start_next_round:
# This loop initializes the array with random numbers
array_init_loop_init:
    li s2, 0 # s2 = 0

array_init_loop_body:
    bge s2, s3, array_init_loop_end # check if s2 >= s3, if yes, end
    slli s5, s2, 2 # s5 = s2 * 4
    add s5, s5, s4 # s5 is address of sequence[s2]
    li a0, 4 # Putting 4 into a0
    call rand # Calling rand with a0 = 10, so rand(10)
    sw a0, 0(s5) # sequence[s2] = a0 (which is a random num)
    addi s2, s2, 1 # s2 = s2 + 1
    j array_init_loop_body
array_init_loop_end:
   
    # TODO: Now read the sequence and replay it on the LEDs. You will
    # need to use the delay function to ensure that the LEDs light up 
    # slowly. In general, for each number in the sequence you should:
    # 1. Figure out the corresponding LED location and colour
    # 2. Light up the appropriate LED (with the colour)
    # 2. Wait for a short delay (e.g. 500 ms)
    # 3. Turn off the LED (i.e. set it to black)
    # 4. Wait for a short delay (e.g. 1000 ms) before repeating
    
read_array_and_display_init:
    li s2, 0 # s2 = 0
read_array_and_display_body:
    bge s2, s3, read_array_and_display_end # check if s2 >= s3, if yes, end
    slli s5, s2, 2 # s5 = s2 * 4
    add s5, s5, s4 # s5 is address of sequence[s2]
    lw s6, 0(s5) # s6 = sequence[s2] (which is a random num)
    li s7, 0
    li s8, 1
    li s9, 2
    
check_up:
    bne s6, s7, check_down
    call turn_on_up
    li a0, 1000
    call delay
    call turn_off_up
    j end_check
check_down:
    bne s6, s8, check_left
    call turn_on_down
    li a0, 1000
    call delay
    call turn_off_down
    j end_check
check_left:
    bne s6, s9, check_right
    call turn_on_left
    li a0, 1000
    call delay
    call turn_off_left
    j end_check
check_right:
    call turn_on_right
    li a0, 1000
    call delay
    call turn_off_right
end_check:
    li a0, 1000
    call delay
    addi s2, s2, 1 # s2 = s2 + 1
    j read_array_and_display_body
read_array_and_display_end:
    
    # TODO: Read through the sequence again and check for user input
    # using pollDpad. For each number in the sequence, check the d-pad
    # input and compare it against the sequence. If the input does not
    # match, display some indication of error on the LEDs and exit. 
    # Otherwise, keep checking the rest of the sequence and display 
    # some indication of success once you reach the end.

read_array_and_poll_init:
    li s2, 0 # s2 = 0  
read_array_and_poll_body:
    bge s2, s3, read_array_and_poll_end # check if s2 >= s3, if yes, end
    slli s5, s2, 2 # s5 = s2 * 4
    add s5, s5, s4 # s5 is address of sequence[s2]
    lw s6, 0(s5) # s6 = sequence[s2] (which is a random num)
    call pollDpad # Getting the input from dpad
    
input_check:
    bne a0, s6, game_over

    addi s2, s2, 1 # s2 = s2 + 1
    j read_array_and_poll_body
read_array_and_poll_end:
    call turn_on_correct
    li a0, 50
    call delay
    call turn_off_correct
    li a0, 50
    call delay
    call turn_on_correct
    li a0, 50
    call delay
    call turn_off_correct
game_over:
    
    # TODO: Ask if the user wishes to play again and either loop back to
    # start a new round or terminate, based on their input.
 
exit:
    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---
# Feel free to use (or modify) them however you see fit

# DELAY FUNCTION
# Takes in the number of milliseconds to wait (in a0) before returning
delay:
    mv t0, a0
    li a7, 30
    ecall
    mv t1, a0
delayLoop:
    ecall
    sub t2, a0, t1
    bgez t2, delayIfEnd
    addi t2, t2, -1
delayIfEnd:
    bltu t2, t0, delayLoop
    jr ra
# END OF DELAY FUNCTION

# RANDOM GENERATOR FUNCTION
# Takes in a number in a0, and returns a (sort of) random number from 0 to
# this number (exclusive)
rand:
    mv t0, a0
    li a7, 30
    ecall
    remu a0, a0, t0
    jr ra
# END OF RANDOM GENERATOR FUNCTION

# Takes in an RGB color in a0, an x-coordinate in a1, and a y-coordinate
# in a2. Then it sets the led at (x, y) to the given color.
setLED:
    li t1, LED_MATRIX_0_WIDTH
    mul t0, a2, t1
    add t0, t0, a1
    li t1, 4
    mul t0, t0, t1
    li t1, LED_MATRIX_0_BASE
    add t0, t1, t0
    sw a0, (0)t0
    jr ra
    
# Polls the d-pad input until a button is pressed, then returns a number
# representing the button that was pressed in a0.
# The possible return values are:
# 0: UP
# 1: DOWN
# 2: LEFT
# 3: RIGHT
pollDpad:
    mv a0, zero
    li t1, 4
pollLoop:
    bge a0, t1, pollLoopEnd
    li t2, D_PAD_0_BASE
    slli t3, a0, 2
    add t2, t2, t3
    lw t3, (0)t2
    bnez t3, pollRelease
    addi a0, a0, 1
    j pollLoop
pollLoopEnd:
    j pollDpad
pollRelease:
    lw t3, (0)t2
    bnez t3, pollRelease
pollExit:
    jr ra

turn_on_up:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, blue
    li a1, 1
    li a2, 0
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_on_down:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, yellow
    li a1, 1
    li a2, 2
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_on_left:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, pink
    li a1, 0
    li a2, 1
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_on_right:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, purple
    li a1, 2
    li a2, 1
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_off_up:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, black
    li a1, 1
    li a2, 0
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_off_down:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, black
    li a1, 1
    li a2, 2
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_off_left:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, black
    li a1, 0
    li a2, 1
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_off_right:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, black
    li a1, 2
    li a2, 1
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_on_correct:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, green
    li a1, 1
    li a2, 1
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra
    
turn_off_correct:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a0, black
    li a1, 1
    li a2, 1
    call setLED
    lw ra, 0(sp)
    addi, sp, sp, 4
    jr ra