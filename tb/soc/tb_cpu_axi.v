`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 13:11:27
// Design Name: 
// Module Name: tb_cpu_axi
// Project Name: 
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


module tb_cpu_axi;

    reg clk = 0;
    reg resetn = 0;

    always #5 clk = ~clk;

    soc_top dut (
        .clk(clk),
        .resetn(resetn)
    );

    initial begin
        $display("\n===== AXI WRITE MONITOR =====");
        $monitor("[T=%0t] AWVALID=%b AWREADY=%b AWADDR=%h | WVALID=%b WREADY=%b WDATA=%h WSTRB=%b | BVALID=%b", $time, dut.cpu_awvalid, dut.cpu_awready, dut.cpu_awaddr, dut.cpu_wvalid, dut.cpu_wready, dut.cpu_wdata, dut.cpu_wstrb, dut.cpu_bvalid);
    end

    initial begin
        $display("\n===== AXI READ MONITOR =====");
        $monitor("[T=%0t] ARVALID=%b ARREADY=%b ARADDR=%h | RVALID=%b RREADY=%b RDATA=%h",$time, dut.cpu_arvalid, dut.cpu_arready, dut.cpu_araddr, dut.cpu_rvalid, dut.cpu_rready, dut.cpu_rdata);
    end

    initial begin
        $dumpfile("cpu_axi_wave.vcd");
        $dumpvars(0, tb_cpu_axi);
        resetn = 0;
        repeat (20) @(posedge clk);
        resetn = 1;
        $display("CPU Released from reset at T=%0t", $time);

        // Run long enough to see multiple AXI transactions
        #2_000_000;

        $display("=========== END CPU AXI TEST ===========");
        $finish;
    end

endmodule