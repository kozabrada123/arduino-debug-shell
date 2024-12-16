/*
 * main.asm
 *
 * Created: 09/12/2024 12:51:47
 * Author : Natan Jurca
 */

// Interrupti
.org 0x0000
RESET: rjmp setup
.org 0x0034

// Knjižnica, da ni treba rocno implementirati serijca
.include "knjiznica.asm"
.include "ascii.asm"
.include "string_stack.asm"
.include "string_algorithms.asm"
.include "commands.asm"

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
	// Push it onto the string buffer / stack as a lowercase version of itself
	call make_r16_lowercase
	call string_stack_push
	// & send it back
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

	// Compare: is it a reset command?
	ldi ZH, HIGH(reset_command_string << 1)
	ldi ZL, LOW(reset_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	// Note: these jumps are done this way so the
	// jump to the command has a larger range
	//
	// If using breq, you have a range of +- 64
	// If using rjmp, you have a range of +- 2k
	// (You can also easily make it jmp)
	brne _after_reset
	rjmp reset_command

_after_reset:
	// Compare: is it a version command?
	ldi ZH, HIGH(version_command_string << 1)
	ldi ZL, LOW(version_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _after_version
	rjmp version_command

_after_version:
	// Compare: is it a help command?
	ldi ZH, HIGH(help_command_string << 1)
	ldi ZL, LOW(help_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _after_help
	rjmp help_command

_after_help:
	// Compare: is it a clear command?
	ldi ZH, HIGH(clear_command_string << 1)
	ldi ZL, LOW(clear_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _after_clear
	rjmp clear_command

_after_clear:
	// Compare: is it dectohex command?
	ldi ZH, HIGH(dec_to_hex_command_string << 1)
	ldi ZL, LOW(dec_to_hex_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _after_dec_to_hex
	rjmp dec_to_hex_command

_after_dec_to_hex:
	// Compare: is it bintohex command?
	ldi ZH, HIGH(bin_to_hex_command_string << 1)
	ldi ZL, LOW(bin_to_hex_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _after_bin_to_hex
	rjmp bin_to_hex_command

_after_bin_to_hex:
	// Compare: is it hextobin command?
	ldi ZH, HIGH(hex_to_bin_command_string << 1)
	ldi ZL, LOW(hex_to_bin_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _after_hex_to_bin
	rjmp hex_to_bin_command

_after_hex_to_bin:
	// Compare: is it in command?
	ldi ZH, HIGH(in_command_string << 1)
	ldi ZL, LOW(in_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _after_in
	rjmp in_command

_after_in:
	// Compare: is it out command?
	ldi ZH, HIGH(out_command_string << 1)
	ldi ZL, LOW(out_command_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _skip_command
	rjmp out_command

_skip_command:
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
	.db "| ", 0x22, "Science isn't about why, it's about why not!", 0x22, " - Cave Johnson |", newline, "| Arduino Debug Shell indev |", 0

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
	.db "| Failed to parse integer, please try again (range: 0 - 255) |", 0

u16_parse_failed_string:
	.db "| Failed to parse integer, please try again (range: 0 - 65535) |", 0

/// Help text
help_string:
	.db newline, "Commands:", newline, "| help | Prints this text", newline, "| reset | Acts like the reset interrupt", newline, "| version | Prints version information", newline, "| clear | Clears a messy screen", newline, "| dectohex [number] | Converts a decimal number into hexadecimal", newline, "| bintohex [number] | Converts a binary number into hexadecimal", newline, "| hextobin [number] | Converts a hexadecimal number into a binary one", newline, "| in [port(b/c/d) / pin(b/c/d) / ddr(b/c/d)] | Prints the hex value of port, pin or ddr registers", newline, "| out [port(b/c/d) / pin(b/c/d) / ddr(b/c/d)] [hex value: 00 to ff] | Sets the hex value of port, pin or ddr registers", newline, newline, "If you encounter a bug or need help, don't hesitate to contact me at 192.168.4.1 on Discord", newline, 0

// Strings for commands
reset_command_string:
	.db "reset", 0

version_command_string:
	.db "version", 0

help_command_string:
	.db "help", 0

clear_command_string:
	.db "clear", 0

dec_to_hex_command_string:
	.db "dectohex", 0

parse_hex_command_string:
	.db "parsehex", 0

bin_to_hex_command_string:
	.db "bintohex", 0

hex_to_bin_command_string:
	.db "hextobin", 0

in_command_string:
	.db "in", 0

out_command_string:
	.db "out", 0

port_string:
	.db "port", 0

ddr_string:
	.db "ddr", 0

pin_string:
	.db "pin", 0

invalid_port_pin_ddr_string:
	.db "| Invalid input, expected port(b/c/d), pin(b/c/d) or ddr(b/c/d) |", 0
