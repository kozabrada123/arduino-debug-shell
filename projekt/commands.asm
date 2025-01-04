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

// Reads a pin in a limited set of i/o registers
// Sytax: inbit <portb/portc/portd/pinb/pinc/pind/ddrb/ddrc/ddrd> <bit, 0 - 7>
inbit_command:
	// Match strings
	// Start of 0x0101 + 5 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x0107)
	ldi YL, LOW(0x0107)

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
	ldi YH, HIGH(0x0107)
	ldi YL, LOW(0x0107)

	// Compare:
	// is it port?
	ldi ZH, HIGH(port_string << 1)
	ldi ZL, LOW(port_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _inbit_is_it_pin
	rjmp _inbit_port

_inbit_is_it_pin:

	// is it pin?
	ldi ZH, HIGH(pin_string << 1)
	ldi ZL, LOW(pin_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _inbit_is_it_ddr
	rjmp _inbit_pin

_inbit_is_it_ddr:

	// is it ddr?
	ldi ZH, HIGH(ddr_string << 1)
	ldi ZL, LOW(ddr_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _inbit_invalid_register
	rjmp _inbit_ddr

_inbit_invalid_register:
	// Print invalid argument
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(invalid_port_pin_ddr_string << 1)
	ldi ZL, LOW(invalid_port_pin_ddr_string  << 1)
	call printstring
	rjmp command_return

_inbit_parse_error:
	// Print parse error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u8_parse_failed_string << 1)
	ldi ZL, LOW(u8_parse_failed_string  << 1)
	call printstring
	rjmp command_return

_inbit_invalid_bit:
	// Print error for bit that isn't 0 - 7
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(not_0_to_7_string << 1)
	ldi ZL, LOW(not_0_to_7_string  << 1)
	call printstring
	rjmp command_return

_inbit_port:
	pop YL
	pop YH

	// Parse the pin number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 1
	breq _inbit_parse_error

	// r18 is now the parsed number
	// check if it's a valid pin number
	cpi r18, 8 // Note: 8 because we're testing < instead of <=
	brlt _inbit_port_ok
	rjmp _inbit_invalid_bit

_inbit_port_ok:

	// Okay, at this point we have:
	// r19 - b, c, or d
	// r18 - the bit (0 - 7)

	// Lets prepare the bitmask, in r21
	// r21 has to be the bitmask to &, so shift 0b1 r18 times
	ldi r21, 0b00000001

	// We'll need this for later, we'll need to shift something r18 times
	mov r20, r18 

_inbit_port_loop:
	cpi r18, 0
	breq _inbit_port_loop_end
	lsl r21
	dec r18
	rjmp _inbit_port_loop

_inbit_port_loop_end:

	// Cool, that's done
	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _inbit_portb
	cpi r19, lower_a+2 // c
	breq _inbit_portc
	cpi r19, lower_a+3 // d
	breq _inbit_portd

	// invalid character
	rjmp _inbit_invalid_register

_inbit_portb:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x05
	and r22, r21
	rjmp _inbit_finish

_inbit_portc:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x08
	and r22, r21
	rjmp _inbit_finish

_inbit_portd:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x0B
	and r22, r21
	rjmp _inbit_finish

_inbit_pin:
	pop YL
	pop YH

	// Parse the pin number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 1
	breq _inbit_parse_error

	// r18 is now the parsed number
	// check if it's a valid pin number
	cpi r18, 8 // Note: 8 because we're testing < instead of <=
	brlt _inbit_pin_ok
	rjmp _inbit_invalid_bit

_inbit_pin_ok:

	// Okay, at this point we have:
	// r19 - b, c, or d
	// r18 - the bit (0 - 7)

	// Lets prepare the bitmask, in r21
	// r21 has to be the bitmask to &, so shift 0b1 r18 times
	ldi r21, 0b00000001

	// We'll need this for later, we'll need to shift something r18 times
	mov r20, r18 

_inbit_pin_loop:
	cpi r18, 0
	breq _inbit_pin_loop_end
	lsl r21
	dec r18
	rjmp _inbit_pin_loop

_inbit_pin_loop_end:

	// Cool, that's done
	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _inbit_pinb
	cpi r19, lower_a+2 // c
	breq _inbit_pinc
	cpi r19, lower_a+3 // d
	breq _inbit_pind

	// invalid character
	rjmp _inbit_invalid_register

_inbit_pinb:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x03
	and r22, r21
	rjmp _inbit_finish

_inbit_pinc:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x06
	and r22, r21
	rjmp _inbit_finish

_inbit_pind:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x09
	and r22, r21
	rjmp _inbit_finish

_inbit_ddr:
	pop YL
	pop YH

	// Parse the pin number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 1
	brne _inbit_parse_ok
	rjmp _inbit_parse_error

_inbit_parse_ok:

	// r18 is now the parsed number
	// check if it's a valid pin number
	cpi r18, 8 // Note: 8 because we're testing < instead of <=
	brlt _inbit_ddr_ok
	rjmp _inbit_invalid_bit

_inbit_ddr_ok:

	// Okay, at this point we have:
	// r19 - b, c, or d
	// r18 - the bit (0 - 7)

	// Lets prepare the bitmask, in r21
	// r21 has to be the bitmask to &, so shift 0b1 r18 times
	ldi r21, 0b00000001

	// We'll need this for later, we'll need to shift something r18 times
	mov r20, r18 

_inbit_ddr_loop:
	cpi r18, 0
	breq _inbit_ddr_loop_end
	lsl r21
	dec r18
	rjmp _inbit_ddr_loop

_inbit_ddr_loop_end:

	// Cool, that's done
	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _inbit_ddrb
	cpi r19, lower_a+2 // c
	breq _inbit_ddrc
	cpi r19, lower_a+3 // d
	breq _inbit_ddrd

	// invalid character
	rjmp _inbit_invalid_register

_inbit_ddrb:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x04
	and r22, r21
	rjmp _inbit_finish

_inbit_ddrc:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x07
	and r22, r21
	rjmp _inbit_finish

_inbit_ddrd:
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x0A
	and r22, r21
	rjmp _inbit_finish

_inbit_finish:
	// Now we have the value in r22
	// As a finishing touch, shift it so we output only 0 or 1

	// We saved the bit into r20
	cpi r20, 0
	breq _inbit_fin_loop_end
	lsr r22
	dec r20
	rjmp _inbit_finish

_inbit_fin_loop_end:
	ldi r16, newline
	call send_char
	mov r16, r22
	call send_hex
	rjmp command_return

// Sets a pin in a limited set of i/o registers
// Sytax: outbit <portb/portc/portd/pinb/pinc/pind/ddrb/ddrc/ddrd> <bit, 0 - 7> <value: 0 or 1>
outbit_command:
	// Match strings
	// Start of 0x0101 + 6 for length of command + 1 for null bit; should be the starting location of the first argument 
	ldi YH, HIGH(0x0108)
	ldi YL, LOW(0x0108)

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
	ldi YH, HIGH(0x0108)
	ldi YL, LOW(0x0108)

	// Compare:
	// is it port?
	ldi ZH, HIGH(port_string << 1)
	ldi ZL, LOW(port_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _outbit_is_it_pin
	rjmp _outbit_port

_outbit_is_it_pin:

	// is it pin?
	ldi ZH, HIGH(pin_string << 1)
	ldi ZL, LOW(pin_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _outbit_is_it_ddr
	rjmp _outbit_pin

_outbit_is_it_ddr:

	// is it ddr?
	ldi ZH, HIGH(ddr_string << 1)
	ldi ZL, LOW(ddr_string  << 1)
	call string_Y_ram_equals_Z_rom
	cpi r17, 1
	brne _outbit_invalid_register
	rjmp _outbit_ddr

_outbit_invalid_register:
	// Print invalid argument
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(invalid_port_pin_ddr_string << 1)
	ldi ZL, LOW(invalid_port_pin_ddr_string  << 1)
	call printstring
	rjmp command_return

_outbit_parse_error:
	// Print parse error
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(u8_parse_failed_string << 1)
	ldi ZL, LOW(u8_parse_failed_string  << 1)
	call printstring
	rjmp command_return

_outbit_invalid_value:
	// Print error for value that isn't 1 or 0
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(not_bool_string << 1)
	ldi ZL, LOW(not_bool_string  << 1)
	call printstring
	rjmp command_return

_outbit_invalid_bit:
	// Print error for bit that isn't 0 - 7
	ldi r16, newline
	call send_char
	ldi ZH, HIGH(not_0_to_7_string << 1)
	ldi ZL, LOW(not_0_to_7_string  << 1)
	call printstring
	rjmp command_return

_outbit_port:
	pop YL
	pop YH

	// Parse the pin number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 1
	breq _outbit_parse_error

	// r18 is now the parsed number
	// check if it's a valid pin number
	cpi r18, 8 // Note: 8 because we're testing < instead of <=
	brlt _outbit_port_ok
	rjmp _outbit_invalid_bit

_outbit_port_ok:

	// Move it to r20, so we can call the parser again
	mov r20, r18

	// Find the start of the next argument
	// Note that we're currently at the start of the second one
	call find_next_string_end_Y_ram
	// At the end of the second one
	ld r16, Y+
	// At the start of the third

	// call the parser
	clr r17
	clr r18
	call parse_bin_string_Y_ram_as_u8
	cpi r17, 1
	breq _outbit_parse_error

	// r18 is now the parsed number
	// check if it's 0 or 1
	cpi r18, 0
	breq _outbit_port_ok_2
	cpi r18, 1
	breq _outbit_port_ok_2
	rjmp _outbit_invalid_value

_outbit_port_ok_2:

	// Okay, at this point we have:
	// r18 - the value (0 or 1)
	// r19 - b, c, or d
	// r20 - the bit (0 - 7)

	// Lets prepare the value to set, in r18, and the bitmask, in r21
	// r21 has to be the bitmask to &, so shift 0b1111110 r20 times as well
	ldi r21, 0b11111110

	// Shift r18 and r21 left r20 times
_outbit_port_loop:
	cpi r20, 0
	breq _outbit_port_loop_end
	lsl r18
	rol r21
	dec r20
	rjmp _outbit_port_loop

_outbit_port_loop_end:

	// Cool, that's done
	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _outbit_portb
	cpi r19, lower_a+2 // c
	breq _outbit_portc
	cpi r19, lower_a+3 // d
	breq _outbit_portd

	// invalid character
	rjmp _outbit_invalid_register

_outbit_portb:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x05
	and r22, r21
	or r22, r18
	out 0x05, r22
	rjmp _outbit_fin

_outbit_portc:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x08
	and r22, r21
	or r22, r18
	out 0x08, r22
	rjmp _outbit_fin

_outbit_portd:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x0B
	and r22, r21
	or r22, r18
	out 0x0B, r22
	rjmp _outbit_fin

_outbit_pin:
	pop YL
	pop YH

	// Parse the pin number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 0
	breq _outbit_parser_ok_1
	rjmp _outbit_parse_error

_outbit_parser_ok_1:

	// r18 is now the parsed number
	// check if it's a valid pin number
	cpi r18, 8 // Note: 8 because we're testing < instead of <=
	brlt _outbit_pin_ok
	rjmp _outbit_invalid_bit

_outbit_pin_ok:

	// Move it to r20, so we can call the parser again
	mov r20, r18

	// Find the start of the next argument
	// Note that we're currently at the start of the second one
	call find_next_string_end_Y_ram
	// At the end of the second one
	ld r16, Y+
	// At the start of the third

	// call the parser
	clr r17
	clr r18
	call parse_bin_string_Y_ram_as_u8
	cpi r17, 0
	breq _outbit_parser_ok_2
	rjmp _outbit_parse_error

_outbit_parser_ok_2:

	// r18 is now the parsed number
	// check if it's 0 or 1
	cpi r18, 0
	breq _outbit_pin_ok_2
	cpi r18, 1
	breq _outbit_pin_ok_2
	rjmp _outbit_invalid_value

_outbit_pin_ok_2:

	// Okay, at this point we have:
	// r18 - the value (0 or 1)
	// r19 - b, c, or d
	// r20 - the bit (0 - 7)

	// Lets prepare the value to set, in r18, and the bitmask, in r21
	// r21 has to be the bitmask to &, so shift 0b1111110 r20 times as well
	ldi r21, 0b11111110

	// Shift r18 and r21 left r20 times
_outbit_pin_loop:
	cpi r20, 0
	breq _outbit_pin_loop_end
	lsl r18
	rol r21
	dec r20
	rjmp _outbit_pin_loop

_outbit_pin_loop_end:

	// Cool, that's done
	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _outbit_pinb
	cpi r19, lower_a+2 // c
	breq _outbit_pinc
	cpi r19, lower_a+3 // d
	breq _outbit_pind

	// invalid character
	rjmp _outbit_invalid_register

_outbit_pinb:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x03
	and r22, r21
	or r22, r18
	out 0x03, r22
	rjmp _outbit_fin

_outbit_pinc:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x06
	and r22, r21
	or r22, r18
	out 0x06, r22
	rjmp _outbit_fin

_outbit_pind:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x09
	and r22, r21
	or r22, r18
	out 0x09, r22
	rjmp _outbit_fin

_outbit_ddr:
	pop YL
	pop YH

	// Parse the pin number
	// We moved Y to the null termination before this argument starts, so just increment it once
	ld r16, Y+

	// call the parser
	clr r17
	call parse_hex_string_Y_ram_as_u8
	cpi r17, 0
	breq _outbit_parser_ok_4
	rjmp _outbit_parse_error

_outbit_parser_ok_4:

	// r18 is now the parsed number
	// check if it's a valid pin number
	cpi r18, 8 // Note: 8 because we're testing < instead of <=
	brlt _outbit_ddr_ok
	rjmp _outbit_invalid_bit

_outbit_ddr_ok:

	// Move it to r20, so we can call the parser again
	mov r20, r18

	// Find the start of the next argument
	// Note that we're currently at the start of the second one
	call find_next_string_end_Y_ram
	// At the end of the second one
	ld r16, Y+
	// At the start of the third

	// call the parser
	clr r17
	clr r18
	call parse_bin_string_Y_ram_as_u8
	cpi r17, 0
	breq _outbit_parser_ok_3
	rjmp _outbit_parse_error

_outbit_parser_ok_3:

	// r18 is now the parsed number
	// check if it's 0 or 1
	cpi r18, 0
	breq _outbit_ddr_ok_2
	cpi r18, 1
	breq _outbit_ddr_ok_2
	rjmp _outbit_invalid_value

_outbit_ddr_ok_2:

	// Okay, at this point we have:
	// r18 - the value (0 or 1)
	// r19 - b, c, or d
	// r20 - the bit (0 - 7)

	// Lets prepare the value to set, in r18, and the bitmask, in r21
	// r21 has to be the bitmask to &, so shift 0b1111110 r20 times as well
	ldi r21, 0b11111110

	// Shift r18 and r21 left r20 times
_outbit_ddr_loop:
	cpi r20, 0
	breq _outbit_ddr_loop_end
	lsl r18
	rol r21
	dec r20
	rjmp _outbit_ddr_loop

_outbit_ddr_loop_end:

	// Cool, that's done
	// Now match r19 for b, c or d
	cpi r19, lower_a+1 // b
	breq _outbit_ddrb
	cpi r19, lower_a+2 // c
	breq _outbit_ddrc
	cpi r19, lower_a+3 // d
	breq _outbit_ddrd

	// invalid character
	rjmp _outbit_invalid_register

_outbit_ddrb:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x04
	and r22, r21
	or r22, r18
	out 0x04, r22
	rjmp _outbit_fin

_outbit_ddrc:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)

	mov r16, r18
	call send_hex
	mov r16, r21
	call send_hex

	in r22, 0x07
	and r22, r21
	or r22, r18
	out 0x07, r22
	rjmp _outbit_fin

_outbit_ddrd:
	// r18 has the value at the right bits (to | with)
	// r21 has the bitmask to & with (e.g. 11111110 to set the value of bit 0)
	in r22, 0x0A
	and r22, r21
	or r22, r18
	out 0x0A, r22
	rjmp _outbit_fin

_outbit_fin:
	rjmp command_return