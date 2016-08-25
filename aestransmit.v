`timescale 1ns / 1ps

/*
 * An AES3 transmitter.
 *
 * Inputs:
 *  clk: The clock. This can be equal to the bit clock or higher.
 *   If it's equal, tie shift_en high.
 *   If it's higher, bring shift_en high on cycles where a bit should
 *   be shifted out.
 *  shift_en: Output shift register enable, see above.
 *  channel_a: 24-bit PCM data for channel A
 *  channel_b: 24-bit PCM data for channel B
 *
 * Outputs:
 *  sdo: serial data out
 *  frame_sync: goes high during the first clock cycle past the end of a frame
 */
module aestransmit(clk, shift_en, channel_a, channel_b, sdo, frame_sync);
	/* This one's a bit more complex than ADAT :/ */
	input wire clk;
	input wire shift_en;
	input wire [23:0] channel_a;
	input wire [23:0] channel_b;
	output reg sdo = 1'b0;
	output reg frame_sync = 1'b0;

	// in (frame, ch, bpos) terms these three are going to count thusly:
	// (0 0 0) - (0 0 1) - (0 0 2) - ... - (0 0 63)
	// (0 1 0) - (0 1 1) - (0 1 2) - ... - (0 1 63)
	// (1 0 0) - (1 0 1) - (1 0 2) - ... - (0 0 63)
	// (1 1 0) - (1 1 1) - (1 1 2) - ... - (0 1 63)
	// ...
	// (191 0 0) - (191 0 1) - (191 0 2) - ... - (191 0 63)
	// (191 1 0) - (191 1 1) - (191 1 2) - ... - (191 1 63)
	// (0 0 0) - (0 0 1) - (0 0 2) - ... - (0 0 63)
	// (0 1 0) - (0 1 1) - (0 1 2) - ... - (0 1 63)
	reg [7:0] frame = 8'b0;
	reg [5:0] bpos = 8'b0;
	reg ch = 0;
	reg parity = 0;

	/*
	 * state: 00 = send preamble, 01 = send "1", 10 = send data bit
	 * from shift reg. State is determined from bpos only.
	 */
	wire [1:0] state;

	/* state decode logic */
	assign state =
		(bpos < 8) ? 2'b00 :
		(bpos == 63) ? 2'b11 :
		(bpos[0] == 0) ? 2'b01 :
		2'b10;

	reg [26:0] shiftreg = 27'b0;

	wire outbit;
	assign outbit =
		(state == 2'b01) ? 1'b1 :
		(state == 2'b11) ? parity :
		shiftreg[0];

	wire [3:0] next_preamble;
	assign next_preamble =
		(ch == 0) ? 4'b0110 :
		(frame == 191) ? 4'b0011 :
		4'b1100;


	wire [23:0] chdata = ch ? channel_b : channel_a;

	wire chstatus;
	//assign chstatus = (frame == 0);
	assign chstatus = 1'b0;

	wire userdata;
	assign userdata = 1'b0;

	wire validity;
	assign validity = 1'b1;

	always @ (posedge clk) begin
		frame_sync <= 0;

		if (shift_en) begin
			bpos <= bpos + 6'd1;
			sdo <= sdo ^ outbit;

			case (state)
				2'b00: begin
					// if this is the last cycle of preamble,
					// load shift register and reset parity
					if (bpos == 5'd7) begin
						shiftreg <= {
							chstatus,
							userdata,
							validity,
							chdata
						};
						parity <= 0;
					end
					else begin
						shiftreg[25:0] <= shiftreg[26:1];
					end
				end
				2'b10: begin
					shiftreg[25:0] <= shiftreg[26:1];
					parity <= parity ^ shiftreg[0];
				end
				2'b11: begin
					// send parity bit (bpos == 63) and load next preamble
					shiftreg <= { 20'b0, next_preamble, 4'b1001 };

					// advance channel and frame
					ch <= !ch;
					if (ch) begin
						// at end of each audio frame pulse frame_sync high
						frame_sync <= 1;
						frame <= (frame == 191) ? 8'd0 : frame+8'd1;
					end
				end
			endcase
		end
	end
endmodule
