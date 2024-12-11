/*
 * projekt.asm
 *
 * Created: 09/12/2024 12:51:47
 * Author : Natan Jurca
 */

// Interrupti
.org 0x0000
RESET: rjmp setup
.org 0x0033

// Knjižnica, da ni treba rocno implementirati serijca
.include "knjiznica.asm"
.include "ascii.asm"
.include "string_stack.asm"

setup:
	call setupUART
	call string_stack_reset

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

// Main, if debug is enabled
main_debug:		
	call get_char
	// Echo it back in hex
	call send_hex

	ldi r16, space
	call send_char

	rjmp main_debug

main:		
	call get_char
	call evaluate_character
	rjmp main

// Called when we receive a character in the main loop
//
// Character will be in r16
evaluate_character:
	// null character
	cpi r16, 0
	breq _ec_ret

	// Enter
	cpi r16, enter
	brne _ec_space
	call execute_command
	ret
_ec_space:
	// Space
	cpi r16, space
	brne _ec_backspace
	// Send space back
	call send_char
	// Add a string end to the string stack, so we know there is a break for arguments
	clr r16
	call string_stack_push
	ret
_ec_backspace:
	// Backspace
	cpi r16, backspace
	brne _ec_alphanumeric
	// Remove one from our string buffer
	// Are we at the start?
	cpi XL, LOW(0x101)
	brne _ec_backspace_2
	cpi XH, HIGH(0x101)
	breq _ec_ret

_ec_backspace_2:
	call string_stack_pop
	// Only moves the cursor back
	ldi r16, backspace
	call send_char
	// Send space and backspace to clear it - dirty hack
	ldi r16, space
	call send_char
	ldi r16, backspace
	call send_char
	ret
_ec_alphanumeric:
	call is_r16_alphanumeric
	cpi r17, 0
	breq _ec_ret
	call make_r16_lowercase
	call string_stack_push
	call send_char
	ret
_ec_ret:
	ret

// Evaluates / executes the current command
execute_command:
	// Push a string termination to the string stack
	clr r16
	call string_stack_push

	// Initialize the pointer to the start of the string stack
	// that's where we store the 0th argument of the command, the command string
	ldi YH, HIGH(0x0101) // No idea why 0x0100 doesn't work, but this fixes it and it works perfectly now
	ldi YL, LOW(0x0101)

	// Compare: is it a hello command?
	ldi ZH, HIGH(hello_command_string << 1)
	ldi ZL, LOW(hello_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq hello_command

	// Compare: is it a reset command?
	ldi ZH, HIGH(reset_command_string << 1)
	ldi ZL, LOW(reset_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq reset_command

	// Compare: is it a version command?
	ldi ZH, HIGH(version_command_string << 1)
	ldi ZL, LOW(version_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq version_command

	// Compare: is it a clear command?
	ldi ZH, HIGH(clear_command_string << 1)
	ldi ZL, LOW(clear_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq clear_command

	// Compare: is it dec_to_hex command?
	ldi ZH, HIGH(dec_to_hex_command_string << 1)
	ldi ZL, LOW(dec_to_hex_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq dec_to_hex_command

	// No other command
	// Check if it is an empty command
	ld r16, Y
	cpi r16, 0
	breq command_return

	// Print the invalid command text
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(invalid_command_string << 1)
	ldi ZL, LOW(invalid_command_string  << 1)
	call printstring

// rjmp here after executing a command
command_return:
	// Clear the string buffer
	call string_stack_reset
	// Aftermath: print a newline and starting string
	call print_newline_and_starting
	ret

// Just prints a message back
hello_command:
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(hello_command_return_string << 1)
	ldi ZL, LOW(hello_command_return_string  << 1)
	call printstring
	rjmp command_return

// Calls the reset interrupt
reset_command:
	rjmp RESET

// Prints the current version
version_command:
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(version_string << 1)
	ldi ZL, LOW(version_string  << 1)
	call printstring
	rjmp command_return

// ""clears"" the screen
clear_command:
	ldi r17, 255
_clear_loop:
	ldi r16, newline
	call send_char
	dec r17
	brne _clear_loop
	rjmp command_return

// Tests int parsing
dec_to_hex_command:
	push YH
	push YL
	// Start of 0x0101 + 8 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x010A)
	ldi YL, LOW(0x010A)
	clr r17
	call parse_string_Y_ram_as_u8
	pop YL
	pop YH
	cpi r17, 1
	breq _dthc_error
	rjmp _dthc_ok
_dthc_error:
	// Error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u8_parse_failed_string<<1)
	ldi ZL, LOW(u8_parse_failed_string<<1)
	call printstring
	rjmp command_return

_dthc_ok:
	// Ok
	ldi r16, newline
	call send_char
	// Send the output
	mov r16, r18
	call send_hex
	rjmp command_return

// Prints a new line and the starting prompt
print_newline_and_starting:
	ldi r16, newline
	call send_char
	ldi ZH, high(starting_string<<1)
	ldi ZL, low(starting_string<<1)
	call printstring
	ret

end:
	rjmp end

// Debug mode: if 1, print ascii codes back into serial
//			   if 0, normal functionality
debug:
	.db 0

// Strings
/// Printed when starting the connection
greet_string:
	.db "| ", 0x22, "Science isn't about why, it's about why not!", 0x22, " | Arduino Debug Shell indev |", 0

version_string:
	.db "| Arduino Debug Shell | indev | last version change 10/12/24 |", 0

/// Printed after each command, on each new line
starting_string:
	.db "> ", 0

/// Printed when submitting an invalid command
invalid_command_string:
	.db "| Invalid or incomplete command, please try again |", 0

/// Printed when submitting an invalid number
u8_parse_failed_string:
	.db "| Failed to parse integer, please try again (0 - 255) |", 0

u16_parse_failed_string:
	.db "| Failed to parse integer, please try again (0 - 65535) |", 0

hello_command_string:
	.db "hello", 0

hello_command_return_string:
	.db "hi, human!", 0

reset_command_string:
	.db "reset", 0

version_command_string:
	.db "version", 0

clear_command_string:
	.db "clear", 0

dec_to_hex_command_string:
	.db "dectohex", 0