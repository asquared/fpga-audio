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
 * Oversampling reclocker for ADAT Lightpipe
 * (and probably applicable to other types of NRZ/NRZI data)
 *
 * This reclocker resynchronizes at each edge of the incoming ADAT signal.
 * In a valid ADAT signal, the longest run with no edges is 10 bit times,
 * or 10 UI. Ideally the transmit and receive clocks should drift apart by 
 * no more than 0.125 UI during this time, or 1.25%. Most typical crystal
 * oscillators should be capable of this level of performance.
 *
 * Edge detection is by means of the synchronizer flip-flops at the input.
 *
 * Inputs:
 *  clk: Clock signal at 8x the data rate (98.304 MHz for 48ksps ADAT)
 *  sdi: Serial data in (can be connected to external fiber optic RX)
 * Outputs:
 *  sample_valid: goes high during the clock cycle that
 *    the `sample` output is valid
 *  sample: data output (synchronized to sample_valid signal)
 */
module adatreclock(clk, sdi, sample, sample_valid);
	input wire clk;
	input wire sdi;
	output wire sample;
	output wire sample_valid;
	
	/* two flip-flops to synchronize the input */
	reg d1, d2;
	/* d2 contains the data sample when sample_timer reaches four */
	assign sample = d2;
		
	/*
  	 * this will be reset to zero at an edge, so it reaches four (3'b100) 
	 * approximately in the middle of the eye with 8x oversampling
	 */
        reg [2:0] sample_timer = 0;
	
	/*
	 * an edge is detected when the current serial data (d1) differs
         * from the previous bit (d2). This resets the sampling delay 
         * counter to zero, realigning the sample point to the eye center. 
	 */
	wire edge_detected;	
        assign edge_detected = (d1 ^ d2);
        
	/* sample_timer is 4 approximately in the center of the eye */
	assign sample_valid = (sample_timer == 3'b100);	
	
        always @ (posedge clk) begin
		/* synchronize the input serial data and detect edges */
                d1 <= sdi;
		d2 <= d1;		
                
		/*
		 * if an edge was detected reset the sampling timer; otherwise
                 * increment the timer		
		 */
		if (edge_detected) begin
			sample_timer <= 3'b0;			
		end
		else begin
			sample_timer <= sample_timer + 3'd1;
		end				
        end		
endmodule
