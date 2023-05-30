`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2023 10:09:40 PM
// Design Name: 
// Module Name: CORDIC
// Project Name: 
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


module CORDIC(input [31:0] rad,output [31:0] trig);
    wire [31:0] Theta [0:7];
    wire [31:0] Prd_K [0:7];
    
    assign Theta[0] = 32'b01100100100001111110110101010001;
    assign Theta[1] = 32'b00111011010110001100111000001010;
    assign Theta[2] = 32'b00011111010110110111010111111001;
    assign Theta[3] = 32'b00001111111010101101110101001101;
    assign Theta[4] = 32'b00000111111111010101011011101101;
    assign Theta[5] = 32'b00000011111111111010101010110111;
    assign Theta[6] = 32'b00000001111111111111010101010101;
    assign Theta[7] = 32'b00000000111111111111111010101010;
    
    assign Prd_K[0] = 32'b01011010100000100111100110011001;
    assign Prd_K[1] = 32'b01010000111101000100110110001001;
    assign Prd_K[2] = 32'b01001110100010011000011011101001;
    assign Prd_K[3] = 32'b01001101111011100100010100000111;
    assign Prd_K[4] = 32'b01001101110001110110101100000110;
    assign Prd_K[5] = 32'b01001101101111011011001111101010;
    assign Prd_K[6] = 32'b01001101101110110100011000011010;
    assign Prd_K[7] = 32'b01001101101110101010101010100101;
endmodule

module edge_trigger_JKFF(input reset_n, input j, input k, input clk, output reg q, output reg q_);  
    initial begin
      q = 0;
      q_ = ~q;
    end
    
    always @(negedge clk) begin
        q = reset_n & (j&~q | ~k&q);
        q_ = ~reset_n | ~q;
    end
endmodule

module FA(input iA, input iB, input iC, output oC, output oV);
    assign oV = (iA ^ iB ^ iC);
    assign oC = (((iA ^ iB) & iC) | (iA & iB));
endmodule

module Fixed32_ADD(input [31:0] ifpA, input [31:0] ifpB, input iC, output oC, output [31:0] ofpR);
    wire [30:0] _CR;
    FA F32 [31:0](
        .iA(ifpA[31:0]),
        .iB(ifpB[31:0]),
        .iC({_CR, iC}),
        .oC({oC, _CR}),
        .oV(ofpR[31:0])
    );
endmodule

module Fixed32_AND(input [31:0] ifpA, input iB, output [31:0] ofpR);
    generate
        genvar i;
        for (i = 0; i <= 31; i = i + 1) begin
            assign ofpR[i] = iB & ifpA[i];
        end
    endgenerate
endmodule

module Fixed32_SFT10(input [31:0] ifpA, output [31:0] ofpR);
    wire [31:0] Shift4;
    wire [31:0] Shift5;

    // 4x == x << 2
    assign Shift4[31:2] = ifpA[29:0];
    assign Shift4[1:0] = 2'b00;

    // 5x = (x << 2) + x
    Fixed32_ADD S4_to_S5(Shift4[31:0], ifpA[31:0], 0'b0, _tmp, Shift5[31:0]);

    // 10x = ((x << 2) + x) << 1
    assign ofpR[31:1] = Shift5[30:0];
    assign ofpR[0] = 1'b0;
endmodule

module Fixed32_MUL(input [31:0] ifpA, input [31:0] ifpB, output [31:0] ofpR);
    wire [31:0] r_ifpA;
    wire [31:0] r_ifpB;
    
    wire [31:0] r_ofpR;

    wire [31:0] OPR_L [0:31];
    wire [31:0] OPR_R [0:31];    

    generate
        genvar t;
        for(t = 0; t <= 31; t = t + 1) begin
            assign r_ifpA[t] = ifpA[31 - t];
            assign r_ifpB[t] = ifpB[31 - t];
            assign r_ofpR[t] = ofpR[31 - t];
        end
    endgenerate
    
    Fixed32_AND FxANDInit(.ifpA(r_ifpA[31:0]),  .iB(r_ifpB[0]), .ofpR({OPR_L[0][31:1], r_ofpR[0]}));
    generate
        genvar i;
        for (i = 1; i <= 31; i = i + 1) begin
            Fixed32_AND FxAND(
                .ifpA(r_ifpA[31:0]),
                .iB(r_ifpB[i]),
                .ofpR(OPR_R[i][31:0])
            );
        end
    endgenerate

    Fixed32_ADD FxADDInit(.ifpA({1'b0, OPR_L[0][31:1]}), .ifpB(OPR_R[1][31:0]), .iC(1'b0), .oC(OPR_L[1][31]), .ofpR({OPR_L[1][30:0], r_ofpR[1]}));
    generate
        genvar j;
        for (j = 0; j <= 30; j = j + 1) begin
            Fixed32_ADD FA(
                .ifpA(OPR_L[j][31:0]),
                .ifpB(OPR_R[j+1][31:0]),
                .iC(1'b0),
                .oC(OPR_L[j+1][31]),
                .ofpR({OPR_L[j+1][30:0], r_ofpR[j+1]})
            );
        end
    endgenerate
endmodule