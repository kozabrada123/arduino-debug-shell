/*
 * string_algorithms.asm
 *
 *  Created: 11/12/2024 09:51:50
 *   Author: Natan Jurca
 */ 

// Contains home cooked string algorithms
// This was probably the hardest part of the project to write

// Parses the string in RAM, starting at where Y is pointing as an 8-bit number into r18.
// In the event of a failure, r17 will have a non-zero (1) value
//
// Does not modify Y
parse_string_Y_ram_as_u8:
	clr r18
	push YH
	push YL
	push r19 // r19 will be our counter for which position we are from the back
	push r20 // temp value
	push r21
	ldi r19, 0
	ldi r20, 0
	ldi r21, 0
	// Check for non empty input string
	ld r16, Y
	cpi r16, 0
	breq _parse_u8_err_return

// First part of the loop: find the end and check that it is just numbers
_parse_u8_loop_1:
	ld r16, Y+ 
	// Check for a zero value, an end of the string
	cpi r16, 0
	brne _parse_u8_loop_1_continue

	// This loop has done its job
	// However, we need to decrease Y once, for the next loop
	ld r16, -Y
	breq _parse_u8_loop_2

_parse_u8_loop_1_continue:
	// Check for hex value
	call is_r16_alphanumeric
	cpi r17, 1
	brne _parse_u8_err_return

	rjmp _parse_u8_loop_1

_parse_u8_loop_2:
	ld r16, -Y
	// Check for a zero value, a start of the string
	cpi r16, 0
	breq _parse_u8_ok_return // This loop has done its job
	// Not zero, ascii magic to get the real value
	andi r16, 0x0F

	// Are we at 10^0?
	cpi r19, 0
	breq _parse_u8_skip_mult

	// Mul r16 with 10 to the power of the position value
	mov r20, r19
	ldi r21, 10

_inner_loop_parse_u8_loop_2:
	mul r16, r21
	mov r16, r0 // Move the result into r16
	// Did we get a carry? error
	brcs _parse_u8_err_return
	dec r20
	brne _inner_loop_parse_u8_loop_2

_parse_u8_skip_mult:
	// Add to r18
	add r18, r16

	// Did we get a carry? error
	brcs _parse_u8_err_return

	inc r19 // We are one position farther now
	rjmp _parse_u8_loop_2

_parse_u8_ok_return:
	pop r21
	pop r20
	pop r19
	pop YL
	pop YH
	clr r17
	ret

_parse_u8_err_return:
	pop r21
	pop r20
	pop r19
	pop YL
	pop YH
	ldi r17, 1
	ret

// Relative branch out of reach....
_parse_u16_err_return_2:
	jmp _parse_u16_err_return

// Parses the string in RAM, starting at where Y is pointing as a 16-bit number into r19 - r18.
// In the event of a failure, r17 will have a non-zero (1) value
//
// Does not modify Y
parse_string_Y_ram_as_u16:
	clr r18
	push YH
	push YL
	push r20 // r20 will be our counter for which position we are from the back
	push r21 // temp value
	push r22
	push r23 // r24 - r23 is a temporary 16 bit value used in multiplication
	push r24
	ldi r19, 0
	ldi r20, 0
	ldi r21, 0
	ldi r22, 0
	ldi r23, 0
	ldi r24, 0
	// Check for non empty input string
	ld r16, Y
	cpi r16, 0
	breq _parse_u16_err_return_2

// First part of the loop: find the end and check that it is just numbers
_parse_u16_loop_1:
	ld r16, Y+ 
	// Check for a zero value, an end of the string
	cpi r16, 0
	brne _loop_u16_1_continue

	// This loop has done its job
	// However, we need to decrease Y once, for the next loop
	ld r16, -Y
	breq _parse_u16_loop_2

_loop_u16_1_continue:
	// Check for numeric value
	call is_r16_number
	cpi r17, 1
	brne _parse_u16_err_return

	rjmp _parse_u16_loop_1

_parse_u16_loop_2:
	ld r16, -Y
	// Check for a zero value, a start of the string
	cpi r16, 0
	breq _parse_u16_ok_return // This loop has done its job
	// Not zero, ascii magic to get the real value
	andi r16, 0x0F

	// Are we at 10^0?
	cpi r20, 0
	breq _skip_mult_u16

	// Mul r16 with 10 to the power of the position value
	mov r21, r20
	ldi r22, 10

	// Move r16 into r24 - r23, to have a mul loop
	mov r23, r16
	clr r16
	clr r24 // Clear the top of the temp u16

_inner_loop_parse_u16_loop_2:
	// Multiply our number by 10 -- this is all this next code does
	// Mul lower and save into r16
	mul r23, r22
	mov r23, r0
	mov r16, r1

	// Mul higher and add what we saved into r16
	mul r24, r22
	mov r24, r0
	add r24, r16

	dec r21
	brne _inner_loop_parse_u16_loop_2
	// Add the result of r24 - r23 to r19 - r18
	add r18, r23
	adc r19, r24
	rjmp _after_add_u16

_skip_mult_u16:
	// Add to r19 - r18
	add r18, r16
	// Note: we know r20 is 0, we checked before
	adc r19, r20
	rjmp _after_add_u16

_after_add_u16:
	// Did we get a carry? error
	brcs _parse_u16_err_return

	inc r20 // We are one position farther now
	rjmp _parse_u16_loop_2

_parse_u16_ok_return:
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop YL
	pop YH
	clr r17
	ret

_parse_u16_err_return:
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop YL
	pop YH
	ldi r17, 1
	ret

// Parses the string in RAM, starting at where Y is pointing as an 8-bit hex number into r18.
// In the event of a failure, r17 will have a non-zero (1) value
//
// Does not modify Y
parse_hex_string_Y_ram_as_u8:
	clr r18
	push YH
	push YL
	push r19 // r19 will be our counter for which position we are from the back
	push r20 // temp value
	push r21
	ldi r19, 0
	ldi r20, 0
	ldi r21, 0
	// Check for non empty input string
	ld r16, Y
	cpi r16, 0
	breq _parse_hex_u8_err_return

// First part of the loop: find the end and check that it is just numbers
_parse_hex_u8_loop_1:
	ld r16, Y+ 
	// Check for a zero value, an end of the string
	cpi r16, 0
	brne _parse_hex_u8_loop_1_continue

	// This loop has done its job
	// However, we need to decrease Y once, for the next loop
	ld r16, -Y
	breq _parse_hex_u8_loop_2

_parse_hex_u8_loop_1_continue:
	// Check for validity
	call is_r16_lowercase_hex
	cpi r17, 1
	brne _parse_hex_u8_err_return

	rjmp _parse_hex_u8_loop_1

_parse_hex_u8_loop_2:
	ld r16, -Y
	// Check for a zero value, a start of the string
	cpi r16, 0
	breq _parse_hex_u8_ok_return // This loop has done its job
	
	mov r20, r16
	// Not zero, ascii magic to get the real value
	andi r20, 0x0F

	// If we are a hex letter, add 9 to get the real value
	call is_r16_lowercase_hex_letter
	cpi r17, 1
	brne _skip_add_9
	subi r20, -9

_skip_add_9:
	mov r16, r20

	// Are we at 16^0?
	cpi r19, 0
	breq _parse_hex_u8_skip_mult

	// Mul r16 with 16 to the power of the position value
	mov r20, r19
	ldi r21, 0x10

_inner_loop_parse_hex_u8_loop_2:
	mul r16, r21
	mov r16, r0 // Move the result into r16
	// Did we get a carry? error
	brcs _parse_hex_u8_err_return
	dec r20
	brne _inner_loop_parse_hex_u8_loop_2

_parse_hex_u8_skip_mult:
	// Add to r18
	add r18, r16

	// Did we get a carry? error
	brcs _parse_hex_u8_err_return

	inc r19 // We are one position farther now
	rjmp _parse_hex_u8_loop_2

_parse_hex_u8_ok_return:
	pop r21
	pop r20
	pop r19
	pop YL
	pop YH
	clr r17
	ret

_parse_hex_u8_err_return:
	pop r21
	pop r20
	pop r19
	pop YL
	pop YH
	ldi r17, 1
	ret

// Relative branch out of reach....
_parse_hex_u16_err_return_2:
	jmp _parse_hex_u16_err_return

// Parses the string in RAM, starting at where Y is pointing as a 16-bit hex number into r19 - r18.
// In the event of a failure, r17 will have a non-zero (1) value
//
// Does not modify Y
parse_hex_string_Y_ram_as_u16:
	clr r18
	push YH
	push YL
	push r20 // r20 will be our counter for which position we are from the back
	push r21 // temp value
	push r22
	push r23 // r24 - r23 is a temporary 16 bit value used in multiplication
	push r24
	ldi r19, 0
	ldi r20, 0
	ldi r21, 0
	ldi r22, 0
	ldi r23, 0
	ldi r24, 0
	// Check for non empty input string
	ld r16, Y
	cpi r16, 0
	breq _parse_hex_u16_err_return_2

// First part of the loop: find the end and check that it is just numbers
_parse_hex_u16_loop_1:
	ld r16, Y+ 
	// Check for a zero value, an end of the string
	cpi r16, 0
	brne _loop_hex_u16_1_continue

	// This loop has done its job
	// However, we need to decrease Y once, for the next loop
	ld r16, -Y
	breq _parse_hex_u16_loop_2

_loop_hex_u16_1_continue:
	// Check for numeric value
	call is_r16_lowercase_hex
	cpi r17, 1
	brne _parse_hex_u16_err_return

	rjmp _parse_hex_u16_loop_1

_parse_hex_u16_loop_2:
	ld r16, -Y
	// Check for a zero value, a start of the string
	cpi r16, 0
	breq _parse_hex_u16_ok_return // This loop has done its job
	
	mov r21, r16
	// Not zero, ascii magic to get the real value
	andi r21, 0x0F

	// If we are a hex letter, add 9 to get the real value
	call is_r16_lowercase_hex_letter
	cpi r17, 1
	brne _skip_add_9_u16
	subi r21, -9

_skip_add_9_u16:
	mov r16, r21

	// Are we at 16^0?
	cpi r20, 0
	breq _skip_mult_hex_u16

	// Mul r16 with 16 to the power of the position value
	mov r21, r20
	ldi r22, 0x10

	// Move r16 into r24 - r23, to have a mul loop
	mov r23, r16
	clr r16
	clr r24 // Clear the top of the temp u16

_inner_loop_parse_hex_u16_loop_2:
	// Multiply our number by 10 -- this is all this next code does
	// Mul lower and save into r16
	mul r23, r22
	mov r23, r0
	mov r16, r1

	// Mul higher and add what we saved into r16
	mul r24, r22
	mov r24, r0
	add r24, r16

	dec r21
	brne _inner_loop_parse_hex_u16_loop_2
	// Add the result of r24 - r23 to r19 - r18
	add r18, r23
	adc r19, r24
	rjmp _after_add_hex_u16

_skip_mult_hex_u16:
	// Add to r19 - r18
	add r18, r16
	// Note: we know r20 is 0, we checked before
	adc r19, r20
	rjmp _after_add_hex_u16

_after_add_hex_u16:
	// Did we get a carry? error
	brcs _parse_hex_u16_err_return

	inc r20 // We are one position farther now
	rjmp _parse_hex_u16_loop_2

_parse_hex_u16_ok_return:
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop YL
	pop YH
	clr r17
	ret

_parse_hex_u16_err_return:
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop YL
	pop YH
	ldi r17, 1
	ret
	
// Parses the string in RAM, starting at where Y is pointing as an 8-bit binary number into r18.
// In the event of a failure, r17 will have a non-zero (1) value
//
// Does not modify Y
parse_bin_string_Y_ram_as_u8:
	clr r18
	push YH
	push YL
	push r19 // r19 will be our counter for which position we are from the back
	push r20 // temp value
	ldi r19, 0
	ldi r20, 0
	// Check for non empty input string
	ld r16, Y
	cpi r16, 0
	breq _parse_bin_u8_err_return

// First part of the loop: find the end and check that it is just numbers
_parse_bin_u8_loop_1:
	ld r16, Y+ 
	// Check for a zero value, an end of the string
	cpi r16, 0
	brne _parse_bin_u8_loop_1_continue

	// This loop has done its job
	// However, we need to decrease Y once, for the next loop
	ld r16, -Y
	breq _parse_bin_u8_loop_2

_parse_bin_u8_loop_1_continue:
	// Check for validity
	call is_r16_binary_digit
	cpi r17, 1
	brne _parse_bin_u8_err_return

	rjmp _parse_bin_u8_loop_1

_parse_bin_u8_loop_2:
	ld r16, -Y
	// Check for a zero value, a start of the string
	cpi r16, 0
	breq _parse_bin_u8_ok_return // This loop has done its job
	
	// Not zero, ascii magic to get the real value
	andi r16, 0x0F

	// Are we at 2^0?
	cpi r19, 0
	breq _parse_bin_u8_skip_mult

	// Shift for the position value
	mov r20, r19

_inner_loop_parse_bin_u8_loop_2:
	lsl r16
	// Did we get a carry? error
	brcs _parse_bin_u8_err_return
	dec r20
	brne _inner_loop_parse_bin_u8_loop_2

_parse_bin_u8_skip_mult:
	// Add to r18
	add r18, r16

	// Did we get a carry? error
	brcs _parse_bin_u8_err_return

	inc r19 // We are one position farther now
	rjmp _parse_bin_u8_loop_2

_parse_bin_u8_ok_return:
	pop r20
	pop r19
	pop YL
	pop YH
	clr r17
	ret

_parse_bin_u8_err_return:
	pop r20
	pop r19
	pop YL
	pop YH
	ldi r17, 1
	ret

// Relative branch out of reach....
_parse_bin_u16_err_return_2:
	jmp _parse_bin_u16_err_return

// Parses the string in RAM, starting at where Y is pointing as a 16-bit binary number into r19 - r18.
// In the event of a failure, r17 will have a non-zero (1) value
//
// Does not modify Y
parse_bin_string_Y_ram_as_u16:
	clr r18
	push YH
	push YL
	push r20 // r20 will be our counter for which position we are from the back
	push r21 // temp value
	push r23 // r24 - r23 is a temporary 16 bit value used in shifting
	push r24
	ldi r19, 0
	ldi r20, 0
	ldi r21, 0
	ldi r23, 0
	ldi r24, 0
	// Check for non empty input string
	ld r16, Y
	cpi r16, 0
	breq _parse_bin_u16_err_return_2

// First part of the loop: find the end and check that it is just numbers
_parse_bin_u16_loop_1:
	ld r16, Y+ 
	// Check for a zero value, an end of the string
	cpi r16, 0
	brne _loop_bin_u16_1_continue

	// This loop has done its job
	// However, we need to decrease Y once, for the next loop
	ld r16, -Y
	breq _parse_bin_u16_loop_2

_loop_bin_u16_1_continue:
	// Check for numeric value
	call is_r16_binary_digit
	cpi r17, 1
	brne _parse_bin_u16_err_return

	rjmp _parse_bin_u16_loop_1

_parse_bin_u16_loop_2:
	ld r16, -Y
	// Check for a zero value, a start of the string
	cpi r16, 0
	breq _parse_bin_u16_ok_return // This loop has done its job
	
	// Not zero, ascii magic to get the real value
	andi r16, 0x0F

	// Are we at 2^0?
	cpi r20, 0
	breq _skip_mult_bin_u16

	// Shift for the position value
	mov r21, r20

	// Move r16 into r24 - r23, to have a shift loop
	mov r23, r16
	clr r16
	clr r24 // Clear the top of the temp u16

_inner_loop_parse_bin_u16_loop_2:
	// Shift our number left
	lsl r23
	rol r24

	dec r21
	brne _inner_loop_parse_bin_u16_loop_2
	// Add the result of r24 - r23 to r19 - r18
	add r18, r23
	adc r19, r24
	rjmp _after_add_bin_u16

_skip_mult_bin_u16:
	// Add to r19 - r18
	add r18, r16
	// Note: we know r20 is 0, we checked before
	adc r19, r20
	rjmp _after_add_bin_u16

_after_add_bin_u16:
	// Did we get a carry? error
	brcs _parse_bin_u16_err_return

	inc r20 // We are one position farther now
	rjmp _parse_bin_u16_loop_2

_parse_bin_u16_ok_return:
	pop r24
	pop r23
	pop r21
	pop r20
	pop YL
	pop YH
	clr r17
	ret

_parse_bin_u16_err_return:
	pop r24
	pop r23
	pop r21
	pop r20
	pop YL
	pop YH
	ldi r17, 1
	ret
