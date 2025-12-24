`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thirunaavukarasan S and Sriram N
// 
// Create Date: 08.12.2025 08:08:44
// Design Name: Dynamic MAC Accelerator
// Module Name: BK_Top_dp
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

module BK_Top_dp #(
    parameter width = 48
)(
    input  wire [width-1:0] A,
    input  wire [width-1:0] B,
    input  wire             Cin,
    output wire [width-1:0] sum,
    output wire             cout
);

    // ---------------------------------------------------------
    // 1. Generate P and G
    // ---------------------------------------------------------
    wire [width-1:0] P, G;
    genvar i;

    generate
        for (i = 0; i < width; i = i + 1) begin
            assign P[i] = A[i] ^ B[i];
            assign G[i] = A[i] & B[i];
        end
    endgenerate

    // ---------------------------------------------------------
    // 2. Brent-Kung Prefix Tree
    // ---------------------------------------------------------
    localparam STAGES = $clog2(width);

    wire [width-1:0] Gs [0:STAGES];
    wire [width-1:0] Ps [0:STAGES];

    // Stage 0 = raw PG
    generate
        for (i = 0; i < width; i = i + 1) begin
            assign Gs[0][i] = G[i];
            assign Ps[0][i] = P[i];
        end
    endgenerate

    // Prefix tree levels
    genvar level, k;
    generate
        for (level = 1; level <= STAGES; level = level + 1) begin : LEVEL
            for (k = 0; k < width; k = k + 1) begin : COL
                if (k >= (1 << (level-1))) begin
                    assign Gs[level][k] =
                           Gs[level-1][k] |
                          (Ps[level-1][k] & Gs[level-1][k - (1 << (level-1))]);

                    assign Ps[level][k] =
                           Ps[level-1][k] &
                           Ps[level-1][k - (1 << (level-1))];
                end 
                else begin
                    assign Gs[level][k] = Gs[level-1][k];
                    assign Ps[level][k] = Ps[level-1][k];
                end
            end
        end
    endgenerate

    // ---------------------------------------------------------
    // 3. Final Grey Cells to compute each carry
    // ---------------------------------------------------------
    wire [width:0] C;
    assign C[0] = Cin;

    generate
        for (i = 0; i < width; i = i + 1) begin : FINAL_GREY
            assign C[i+1] = Gs[STAGES][i] | (Ps[STAGES][i] & C[i]);
        end
    endgenerate

    // ---------------------------------------------------------
    // 4. Final Sum
    // ---------------------------------------------------------
    generate
        for (i = 0; i < width; i = i + 1) begin
            assign sum[i] = P[i] ^ C[i];
        end
    endgenerate

    assign cout = C[width];

endmodule

