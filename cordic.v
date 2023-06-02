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

module ConvertConv(input [31:0] ifpA, output [31:0] ofpR);
    generate
        genvar v;
        for(v = 0; v <= 30; v = v + 1) begin
            assign ofpR[v] = ifpA[31] ^ ifpA[v];
        end
    endgenerate
    assign ofpR[31] = ifpA[31];
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
    wire [30:0] r_ifpA; // Reversed 31bit input float array of multiplier
    wire [30:0] r_ifpB; // Reversed 31bit input float array of multiplicant
    
    wire [30:0] r_ofpR; // Reversed 31bit multiplication output (Temp)
    
    wire [30:0] OPR_iSFT [0:30];    // Shifted result of (reversed float multiplier) & (digit of multiplicant)
    wire [30:0] OPR_SFT [0:30];     // Float result of (float multiplier) & (digit of multiplicant) : Reverse of OPR_iSFT

    wire [30:0] OPR_AND [0:30];     // (reversed float multiplier) & (digit of multiplicant)
    wire [30:0] OPR_SUM [0:29];     // Accumulate of OPR_SFT
    wire OPR_C[0:29];
    
    assign ofpR[31] = ifpA[31] ^ ifpB[31];
    
    // Reverse wire setting
    generate
        genvar t;
        for(t = 0; t <= 30; t = t + 1) begin
            assign r_ifpA[t] = ifpA[30 - t];
            assign r_ifpB[t] = ifpB[30 - t];
            assign ofpR[t] = r_ofpR[t];
        end
    endgenerate
    
    // AND operations of inversed multiplier and inversed multiplicand: MULTIPLICATE PROPAGATES TO LSB. (2^-1 * 2^-3 = 2^-4)
    generate
        genvar i;
        for (i = 0; i <= 30; i = i + 1) begin
            Fixed32_AND FxAND(
                .ifpA({1'b0, r_ifpA[30:0]}),
                .iB(r_ifpB[i]),
                .ofpR({_tmp, OPR_AND[i]})
            );
            assign OPR_iSFT[i] = OPR_AND[i] << i;
        end
    endgenerate

    // Reverses each 31bit floats
    generate
        genvar ki, kj;
        for (ki = 0; ki <= 30; ki = ki + 1) begin
            for(kj = 0; kj <= 30; kj = kj + 1) begin
                assign OPR_SFT[ki][kj] = OPR_iSFT[ki][30 - kj];
            end
        end
    endgenerate
        
    // Adding 31bit floats (orignal order): ADDITION CARRY PROPAGATES TO MSB (2^-2 + 2^-2 = 2^-1)
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

module CORDIC(input [31:0] rad, input [31:0] InitVectX, input [31:0] InitVectY, output [31:0] trig);
    reg [31:0] Theta [0:7];
    reg [31:0] Prd_K [0:7];

    reg reset_n;
    wire sgn;

    wire [31:0] Rin [0:8];

    wire [31:0] COS [0:8];
    wire [31:0] SIN [0:8];

    wire [31:0] MulX [0:7];
    wire [31:0] SgnX [0:7];
    wire [31:0] _NrmX [0:7];
    wire [31:0] NrmX [0:7];

    wire [31:0] MulY [0:7];
    wire [31:0] SgnY [0:7];
    wire [31:0] _NrmY [0:7];
    wire [31:0] NrmY [0:7];

    wire [31:0] SgnR [0:7];

    //REG32 RX(reset_n, Din_X, clock, Dout_X);
    //REG32 RY(reset_n, Din_Y, clock, Dout_Y);

    // Initial vector to be rotated
    assign COS[0] = InitVectX[31:0]; //32'b01000000000000000000000000000000;
    assign SIN[0] = InitVectY[31:0]; //32'b00000000000000000000000000000000;

    // Result after 8 iterations.
    assign trig[31:0] = COS[8][31:0];

    initial begin
        // Each atan(2^-i) angle (in rad)
        Theta[0] = 32'b00110010010000111111011010101000;
        Theta[1] = 32'b00011101101011000110011100000101;
        Theta[2] = 32'b00001111101011011011101011111100;
        Theta[3] = 32'b00000111111101010110111010100110;
        Theta[4] = 32'b00000011111111101010101101110110;
        Theta[5] = 32'b00000001111111111101010101011011;
        Theta[6] = 32'b00000000111111111111101010101010;
        Theta[7] = 32'b00000000011111111111111101010101;
        
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
        
        // Multiplicates with Each iteration
        Prd_K[0] = 32'b00101101010000010011110011001100;
        Prd_K[1] = 32'b00111001001111100100101110001011;
        Prd_K[2] = 32'b00111110000101101101000010010001;
        Prd_K[3] = 32'b00111111100000010111101100010001;
        Prd_K[4] = 32'b00111111111000000001011111101100;
        Prd_K[5] = 32'b00111111111110000000000101111111;
        Prd_K[6] = 32'b00111111111111100000000000010111;
        Prd_K[7] = 32'b00111111111111111000000000000001;
    end

    assign Rin[0][31:0] = rad[31:0];

    generate
        genvar k;
        for(k = 0; k < 8; k = k + 1) begin

            // x' = x - sigma * (y * 2^-j)
            Fixed32_MUL angX(SIN[k], {32'b01000000000000000000000000000000 >> k}, MulX[k]);
            Fixed32_XOR sgnX(MulX[k], ~Rin[k][31], SgnX[k]);
            Fixed32_ADD cosT(COS[k], SgnX[k] , ~Rin[k][31], _tmp, _NrmX[k]);
            ConvertConv cnvX(_NrmX[k], NrmX[k]);
                
            // y' = y + sigma * (x * 2^(-j)
            Fixed32_MUL angY(COS[k], {32'b01000000000000000000000000000000 >> k}, MulY[k]);
            Fixed32_XOR sgnY(MulY[k], Rin[k][31], SgnY[k]);
            Fixed32_ADD sinT(SIN[k], SgnY[k] , Rin[k][31], _tmp, _NrmY[k]);
            ConvertConv cnvY(_NrmY[k], NrmY[k]);

            // Angle reducing
            Fixed32_XOR sgnR(Theta[k], ~Rin[k][31], SgnR[k]);
            Fixed32_ADD addR(Rin[k], SgnR[k], ~Rin[k][31], _tmp, Rin[k+1]);
                
            // Normalization
            Fixed32_MUL nrmX(NrmX[k], Prd_K[k], COS[k+1]);
            Fixed32_MUL nrmY(NrmY[k], Prd_K[k], SIN[k+1]);

            // Matrix
        end
    endgenerate 

endmodule