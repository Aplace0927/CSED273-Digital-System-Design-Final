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
    wire [31:0] ResultC;
    
    // Initialize with (Input angle), (vector [1, 0]), (Output wire)
    CORDIC CRD(BA, 32'b01000000000000000000000000000000, 32'b00000000000000000000000000000000 , ResultC);
    
    initial begin    
        BA[31:0] <= 32'h00000000; // Initialize by 0 [deg]
        #90 $finish;
    end
    
    always begin
      #5 BA <= BA + 32'h0595c612; // Increment by 5 [deg]
    end 
endmodule
