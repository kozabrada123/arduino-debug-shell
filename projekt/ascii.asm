/*
 * ascii.asm
 *
 *  Created: 09/12/2024 14:06:00
 *   Author: Natan Jurca
 */ 

/// Helper things for ascii
// Ascii table
// Source: https://www.asciitable.com/
.equ null = 0x0
.equ backspace = 0x8
.equ tab = 0x9
.equ newline = 0x0a
.equ escape = 0x1b
.equ space = 0x20
.equ zero = 0x30
.equ nine = 0x39
.equ upper_a = 0x41
.equ upper_z = 0x5a
.equ lower_a = 0x61
.equ lower_z = 0x7a
.equ enter = 0x0d
.equ delete = 0x7F

/// Returns (in r17) whether r16 is between A and Z
is_r16_uppercase_letter:
	cpi r16, upper_a
	brlo _set_r17_false_and_ret
	cpi r16, upper_z
	breq _set_r17_true_and_ret
	brlo _set_r17_true_and_ret
	rjmp _set_r17_false_and_ret

/// Returns (in r17) whether r16 is between a and z
is_r16_lowercase_letter:
	cpi r16, lower_a
	brlo _set_r17_false_and_ret
	cpi r16, lower_z
	breq _set_r17_true_and_ret
	brlo _set_r17_true_and_ret
	rjmp _set_r17_false_and_ret

/// Returns (in r17) whether r16 is between 0 and 9
is_r16_number:
	cpi r16, zero
	brlo _set_r17_false_and_ret
	cpi r16, nine
	breq _set_r17_true_and_ret
	brlo _set_r17_true_and_ret
	rjmp _set_r17_false_and_ret

/// Returns (in r17) whether r16 is between 0 and 9, A and Z or a and z
is_r16_alphanumeric:
	call is_r16_uppercase_letter
	cpi r17, 1
	breq _set_r17_true_and_ret
	call is_r16_lowercase_letter
	cpi r17, 1
	breq _set_r17_true_and_ret
	call is_r16_number
	cpi r17, 1
	breq _set_r17_true_and_ret
	rjmp _set_r17_false_and_ret

/// Turns an ascii character in r16 into lowercase
make_r16_lowercase:
	call is_r16_uppercase_letter
	cpi r17, 0
	breq _ret
	ldi r17, 0x20
	add r16, r17
	ret

_ret:
	ret

_set_r17_true_and_ret:
	ldi r17, 1
	ret

_set_r17_false_and_ret:
	ldi r17, 0
	ret