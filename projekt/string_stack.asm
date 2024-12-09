/*
 * string_stack.asm
 *
 *  Created: 09/12/2024 15:57:15
 *   Author: User
 */ 

// Implementation of a home brewed stack, with the X register as a stack pointer
initialize_string_stack:
	ldi XH, HIGH(0x0100)
	ldi XL, LOW(0x0100)

// Pushes r16 onto the string stack
string_stack_push:
	st X+, r16
	ret

// Pops r16 from the string stack
string_stack_pop:
	ld r16, X
	// FIXME
	push r16
	ld r16, -X
	pop r16
	ret