/*
 * I made those Flip-flops, but actually did not use them :(
 * Implemented Sequential logic with internal clocks and buttons
 *
*/

// JK Flipflop
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

// D Flipflop
module D_FF(input reset_n, input d, input clk, output q);   
    JK_FF D(reset_n, d, ~d, clk, q, _);
endmodule

// T Flipflop
module T_FF(input reset_n, input t, input clk, output q);   
    JK_FF T(reset_n, t, t, clk, q, _);
endmodule


// 32bit Register w/ D Flipflop
module REG32(input reset_n, input [31:0] d, input clk, output [31:0] q);
    D_FF DFF32 [31:0](
        .reset_n(reset_n),
        .d(d[31:0]),
        .clk(clk),
        .q(q[31:0])
    );
endmodule

module Count8(input reset_n, input clk, output [2:0] count);
    T_FF T4(reset_n, 1'b1, count[0] & count[1], count[2]);
    T_FF T2(reset_n, 1'b1, count[0], count[1]);
    T_FF T1(reset_n, 1'b1, clk, count[0]);
endmodule