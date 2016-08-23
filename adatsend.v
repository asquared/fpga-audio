`timescale 1ns / 1ps
/*
 * Copyright (c) 2016 Andrew H. Armenia.
 * Permission is hereby granted, free of charge, to any person obtaining a 
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of the Software, and to permit persons to whom the 
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */


/*
 * A basic ADAT transmitter. Uses 8x oversampled clock with shift_enable
 * signal to permit generating a signal with (roughly) same timing as 
 * an input signal.
 *
 * This transmitter uses a shift register that is loaded from the data_frame
 * input bus every 256 bit times. The frame_sync signal indicates that the 
 * data_frame signals have been latched in and transmission of a new frame
 * is beginning. NRZi encoding is included in this module but a raw ADAT
 * frame is expected as input.
 *
 * Inputs:
 *
 *  clk8x: Nominal 8x bit clock. For 48khz ADAT this is 98.304 MHz.
 *  shift_enable: For a free-running transmitter, pulse high every 8 cycles.
 *   To synchronize the transmitter to a receiver, connect the "sample_valid"
 *   signal from the reclocker module.
 *  data_frame[255:0]: ADAT data frame, shifted out MSB first.
 *
 * Outputs:
 *  sdo: serial data output. Connect to external fiber optic TX.
 *  frame_sync: goes high for 1 cycle after the data_frame has been loaded
 *  into the transmit shift register
 */
module adatsend(clk8x, data_frame, shift_enable, sdo, frame_sync);
	input wire clk8x;
	input wire [255:0] data_frame;
	input wire shift_enable;
	output reg sdo;
	output reg frame_sync;
	
	reg [255:0] shift_out = 256'd0;
	reg [7:0] bit_count = 8'd0;	
	
	
	always @ (posedge clk8x) begin
		frame_sync <= 0;
		if (shift_enable) begin
			// do a load every 256 bits, otherwise shift
			if (bit_count == 0) begin
				shift_out <= data_frame;
				
				// drive frame_sync high for one cycle after we load
				frame_sync <= 1;
			end
			else begin
				shift_out[255:1] <= shift_out[254:0];
			end
			
			// NRZi encode
			sdo <= sdo ^ shift_out[255];
			
			bit_count <= bit_count + 1;
		end
	end
endmodule
