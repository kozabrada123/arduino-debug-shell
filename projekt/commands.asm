/*
 * commands.asm
 *
 *  Created: 11/12/2024 11:15:13
 *   Author: Natan Jurca
 */ 

// Contains commands for easier viewing and editing
// After doing their thing, they should jump to command_return

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

// Prints the help text
help_command:
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(help_string << 1)
	ldi ZL, LOW(help_string  << 1)
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

// Tests int parsing and converts a decimal number in hex
dec_to_hex_command:
	push YH
	push YL
	// Start of 0x0101 + 8 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x010A)
	ldi YL, LOW(0x010A)
	clr r17
	call parse_string_Y_ram_as_u16
	pop YL
	pop YH
	cpi r17, 1
	breq _dthc_error
	rjmp _dthc_ok
_dthc_error:
	// Error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u16_parse_failed_string<<1)
	ldi ZL, LOW(u16_parse_failed_string<<1)
	call printstring
	rjmp command_return

_dthc_ok:
	// Ok
	ldi r16, newline
	call send_char
	// Send the output
	mov r16, r19
	call send_hex
	mov r16, r18
	call send_hex
	rjmp command_return

// Tests int parsing
parse_hex_command:
	push YH
	push YL
	// Start of 0x0101 + 8 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x010A)
	ldi YL, LOW(0x010A)
	clr r17
	call parse_hex_string_Y_ram_as_u16
	pop YL
	pop YH
	cpi r17, 1
	breq _hthc_error
	rjmp _hthc_ok
_hthc_error:
	// Error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u16_parse_failed_string<<1)
	ldi ZL, LOW(u16_parse_failed_string<<1)
	call printstring
	rjmp command_return

_hthc_ok:
	// Ok
	ldi r16, newline
	call send_char
	// Send the output
	mov r16, r19
	call send_hex
	mov r16, r18
	call send_hex
	rjmp command_return

// Tests int parsing and turns a binary number into a hex one
bin_to_hex_command:
	push YH
	push YL
	// Start of 0x0101 + 8 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x010A)
	ldi YL, LOW(0x010A)
	clr r17
	call parse_bin_string_Y_ram_as_u16
	pop YL
	pop YH
	cpi r17, 1
	breq _bthc_error
	rjmp _bthc_ok
_bthc_error:
	// Error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u16_parse_failed_string<<1)
	ldi ZL, LOW(u16_parse_failed_string<<1)
	call printstring
	rjmp command_return

_bthc_ok:
	// Ok
	ldi r16, newline
	call send_char
	// Send the output
	mov r16, r19
	call send_hex
	mov r16, r18
	call send_hex
	rjmp command_return