`timescale 1ns / 1ps

module CORDIC_FPGA (input clk, input [15:0] sw, output [3:0] ssSel, output [7:0] ssDisp);
	reg [31:0] counter;
	reg [15:0] gbuf;
	wire [3:0] res;

	wire [31:0] FixedTrig;
	wire [31:0] intTrig;

	wire c_out;
	reg blinker;

	initial begin
		counter <= 0;
		gbuf <= 16'b1111111111111111;
	end

	CORDIC Cordic(
    	.rad({1'b0, sw, 15'b0}),
    	.InitVectX(32'b01000000000000000000000000000000),
    	.InitVectY(32'b00000000000000000000000000000000),
    	.trig(FixedTrig)
	);

	Fixed32_APRX_4DIG INTMAKE(
		.ifpA({18'b0, FixedTrig[30:17]}),
		.ofpR(intTrig)
	);
	
	led_renderer Renderer(
    	.graphics(gbuf),
    	.clk(clk),
    	.segSel(ssSel),
    	.seg(ssDisp)
	);

	// FND Buffer
	always @(posedge clk) begin
		gbuf[3:0] <= (intTrig / 1000) % 10;
		gbuf[7:4] <= (intTrig / 100) % 10;
		gbuf[11:8] <= (intTrig / 10) % 10;
		gbuf[15:12] <= intTrig % 10;
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
