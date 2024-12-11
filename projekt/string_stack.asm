/*
 * string_stack.asm
 *
 *  Created: 09/12/2024 15:57:15
 *   Author: Natan Jurca
 */ 

// Implementation of a home brewed stack, with the X register as a stack pointer
// Instead of the real stack we count forwards from 0x0100

// Resets the string stack pointer to the beginning
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
