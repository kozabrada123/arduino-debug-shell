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

// Tests int parsing and turns a binary number into a hex one
bin_to_hex_command:
	push YH
	push YL
	// Start of 0x0101 + 8 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x010A)
	ldi YL, LOW(0x010A)
	clr r17
	call parse_bin_string_Y_ram_as_u8
	pop YL
	pop YH
	cpi r17, 1
	breq _bthc_error
	rjmp _bthc_ok
_bthc_error:
	// Error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u8_parse_failed_string<<1)
	ldi ZL, LOW(u8_parse_failed_string<<1)
	call printstring
	rjmp command_return

_bthc_ok:
	// Ok
	ldi r16, newline
	call send_char
	// Send the output
	mov r16, r18
	call send_hex
	rjmp command_return

// Tests int parsing and turns a hex number into a binary one
hex_to_bin_command:
	push YH
	push YL
	// Start of 0x0101 + 8 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x010A)
	ldi YL, LOW(0x010A)
	clr r17
	call parse_hex_string_Y_ram_as_u8
	pop YL
	pop YH
	cpi r17, 1
	breq _htbc_error
	rjmp _htbc_ok
_htbc_error:
	// Error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u8_parse_failed_string<<1)
	ldi ZL, LOW(u8_parse_failed_string<<1)
	call printstring
	rjmp command_return

_htbc_ok:
	// Ok
	ldi r16, newline
	call send_char
	// Send the output
	mov r16, r18
	call send_bin
	rjmp command_return

// Reads and prints a limited set of i/o registers
// Sytax: in <portb/portc/portd/pinb/pinc/pind/ddrb/ddrc/ddrd>
in_command:
	// Match strings
	// Start of 0x0101 + 2 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x0104)
	ldi YL, LOW(0x0104)

	// Lets do some terribleness!
	// save the last character (which is hopefully b/c/d) into r18 and replace it with a zero byte, so we'll only compare up to there
	// null byte
	call string_stack_pop
	// last character
	call string_stack_pop
	mov r18, r16
	// Replace with 0 byte
	clr r16
	call string_stack_push

	// Compare:
	// is it port?
	ldi ZH, HIGH(port_string << 1)
	ldi ZL, LOW(port_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq _in_port

	// is it pin?
	ldi ZH, HIGH(pin_string << 1)
	ldi ZL, LOW(pin_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq _in_pin

	// is it ddr?
	ldi ZH, HIGH(ddr_string << 1)
	ldi ZL, LOW(ddr_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq _in_ddr

_in_invalid:
	// Print invalid argument
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(invalid_port_pin_ddr_string << 1)
	ldi ZL, LOW(invalid_port_pin_ddr_string  << 1)
	call printstring
	rjmp command_return

_in_port:
	// Now match r18 for b, c or d
	cpi r18, lower_a+1 // b
	breq _in_portb
	cpi r18, lower_a+2 // c
	breq _in_portc
	cpi r18, lower_a+3 // d
	breq _in_portd

	// invalid character
	rjmp _in_invalid

_in_pin:
	// Now match r18 for b, c or d
	cpi r18, lower_a+1 // b
	breq _in_pinb
	cpi r18, lower_a+2 // c
	breq _in_pinc
	cpi r18, lower_a+3 // d
	breq _in_pind

	// invalid character
	rjmp _in_invalid

_in_ddr:
	// Now match r18 for b, c or d
	cpi r18, lower_a+1 // b
	breq _in_ddrb
	cpi r18, lower_a+2 // c
	breq _in_ddrc
	cpi r18, lower_a+3 // d
	breq _in_ddrd

	// invalid character
	rjmp _in_invalid

_in_portb:
	in r16, 0x05
	rjmp _in_fin

_in_portc:
	in r16, 0x08
	rjmp _in_fin

_in_portd:
	in r16, 0x0B
	rjmp _in_fin

_in_pinb:
	in r16, 0x03
	rjmp _in_fin

_in_pinc:
	in r16, 0x06
	rjmp _in_fin

_in_pind:
	in r16, 0x09
	rjmp _in_fin

_in_ddrb:
	in r16, 0x04
	rjmp _in_fin

_in_ddrc:
	in r16, 0x07
	rjmp _in_fin

_in_ddrd:
	in r16, 0x0A
	rjmp _in_fin

_in_fin:
	mov r17, r16
	ldi r16, newline
	call send_char
	mov r16, r17
	// Send the output that is in r16
	call send_hex
	rjmp command_return

// Reads and prints a limited set of i/o registers
// Sytax: out <portb/portc/portd/pinb/pinc/pind/ddrb/ddrc/ddrd> <value: 00 to ff>
out_command:
	// Match strings
	// Start of 0x0101 + 3 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x0105)
	ldi YL, LOW(0x0105)

	// Find the end of this argument
	call find_next_string_end_Y_ram

	// Lets do some terribleness!
	// save the last character (which is hopefully b/c/d) into r19 and replace it with a zero byte, so we'll only compare up to there
	ld r19, -Y
	// Replace with 0 byte
	clr r16
	st Y+, r16

	// Move back to the start of the first agument
	push YH
	push YL
	ldi YH, HIGH(0x0105)
	ldi YL, LOW(0x0105)

	// Compare:
	// is it port?
	ldi ZH, HIGH(port_string << 1)
	ldi ZL, LOW(port_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq _out_port

	// is it pin?
	ldi ZH, HIGH(pin_string << 1)
	ldi ZL, LOW(pin_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq _out_pin

	// is it ddr?
	ldi ZH, HIGH(ddr_string << 1)
	ldi ZL, LOW(ddr_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	breq _out_ddr

_out_invalid:
	// Print invalid argument
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(invalid_port_pin_ddr_string << 1)
	ldi ZL, LOW(invalid_port_pin_ddr_string  << 1)
	call printstring
	rjmp command_return

_out_parse_error:
	// Print parse error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u8_parse_failed_string << 1)
	ldi ZL, LOW(u8_parse_failed_string  << 1)
	call printstring
	rjmp command_return

_out_port:
	pop YL
	pop YH

	// Parse the number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 1
	breq _out_parse_error
	// r18 is now the parsed number

	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _out_portb
	cpi r19, lower_a+2 // c
	breq _out_portc
	cpi r19, lower_a+3 // d
	breq _out_portd

	// invalid character
	rjmp _out_invalid

_out_pin:
	pop YL
	pop YH

	// Parse the number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 1
	breq _out_parse_error
	// r18 is now the parsed number

	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _out_pinb
	cpi r19, lower_a+2 // c
	breq _out_pinc
	cpi r19, lower_a+3 // d
	breq _out_pind

	// invalid character
	rjmp _out_invalid

_out_ddr:
	pop YL
	pop YH

	// Parse the number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 1
	breq _out_parse_error
	// r18 is now the parsed number

	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _out_ddrb
	cpi r19, lower_a+2 // c
	breq _out_ddrc
	cpi r19, lower_a+3 // d
	breq _out_ddrd

	// invalid character
	rjmp _out_invalid

_out_portb:
	out 0x05, r18
	rjmp _out_fin

_out_portc:
	out 0x08, r18
	rjmp _out_fin

_out_portd:
	out 0x0B, r18
	rjmp _out_fin

_out_pinb:
	out 0x03, r18
	rjmp _out_fin

_out_pinc:
	out 0x06, r18
	rjmp _out_fin

_out_pind:
	out 0x09, r18
	rjmp _out_fin

_out_ddrb:
	out 0x04, r18
	rjmp _out_fin

_out_ddrc:
	out 0x07, r18
	rjmp _out_fin

_out_ddrd:
	out 0x0A, r18
	rjmp _out_fin

_out_fin:
	rjmp command_return