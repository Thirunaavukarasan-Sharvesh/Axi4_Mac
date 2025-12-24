`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thirunaavukarasan S and Sriram N
// 
// Create Date: 08.12.2025 08:08:44
// Design Name: Dynamic MAC Accelerator
// Module Name: mac_top_dp
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
// Dynamic-Precision MAC Top
//   - Uses dynamic Booth multiplier (multiplier_stage_dp)
//   - Uses BK-based dynamic accumulator (accumulator_bk_dp)
//   - Accumulator is 32-bit, multiplier is up to 80-bit
//   - Product is dynamically truncated/sign-extended per mode
//////////////////////////////////////////////////////////////////////////////////

module mac_top_dp #(
    parameter W = 40,
    parameter ACC_WIDTH = 32
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire                en,
    input  wire                clear,
    input  wire  [1:0]         precision_mode,
    input  signed [W-1:0]      A,
    input  signed [W-1:0]      B,

    output wire signed [ACC_WIDTH-1:0] mac_out,
    output wire                        mac_ovf
);

    // MULTIPLIER (dynamic precision)
    wire signed [2*W-1:0] P_full;

    multiplier_stage_dp #(.W(W)) MUL (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .precision_mode(precision_mode),
        .A(A),
        .B(B),
        .P_reg(P_full)
    );

    // 2) TRUNCATION TO 32-bit DOMAIN FOR ACCUMULATOR

    reg signed [31:0] P_masked;

    always @(*) begin
        case (precision_mode)
            2'b00: begin
                P_masked = {{16{P_full[15]}}, P_full[15:0]};
            end
            2'b01: begin
                P_masked = P_full[31:0];
            end
            default: begin
                P_masked = P_full[31:0];
            end
        endcase
    end
  
    // MAP MULTIPLIER PRECISION ? ACCUMULATOR PRECISION

    wire [1:0] acc_precision = (precision_mode == 2'b00) ? 2'b00 : 2'b01;
   
    // ACCUMULATOR (already dynamic)

    accumulator_dp #(.ACC_WIDTH(32)) ACC (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .clear(clear),
        .precision_mode(acc_precision),
        .data_in(P_masked),
        .acc_out(mac_out),
        .ovf_flag(mac_ovf)
    );

endmodule

