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

    wire [31:0] Result;

    Fixed32_MUL FMul32(BA, BB, Result[31:0]);
    
    initial begin
        
        BA[31:0]   <= 32'b11111111111111111111111111111111;
        BB[31:0]   <= 32'b10000000001111111111111111111111;
         
        #100 $finish;
    end
    
    always begin
        #5 BB <= (BB >> 1);
    end
endmodule
