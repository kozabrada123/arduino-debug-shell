;
; projekt.asm
;
; Created: 09/12/2024 12:51:47
; Author : Natan Jurca
;

// Interrupti
.org 0x0000
RESET: rjmp setup
.org 0x0033

// Knjižnica, da ni treba ro?no implementirati serijca
.include "knjiznica.asm"
.include "ascii.asm"
.include "string_stack.asm"

setup:
	call setupUART

	ldi ZH, high(greet_string<<1)
	ldi ZL, low(greet_string<<1)

	call printstring

	call print_newline_and_starting

	// Check if debug is enabled
	ldi ZH, high(debug<<1)
	ldi ZL, low(debug<<1)
	lpm r16, Z
	tst r16
	brne main_debug

	rjmp main

main:		
	call get_char
	call evaluate_character
	rjmp main

// Called when we receive a character in the main loop
//
// Character will be in r16
evaluate_character:
	// Enter
	cpi r16, enter
	brne _1
	call execute_command
	ret
_1:
	// Space
	cpi r16, space
	brne _2
	// Send space back
	call send_char
_2:
	// Backspace
	cpi r16, backspace
	brne _3
	call send_char
	// Send space and backspace to clear it - dirty hack
	ldi r16, space
	call send_char
	ldi r16, backspace
	call send_char
_3:
	call is_r16_alphanumeric
	cpi r17, 0
	breq _4
	call make_r16_lowercase
	// push to the string stack
	call string_stack_push
	// print it back
	call send_char
_4:
	ret

// Evaluates / executes the current command
execute_command:
	// Push a string end to the string stack
	clr r16
	call string_stack_push
	// TODO: logic
	// Aftermath: print a newline and starting string
	call print_newline_and_starting
	ret

// Prints a new line and the starting prompt
print_newline_and_starting:
	ldi r16, newline
	call send_char
	ldi ZH, high(starting_string<<1)
	ldi ZL, low(starting_string<<1)
	call printstring
	ret

// Main, if debug is enabled
main_debug:		
	call get_char
	// Echo it back in hex
	call send_hex

	ldi r16, space
	call send_char

	rjmp main_debug

end:
	rjmp end

// Debug mode: if 1, print ascii codes back into serial
//			   if 0, normal functionality
debug:
	.db 0

// Strings
/// Printed when starting the connection
greet_string:
	.db "Beep boop, boop beep?", 0

/// Printed after each command, on each new line
starting_string:				
	.db "> ", 0