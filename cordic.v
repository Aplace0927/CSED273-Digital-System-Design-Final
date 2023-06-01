`timescale 1ps/1fs
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aplace
// 
// Create Date: 05/30/2023 10:09:40 PM
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

module JK_FF(input reset_n, input j, input k, input clk, output reg q, output reg q_);  
    initial begin
      q = 0;
      q_ = ~q;
    end
    
    always @(negedge clk) begin
        q = reset_n & (j&~q | ~k&q);
        q_ = ~reset_n | ~q;
    end
endmodule


module D_FF(input reset_n, input d, input clk, output q);   
    JK_FF D(reset_n, d, ~d, clk, q, _);
endmodule


module REG32(input reset_n, input [31:0] d, input clk, output [31:0] q);
    D_FF DFF32 [31:0](
        .reset_n(reset_n),
        .d(d[31:0]),
        .clk(clk),
        .q(q[31:0])
    );
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


module Fixed32_XOR(input [31:0] ifpA, input iB, output [31:0] ofpR);
    generate
        genvar i;
        for (i = 0; i <= 31; i = i + 1) begin
            assign ofpR[i] = iB ^ ifpA[i];
        end
    endgenerate
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
    wire [30:0] r_ifpA;
    wire [30:0] r_ifpB;
    
    wire [30:0] r_ofpR;

    wire [30:0] OPR_SFT [0:30];
    wire [30:0] OPR_AND [0:30];
    wire [30:0] OPR_SUM [0:29];    
    wire OPR_C[0:29];
    
    assign ofpR[31] = ifpA[31] ^ ifpB[31];
    
    generate
        genvar t;
        for(t = 0; t <= 30; t = t + 1) begin
            assign r_ifpA[t] = ifpA[30 - t];
            assign r_ifpB[t] = ifpB[30 - t];
            assign ofpR[30 - t] = r_ofpR[t];
        end
    endgenerate
    
    generate
        genvar i;
        for (i = 0; i <= 30; i = i + 1) begin
            Fixed32_AND FxAND(
                .ifpA({1'b0, r_ifpA[30:0]}),
                .iB(r_ifpB[i]),
                .ofpR({_tmp, OPR_AND[i]})
            );
            assign OPR_SFT[i] = OPR_AND[i] << i;
        end
    endgenerate

    Fixed32_ADD FxADDInit(.ifpA({1'b0, OPR_SFT[30]}), .ifpB({1'b0, OPR_SFT[29]}), .iC(1'b0), .oC(OPR_C[29]), .ofpR({_tmp, OPR_SUM[29]}));
    generate
        genvar j;
        for (j = 29; j >= 1; j = j - 1) begin
            Fixed32_ADD FA(
                .ifpA({1'b0, OPR_SUM[j]}),
                .ifpB({1'b0, OPR_SFT[j]}),
                .iC(OPR_C[j]),
                .oC(OPR_C[j-1]),
                .ofpR({_tmp, OPR_SUM[j-1]})
            );
        end
    endgenerate
    Fixed32_ADD FxADDFin(.ifpA({1'b0, OPR_SUM[0]}), .ifpB({1'b0, OPR_SFT[0]}), .iC(OPR_C[0]), .oC(_overflow), .ofpR({_tmp, r_ofpR}));
endmodule

module CORDIC(input reg [31:0] rad, output reg [31:0] trig);
    reg [31:0] Theta [0:7];
    reg [31:0] Prd_K [0:7];

    reg reset_n;
    reg clock;
    wire sgn;

    wire [31:0] Din_X;
    wire [31:0] Din_Y;
    wire [31:0] Dout_X;
    wire [31:0] Dout_Y;

    wire [31:0] MulX [0:7];
    wire [31:0] SgnX [0:7];
    wire [31:0] NrmX [0:7];

    wire [31:0] MulY [0:7];
    wire [31:0] SgnY [0:7];
    wire [31:0] NrmY [0:7];

    wire [31:0] SgnR [0:7];

    reg [31:0] Rotate [0:1];

    REG32 RX(reset_n, Din_X, clock, Dout_X);
    REG32 RY(reset_n, Din_Y, clock, Dout_Y);

    /* Plans and pseudocodes

    Fixed32_ADD (rad, {rad[31], Theta[30:0]}, rad[31], _oC, rad);
    
    // Rad += {rad[31], Theta[30:0]} or Rad -= {rad[31], Theta[30:0]} : determined by rad[31]'s sign
    // In-carry rad[31] determines ADD or SUB.
    // Out-carry _oC is not important
    // Finally rad is calculated and saved to itself again.

    */

    initial begin
        clock = 1'b0;

        Rotate[0] = 32'b01111111111111111111111111;
        Rotate[1] = 32'b00000000000000000000000000;

        Theta[0] = 32'b01100100100001111110110101010001;
        Theta[1] = 32'b00111011010110001100111000001010;
        Theta[2] = 32'b00011111010110110111010111111001;
        Theta[3] = 32'b00001111111010101101110101001101;
        Theta[4] = 32'b00000111111111010101011011101101;
        Theta[5] = 32'b00000011111111111010101010110111;
        Theta[6] = 32'b00000001111111111111010101010101;
        Theta[7] = 32'b00000000111111111111111010101010;
        
        /* Accumulated
        Prd_K[0] = 32'b01011010100000100111100110011001;
        Prd_K[1] = 32'b01010000111101000100110110001001;
        Prd_K[2] = 32'b01001110100010011000011011101001;
        Prd_K[3] = 32'b01001101111011100100010100000111;
        Prd_K[4] = 32'b01001101110001110110101100000110;
        Prd_K[5] = 32'b01001101101111011011001111101010;
        Prd_K[6] = 32'b01001101101110110100011000011010;
        Prd_K[7] = 32'b01001101101110101010101010100101;
        */
        
        Prd_K[0] = 32'b01011010100000100111100110011001;
        Prd_K[1] = 32'b01110010011111001001011100010110;
        Prd_K[2] = 32'b01111100001011011010000100100011;
        Prd_K[3] = 32'b01111111000000101111011000100010;
        Prd_K[4] = 32'b01111111110000000010111111011000;
        Prd_K[5] = 32'b01111111111100000000001011111111;
        Prd_K[6] = 32'b01111111111111000000000000101111;
        Prd_K[7] = 32'b01111111111111110000000000000010;
    end

    generate
        genvar k;
        for(k = 0; k < 8; k = k + 1) begin
            assign sgn = rad[31];

            // x = v[0] - sigma * (v[1] * 2^-j)
            Fixed32_MUL angX(Dout_Y, {32'b01000000000000000000000000000000 >> k}, MulX[k]);
            Fixed32_XOR sgnX(MulX[k], ~sgn, SgnX[k]);
            Fixed32_ADD cosT(Dout_X, SgnX[k] , ~sgn, _tmp, NrmX[k]);
                
            // y = sigma * (v[0] * 2^(-j)) + v[1];
            Fixed32_MUL angY(Dout_X, {32'b01000000000000000000000000000000 >> k}, MulY[k]);
            Fixed32_XOR sgnY(MulY[k], sgn, SgnY[k]);
            Fixed32_ADD sinT(Dout_Y, SgnY[k] , sgn, _tmp, NrmY[k]);

            // Angle reducing
            Fixed32_XOR sgnR(Theta[k], ~sgn, SgnR[k]);
            Fixed32_ADD addR(rad, SgnR[k], ~sgn, _tmp, rad);
                
            // Normalization
            Fixed32_MUL nrmX(NrmX[k], Prd_K[k], Din_X);
            Fixed32_MUL nrmY(NrmY[k], Prd_K[k], Din_Y);
        end
    endgenerate

    always begin
        #10 clock = ~clock;
    end

endmodule