`timescale 1ns / 1ps

// To upload CORDIC on FPGA board
module CORDIC_FPGA (input clk, input [15:0] sw, output [3:0] ssSel,
					input btnCenter, input btnBottom, input btnLeft, input btnRight, input btnTop,
					output [7:0] ssDisp, output reg [15:0] led);
	reg [31:0] counter;
	reg [15:0] gbuf;
	wire [3:0] res;

	wire [255:0] FixedTrigVct;	// 32bit fixed point * 8 entries
	wire [31:0] intTrig [0:7];

	reg [3:0] StepState;

	wire c_out;
	reg blinker;

	initial begin
		StepState <= 0;
		counter <= 0;
		gbuf <= 16'b1111111111111111;
	end

	CORDIC Cordic(
    	.rad({1'b0, sw, 15'b0}),							// 32bit fixed point angle in radian
    	.InitVectX(32'b01000000000000000000000000000000),	// [1, 0]
    	.InitVectY(32'b00000000000000000000000000000000),
    	.trig(FixedTrigVct)									// Output
	);

	// Interprete each step into decimal points
	Fixed32_APRX_4DIG INTMAKE_7(.ifpA({18'b0, FixedTrigVct[30+224:17+224]}), .ofpR(intTrig[7]));
	Fixed32_APRX_4DIG INTMAKE_6(.ifpA({18'b0, FixedTrigVct[30+192:17+192]}), .ofpR(intTrig[6]));
	Fixed32_APRX_4DIG INTMAKE_5(.ifpA({18'b0, FixedTrigVct[30+160:17+160]}), .ofpR(intTrig[5]));
	Fixed32_APRX_4DIG INTMAKE_4(.ifpA({18'b0, FixedTrigVct[30+128:17+128]}), .ofpR(intTrig[4]));
	Fixed32_APRX_4DIG INTMAKE_3(.ifpA({18'b0, FixedTrigVct[30+ 96:17+ 96]}), .ofpR(intTrig[3]));
	Fixed32_APRX_4DIG INTMAKE_2(.ifpA({18'b0, FixedTrigVct[30+ 64:17+ 64]}), .ofpR(intTrig[2]));
	Fixed32_APRX_4DIG INTMAKE_1(.ifpA({18'b0, FixedTrigVct[30+ 32:17+ 32]}), .ofpR(intTrig[1]));
	Fixed32_APRX_4DIG INTMAKE_0(.ifpA({18'b0, FixedTrigVct[30+  0:17+  0]}), .ofpR(intTrig[0]));

	led_renderer Renderer(
    	.graphics(gbuf),
    	.clk(clk),
    	.segSel(ssSel),
    	.seg(ssDisp)
	);


	always @(posedge clk) begin
		if(btnTop & StepState == 0) begin		// Step-by-step increasing state by pressing button
			StepState <= 1;
		end
		if(btnRight & StepState == 1) begin
			StepState <= 2;
		end
		if(btnBottom & StepState == 2) begin
			StepState <= 3;
		end
		if(btnLeft & StepState == 3) begin
			StepState <= 4;
		end
		if(btnTop & StepState == 4) begin
			StepState <= 5;
		end
		if(btnRight & StepState == 5) begin
			StepState <= 6;
		end
		if(btnBottom & StepState == 6) begin
			StepState <= 7;
		end
		if(btnLeft & StepState == 7) begin
			StepState <= 0;
		end
		if(btnCenter & StepState == 7) begin	// State toggle to init. state
			StepState <= 0;
		end
		if(btnCenter & StepState != 7) begin	// State toggle to final state
			StepState <= 7;
		end
	end

	// FND Buffer
	always @(posedge clk) begin

		/*
		 * Each state: from lower to higher state, set their LED from right to left
		 * Leftmost LED is spare for overflow flag( cos(x) >= 1 ) with some errors.
		 * Set each digits of gbufs to corresponding digits 
		*/
		case (StepState)
		4'b0000: begin
			led = 16'h8000 | (intTrig[0] >= 10000);
			gbuf[3:0] <= (intTrig[0] / 1000) % 10;
			gbuf[7:4] <= (intTrig[0] / 100) % 10;
			gbuf[11:8] <= (intTrig[0] / 10) % 10;
			gbuf[15:12] <= intTrig[0] % 10;
		end
		4'b0001: begin
			led = 16'h4000 | (intTrig[1] >= 10000);
			gbuf[3:0] <= (intTrig[1] / 1000) % 10;
			gbuf[7:4] <= (intTrig[1] / 100) % 10;
			gbuf[11:8] <= (intTrig[1] / 10) % 10;
			gbuf[15:12] <= intTrig[1] % 10;
		end
		4'b0010: begin
			led = 16'h2000 | (intTrig[2] >= 10000);
			gbuf[3:0] <= (intTrig[2] / 1000) % 10;
			gbuf[7:4] <= (intTrig[2] / 100) % 10;
			gbuf[11:8] <= (intTrig[2] / 10) % 10;
			gbuf[15:12] <= intTrig[2] % 10;
		end
		4'b0011: begin
			led = 16'h1000 | (intTrig[3] >= 10000);
			gbuf[3:0] <= (intTrig[3] / 1000) % 10;
			gbuf[7:4] <= (intTrig[3] / 100) % 10;
			gbuf[11:8] <= (intTrig[3] / 10) % 10;
			gbuf[15:12] <= intTrig[3] % 10;
		end
		4'b0100: begin
			led = 16'h0800 | (intTrig[4] >= 10000);
			gbuf[3:0] <= (intTrig[4] / 1000) % 10;
			gbuf[7:4] <= (intTrig[4] / 100) % 10;
			gbuf[11:8] <= (intTrig[4] / 10) % 10;
			gbuf[15:12] <= intTrig[4] % 10;
		end
		4'b0101: begin
			led = 16'h0400 | (intTrig[5] >= 10000);
			gbuf[3:0] <= (intTrig[5] / 1000) % 10;
			gbuf[7:4] <= (intTrig[5] / 100) % 10;
			gbuf[11:8] <= (intTrig[5] / 10) % 10;
			gbuf[15:12] <= intTrig[5] % 10;
		end
		4'b0110: begin
			led = 16'h0200 | (intTrig[6] >= 10000);
			gbuf[3:0] <= (intTrig[6] / 1000) % 10;
			gbuf[7:4] <= (intTrig[6] / 100) % 10;
			gbuf[11:8] <= (intTrig[6] / 10) % 10;
			gbuf[15:12] <= intTrig[6] % 10;
		end
		4'b0111: begin
			led = 16'h0100 | (intTrig[7] >= 10000);
			gbuf[3:0] <= (intTrig[7] / 1000) % 10;
			gbuf[7:4] <= (intTrig[7] / 100) % 10;
			gbuf[11:8] <= (intTrig[7] / 10) % 10;
			gbuf[15:12] <= intTrig[7] % 10;
		end
		endcase
	end
endmodule

module led_renderer	(input [15:0] graphics, input clk, output reg [3:0] segSel, output reg [7:0] seg);
	integer counter;
	wire [7:0] res0, res1, res2, res3;

  	initial begin
    	counter <= 0;
    	segSel <= 14;
    	seg <= 8'b11111111;
  	end

  	bcd_to_7seg pos0 (.bcd(graphics[3:0]), .seg(res0));
	bcd_to_7seg pos1 (.bcd(graphics[7:4]), .seg(res1));
  	bcd_to_7seg pos2 (.bcd(graphics[11:8]), .seg(res2));
  	bcd_to_7seg pos3 (.bcd(graphics[15:12]), .seg(res3));

  	always @(posedge clk) begin
    	counter <= counter + 1;
    	if (counter == 100000) begin
      	counter <= 0;
		case (segSel)
			14: begin
				segSel <= 13;
				seg <= res1;
			end
			13: begin
				segSel <= 11;
				seg <= res2;
			end
			11: begin
				segSel <= 7;
				seg <= res3;
			end
			7: begin
				segSel <= 14;
				seg <= res0;
			end
		endcase
		end
	end
endmodule

module bcd_to_7seg (input [3:0] bcd, output reg [7:0] seg);
	always @(*) begin
    // dot, center, tl, bl, b, br, tr, t
    case (bcd)
		4'b0000: seg = 8'b11000000;  // 0
		4'b0001: seg = 8'b11111001;  // 1
		4'b0010: seg = 8'b10100100;  // 2
		4'b0011: seg = 8'b10110000;  // 3
		4'b0100: seg = 8'b10011001;  // 4
		4'b0101: seg = 8'b10010010;  // 5
		4'b0110: seg = 8'b10000010;  // 6
		4'b0111: seg = 8'b11111000;  // 7
		4'b1000: seg = 8'b10000000;  // 8
		4'b1001: seg = 8'b10010000;  // 9
		default: seg = 8'b11111111;
    endcase
  	end
endmodule
