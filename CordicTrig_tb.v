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
    reg [31:0] BA;
    reg [31:0] BB;

    wire [31:0] ResultC;
    wire [31:0] ResultM;

    //Fixed32_MUL FMul32(BA, Ix, Iy, Result[31:0]);
    
    CORDIC CRD(BA, 32'b01000000000000000000000000000000, 32'b00000000000000000000000000000000 , ResultC);
    Fixed32_MUL MUL(BA, BB, ResultM);
    
    initial begin    
        BA[31:0] <= 32'h16a09e66;
        BB[31:0] <= 32'h393e4b8b;
        #100 $finish;
    end
    
    //always begin
    //   #5 BA <= (BA >> 1);
    //end 
endmodule
