`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thirunaavukarasan S and Sriram N
// 
// Create Date: 09.12.2025 10:17:16
// Design Name: Memory module for the RISC V processor  
// Module Name: ram
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

module ram #(
    parameter MEM_SIZE      = 128 * 1024,             // 128 KB
    parameter INIT_FILE     = "firmware.hex"   
)(
    input  wire         clk,
    input  wire         wen,                          // write enable
    input  wire [3:0]   wstrb,                        // byte enables
    input  wire [31:0]  addr,                         // byte address
    input  wire [31:0]  wdata,                        // write data
    output wire [31:0]  rdata                         // read data
);

    // Memory depth = MEM_SIZE / 4 (32-bit words)

    localparam MEM_WORDS = MEM_SIZE / 4;

    // 32-bit word addressed RAM
    reg [31:0] mem [0:MEM_WORDS-1];

    initial begin
        if (INIT_FILE != "") begin
            $display("Loading RAM init file: %s", INIT_FILE);
            $readmemh(INIT_FILE, mem);
        end
    end

    wire [31:0] word_addr = addr[31:2];
    assign rdata = mem[word_addr];
    always @(posedge clk) begin
        if (wen) begin
            if (wstrb[0]) mem[word_addr][ 7: 0] <= wdata[ 7: 0];
            if (wstrb[1]) mem[word_addr][15: 8] <= wdata[15: 8];
            if (wstrb[2]) mem[word_addr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[word_addr][31:24] <= wdata[31:24];
        end
    end

endmodule
