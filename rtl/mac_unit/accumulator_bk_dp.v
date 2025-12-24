`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thirunaavukarasan S and Sriram N
// 
// Create Date: 08.12.2025 08:08:44
// Design Name: Dynamic MAC Accelerator
// Module Name: accumulator_dp
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

module accumulator_dp #(
    parameter ACC_WIDTH = 32
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      en,             
    input  wire                      clear,          
    input  wire [1:0]                precision_mode,
    input  wire signed [ACC_WIDTH-1:0] data_in,     
    output wire signed [ACC_WIDTH-1:0] acc_out,      
    output reg                       ovf_flag        
);

    reg  signed [ACC_WIDTH-1:0] acc_reg;
    wire signed [ACC_WIDTH-1:0] data_in_se;

    assign data_in_se =
        (precision_mode == 2'b00) ?
            {{(ACC_WIDTH-16){data_in[15]}}, data_in[15:0]} : data_in;   // for mode 1/2 we use full 32-bit

    wire signed [ACC_WIDTH-1:0] adder_a = acc_reg;
    wire signed [ACC_WIDTH-1:0] adder_b = data_in_se;
    wire                        adder_cin = 1'b0;
    wire signed [ACC_WIDTH-1:0] sum_comb;
    wire                        cout_comb;

    BK_Top_dp #(
        .width(ACC_WIDTH)
    ) ADDER (
        .A   (adder_a),
        .B   (adder_b),
        .Cin (adder_cin),
        .sum (sum_comb),
        .cout(cout_comb)
    );
    // Overflow detection logic

    wire overflow_16;
    wire overflow_32;
    wire overflow;

    assign overflow_16 =
        (adder_a[15] == adder_b[15]) && (adder_a[15] != sum_comb[15]);

    assign overflow_32 =
        (adder_a[ACC_WIDTH-1] == adder_b[ACC_WIDTH-1]) &&
        (adder_a[ACC_WIDTH-1] != sum_comb[ACC_WIDTH-1]);

    assign overflow =
        (precision_mode == 2'b00) ? overflow_16 : overflow_32;

    // PIPELINE STAGE 1: register adder result and control

    reg signed [ACC_WIDTH-1:0] sum_reg;
    reg                        ovf_reg;
    reg                        en_reg;
    reg                        clear_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg   <= {ACC_WIDTH{1'b0}};
            ovf_reg   <= 1'b0;
            en_reg    <= 1'b0;
            clear_reg <= 1'b0;
        end else begin
            sum_reg   <= sum_comb;
            ovf_reg   <= overflow;
            en_reg    <= en;
            clear_reg <= clear;
        end
    end


    // PIPELINE STAGE 2: update accumulator state

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_reg  <= {ACC_WIDTH{1'b0}};
            ovf_flag <= 1'b0;
        end
        else if (clear_reg) begin
            acc_reg  <= {ACC_WIDTH{1'b0}};
            ovf_flag <= 1'b0;
        end
        else if (en_reg) begin
            acc_reg  <= sum_reg;    
            ovf_flag <= ovf_reg;
        end
    end

    assign acc_out = acc_reg;

endmodule
