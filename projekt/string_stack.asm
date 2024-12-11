/*
 * string_stack.asm
 *
 *  Created: 09/12/2024 15:57:15
 *   Author: Natan Jurca
 */ 

// Implementation of a home brewed stack, with the X register as a stack pointer
string_stack_reset:
	ldi XH, HIGH(0x0100)
	ldi XL, LOW(0x0100)

// Pushes r16 onto the string stack
string_stack_push:
	st X+, r16
	ret

// Pops r16 from the string stack
string_stack_pop:
	ld r16, -X
	ret

// Pushes the string stack pointer (X) to the regular stack
string_stack_pointer_push:
	push XH
	push XL

// Pops the string stack pointer (X) from the regular stack
string_stack_pointer_pop:
	pop XL
	pop XH

// Returns, in r17, whether the string in RAM, starting at where Y is pointing and the string in flash, starting at where Z is pointing, equal
//
// Does not modify Y or Z
string_Y_ram_equals_Z_rom:
	push YH
	push YL
	push ZH
	push ZL
	push r16
	push r18
_seq_loop:
	ld r16, Y+ 
	lpm r18, Z+
	// Do they equal?
	cp r16, r18
	brne _seq_false
	// Are they 0?
	cpi r16, 0
	breq _seq_true
	rjmp _seq_loop

_seq_false:
	pop r18
	pop r16
	pop ZL
	pop ZH
	pop YL
	pop YH
	rjmp _set_r17_false_and_ret

_seq_true:
	pop r18
	pop r16
	pop ZL
	pop ZH
	pop YL
	pop YH
	rjmp _set_r17_true_and_ret

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
	// Check for numeric value
	call is_r16_number
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
	ldi r19, 0
	ldi r20, 0
	ldi r21, 0
	ldi r22, 0
	// Check for non empty input string
	ld r16, Y
	cpi r16, 0
	breq _parse_u16_err_return

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

	// Move r16 into r1 - r0, to have a mul loop
	mov r0, r16
	clr r16

_inner_loop_parse_u16_loop_2:
	mul r0, r22
	// TODO -- kaj ce so spodnji 0 in zgornji nekej? poglej si test 2999 vs test 3000
	dec r21
	brne _inner_loop_parse_u16_loop_2
	// Add the result of r1 - r0 to r19 - r18
	add r18, r0
	adc r19, r1
	rjmp _after_add_u16

_skip_mult_u16:
	// Add to r19 - r18
	add r18, r16
	// Note: we know r20 is 0, we checked before
	adc r19, r20
	rjmp _after_add

_after_add_u16:
	// Did we get a carry? error
	brcs _parse_u16_err_return

	inc r20 // We are one position farther now
	rjmp _parse_u16_loop_2

_parse_u16_ok_return:
	pop r22
	pop r21
	pop r20
	pop YL
	pop YH
	clr r17
	ret

_parse_u16_err_return:
	pop r22
	pop r21
	pop r20
	pop YL
	pop YH
	ldi r17, 1
	ret
