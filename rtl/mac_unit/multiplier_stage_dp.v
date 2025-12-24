`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thirunaavukarasan S and Sriram N
// 
// Create Date: 08.12.2025 08:08:44
// Design Name: Dynamic MAC Accelerator
// Module Name: multiplier_stage_dp
// Project Name: High-Speed AXI4-Lite Dynamic MAC Accelerator for RISC-V SoC Designs 
// Target Devices: FPGAs Zedboard 7000 and Artix-7
// Tool Versions: Vivado 2018.3
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module multiplier_stage_dp #(
    parameter W = 40   // max width
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire                clear,
    input  wire  [1:0]         precision_mode,   // 00=8, 01=16, 10=32, 11=40
    input  signed [W-1:0]      A,
    input  signed [W-1:0]      B,
    output reg  signed [(2*W)-1:0] P_reg
);

   
    // Dynamic MASKING (this makes MAC dynamic)

    reg signed [W-1:0] A_eff, B_eff;

    always @(*) begin
        case (precision_mode)
            2'b00: begin       // 8-bit
                A_eff = {{(W-8){A[7]}}, A[7:0]};
                B_eff = {{(W-8){B[7]}}, B[7:0]};
            end

            2'b01: begin       // 16-bit
                A_eff = {{(W-16){A[15]}}, A[15:0]};
                B_eff = {{(W-16){B[15]}}, B[15:0]};
            end

            2'b10: begin       // 32-bit
                A_eff = {{(W-32){A[31]}}, A[31:0]};
                B_eff = {{(W-32){B[31]}}, B[31:0]};
            end

            default: begin     // 40-bit
                A_eff = A;
                B_eff = B;
            end
        endcase
    end

   
    //  FIXED Booth multiplier (W bits always)
  
    wire signed [(2*W)-1:0] P_comb;

    booth_radix4_dp #(.W(W)) u_booth (
        .A(A_eff),
        .B(B_eff),
        .clear(clear),
        .P(P_comb)
    );

   
    // Pipeline register

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            P_reg <= 0;
        else if (clear)
            P_reg <= 0;
        else
            P_reg <= P_comb;
    end

endmodule

