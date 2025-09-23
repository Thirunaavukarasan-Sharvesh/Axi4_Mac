// Radix 4 Booth multiplier

`timescale 1ps/1ps

module multiplier
(
    input       signed [15:0] A;
    input       signed [15:0] B;
    output      signed [31:0] P;
    input       wire   clk, rst_n
);

integer i;
reg signed [33:0] acc;
reg signed [17:0] Q_ext;      // 16(multplicant) + 1 MSB + 1 LSB
reg signed [33:0] pp;         // partial product

always @(*) begin
    Q_ext = {B,1'b0};
    acc = 0;

    for(i=0; i < 16; i=i+2)
    begin
        case({Q_ext[i+2], Q_ext[i+1], Q_ext[i]})
            3'b000, 3'b111 : pp = 0;
            3'b001, 3'b010 : pp = {{18{A[15]}},A};    // +M
            3'b011         : pp = ({{18{A[15]}},A} << 1);   // +2M
            3'b100         : pp = -({{18{A[15]}},A} << 1);   // -2M
            3'b101, 3'b110 : pp = -{{18{A[15]}},A};          // -M
            default : pp = 0;
        endcase
        
    acc = acc + (pp <<< i);
    end    
    P = acc[31:0];
end

endmodule