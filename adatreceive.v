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
 * ADAT receiver. Also provides the recovered "clock" as output.
 *
 * Inputs:
 *  clk8x: clock at 8x the nominal ADAT bit rate (12.288MHz x 8 = 98.304 MHz)
 *  sdi: serial data input
 *
 * Outputs:
 *  ch1..ch8: 24-bit PCM data for each channel
 *  frame_sync: goes high for one clk8x cycle when a valid sync pattern
 *   is received
 *  bit_sync: recovered clock from ADAT input
 */
module adatreceive(clk8x, sdi, frame_sync, bit_sync,
	ch1, ch2, ch3, ch4,
	ch5, ch6, ch7, ch8);

	input wire clk8x;
	input wire sdi;

	output reg frame_sync;
	output wire bit_sync;
	output reg [23:0] ch1;
	output reg [23:0] ch2;
	output reg [23:0] ch3;
	output reg [23:0] ch4;
	output reg [23:0] ch5;
	output reg [23:0] ch6;
	output reg [23:0] ch7;
	output reg [23:0] ch8;

	reg [7:0] bitpos = 8'd0;
	reg [28:0] shiftreg;
	reg prevbit;
	wire [23:0] sample;
	wire [23:0] rsample;
	wire sdi_reclocked;
	wire found_sync_pattern;

	// remove the stuffed bits
	assign sample[23:20] = shiftreg[28:25];
	assign sample[19:16] = shiftreg[23:20];
	assign sample[15:12] = shiftreg[18:15];
	assign sample[11:8]  = shiftreg[13:10];
	assign sample[7:4]   = shiftreg[8:5];
	assign sample[3:0]   = shiftreg[3:0];

	genvar i;
	generate
		for (i = 0; i < 24; i = i + 1) begin
			assign rsample[i] = sample[23-i];
		end
	endgenerate

	// obtain a bit sync signal
	adatreclock reclocker(
		.clk(clk8x),
		.sdi(sdi),
		.sample(sdi_reclocked),
		.sample_valid(bit_sync)
	);

	// sync pattern is ten zeroes. The following 1 will be considered
	// bit zero of the frame.
	assign found_sync_pattern =
		(shiftreg[28:19] == 10'b0000000000);

	always @ (posedge clk8x) begin
		frame_sync <= 0;

		// shift in a bit at the right time
		if (bit_sync) begin
			prevbit <= sdi_reclocked;
			shiftreg[28] <= sdi_reclocked ^ prevbit;
			shiftreg[27:0] <= shiftreg[28:1];

			if (found_sync_pattern) begin
				frame_sync <= 1;
				bitpos <= 0;
			end
			else begin
				bitpos <= bitpos + 1;
			end
		end

		case (bitpos)
			8'd34: ch1 <= rsample;
			8'd64: ch2 <= rsample;
			8'd94: ch3 <= rsample;
			8'd124: ch4 <= rsample;
			8'd154: ch5 <= rsample;
			8'd184: ch6 <= rsample;
			8'd214: ch7 <= rsample;
			8'd244: ch8 <= rsample;
		endcase
	end
endmodule
