`timescale 1ps / 1fs
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aplace
// 
// Create Date: 05/31/2023 07:06:41 PM
// Design Name: Trigonometric Calculator
// Module Name: CORDIC
// Project Name: CSED273_Final
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CordicTrig_tb();
    integer k;
    reg [31:0] BA;
    wire [255:0] ResultC;
    wire [31:0] ResultD;
    
    CORDIC CRD(BA, 32'b01000000000000000000000000000000, 32'b00000000000000000000000000000000 , ResultC);
    Fixed32_APRX_4DIG SHFT({18'b0, ResultC[30+224:17+224]}, ResultD);

    initial begin
        BA[31:0] = 32'h00000000;
        for(k = 0; k < 90; k = k + 5) begin
            $display("Deg = %2d | CORDIC = %5d", k, ResultD);
            #10 BA = BA + 32'h0595c612;
        end
        $finish;
    end
endmodule
