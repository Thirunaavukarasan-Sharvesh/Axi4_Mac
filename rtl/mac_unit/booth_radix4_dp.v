`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thirunaavukarasan S and Sriram N
// 
// Create Date: 08.12.2025 08:08:44
// Design Name: Dynamic MAC Accelerator
// Module Name: booth_radix4_dp
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

module booth_radix4_dp #(
  parameter W = 16)(
    input  signed [W-1:0] A,
    input  signed [W-1:0] B,
    input  clear,
    output reg signed [2*W-1:0] P
);

integer k;

reg signed [W:0]   A_ext;
reg signed [W:0]   twoA_ext;
reg signed [W+1:0] B_ext;

reg signed [2*W:0] sum;
reg signed [2*W:0] pp;
reg [2:0] booth_bits;

always @* begin
    if (clear) begin
        P = 0;
    end else begin
        // Sign-extend A
        A_ext    = {A[W-1], A};
        twoA_ext = A_ext <<< 1;

        // Extend B
        B_ext = {B[W-1], B, 1'b0};

        sum = 0;

        for (k = 0; k < W; k = k + 2) begin
            booth_bits = {B_ext[k+2], B_ext[k+1], B_ext[k]};

            case (booth_bits)
                3'b000, 3'b111: pp = 0;
                3'b001, 3'b010: pp =  A_ext;
                3'b011:         pp =  twoA_ext;
                3'b100:         pp = -twoA_ext;
                3'b101, 3'b110: pp = -A_ext;
            endcase

            sum = sum + (pp <<< k);
        end

        P = sum[2*W-1:0];
    end
end

endmodule


