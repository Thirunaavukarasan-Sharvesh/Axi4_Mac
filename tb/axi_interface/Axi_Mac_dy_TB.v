`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 09:16:10
// Design Name: 
// Module Name: Axi_Mac_dy_TB
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


module Axi_Mac_dy_TB;

    reg         ACLK;
    reg         ARESETN;
    reg  [3:0]  AWADDR;
    reg         AWVALID;
    wire        AWREADY;

    reg  [31:0] WDATA;
    reg  [3:0]  WSTRB;
    reg         WVALID;
    wire        WREADY;

    wire [1:0]  BRESP;
    wire        BVALID;
    reg         BREADY;

    reg  [3:0]  ARADDR;
    reg         ARVALID;
    wire        ARREADY;

    wire [31:0] RDATA;
    wire [1:0]  RRESP;
    wire        RVALID;
    reg         RREADY;

    // Address constants
    localparam [3:0] ADDR_CTRL = 4'h0;  // 0x00: en/clear + ovf (bit2 read)
    localparam [3:0] ADDR_OP   = 4'h4;  // 0x04: A[31:16], B[15:0]
    localparam [3:0] ADDR_RES  = 4'h8;  // 0x08: MAC result
    localparam [3:0] ADDR_MODE = 4'hC;  // 0x0C: precision_mode[1:0]

    Axi4_Lite_Mac_Dy_v1_0 DUT (
        .s00_axi_aclk    (ACLK),
        .s00_axi_aresetn (ARESETN),

        .s00_axi_awaddr  (AWADDR),
        .s00_axi_awprot  (3'b000),
        .s00_axi_awvalid (AWVALID),
        .s00_axi_awready (AWREADY),

        .s00_axi_wdata   (WDATA),
        .s00_axi_wstrb   (WSTRB),
        .s00_axi_wvalid  (WVALID),
        .s00_axi_wready  (WREADY),

        .s00_axi_bresp   (BRESP),
        .s00_axi_bvalid  (BVALID),
        .s00_axi_bready  (BREADY),

        .s00_axi_araddr  (ARADDR),
        .s00_axi_arprot  (3'b000),
        .s00_axi_arvalid (ARVALID),
        .s00_axi_arready (ARREADY),

        .s00_axi_rdata   (RDATA),
        .s00_axi_rresp   (RRESP),
        .s00_axi_rvalid  (RVALID),
        .s00_axi_rready  (RREADY)
    );

    reg [31:0] packed_AB;

    initial begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK;
    end

    task axi_write(input [3:0] addr, input [31:0] data);
    begin
        $display("\nAXI WRITE REQ: ADDR=%0h DATA=%0d", addr, data);

        AWADDR  = addr;
        AWVALID = 1;
        WDATA   = data;
        WSTRB   = 4'hF;
        WVALID  = 1;
        BREADY  = 1;

        @(posedge ACLK);
        while (!AWREADY || !WREADY) begin
            $display("  WAITING: AWREADY=%b WREADY=%b", AWREADY, WREADY);
            @(posedge ACLK);
        end

        $display("  WRITE ACCEPTED: AWREADY=%b WREADY=%b", AWREADY, WREADY);

        AWVALID = 0;
        WVALID  = 0;

        while (!BVALID) begin
            $display("  WAITING BVALID...");
            @(posedge ACLK);
        end

        $display("  WRITE RESPONSE: BVALID=%b BRESP=%0d", BVALID, BRESP);

        @(posedge ACLK);
        BREADY = 0;
    end
    endtask
// AXI Read Task
   
    task axi_read(input [3:0] addr);
    begin
        $display("\nAXI READ REQ: ADDR=%0h", addr);

        ARADDR  = addr;
        ARVALID = 1;
        RREADY  = 1;

        @(posedge ACLK);
        while (!ARREADY) begin
            $display("  WAITING ARREADY...");
            @(posedge ACLK);
        end

        $display("  READ ADDRESS ACCEPTED");

        ARVALID = 0;

        while (!RVALID) begin
            $display("  WAITING RVALID...");
            @(posedge ACLK);
        end

        $display("  READ DATA: %0d (RVALID=%b)", RDATA, RVALID);

        @(posedge ACLK);
        RREADY = 0;
    end
    endtask

    integer i;
    integer A_val, B_val;
    integer expected_acc;
    integer product;

    initial begin

        // Reset sequence
        ARESETN = 0;
        AWVALID = 0;
        WVALID  = 0;
        ARVALID = 0;
        BREADY  = 0;
        RREADY  = 0;
        AWADDR  = 0;
        ARADDR  = 0;
        #50;
        ARESETN = 1;
        @(posedge ACLK);
        $display("===== RESET DONE =====");

        // SET PRECISION MODE (e.g. 16-bit ? 2'b01)
        // mode encoding in mac_top_dp:
        // 00 ? 8-bit mult / 16-bit acc region
        // 01 ? 16-bit / 32-bit
        // 10/11 ? 32/40-bit truncated to 32

        axi_write(ADDR_MODE, 32'h1);  // precision_mode = 2'b01 (16-bit MAC)
        $display("Precision mode set to 16-bit (01).");

        axi_write(ADDR_OP, {16'sd10, 16'sd5});
        axi_write(ADDR_CTRL, 32'h0);
        axi_write(ADDR_CTRL, 32'h1);   
        repeat(7) @(posedge ACLK);
        axi_read(ADDR_RES);

        $display("\n--- After Test #1 ---");
        $display("A=%0d B=%0d en=%0b mac_out=%0d",
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.A_mac,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.B_mac,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.en_pulse,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.mac_out );

        axi_write(ADDR_OP, {16'sd3, 16'sd7});
        axi_write(ADDR_CTRL, 32'h0);
        axi_write(ADDR_CTRL, 32'h1);
        repeat(7) @(posedge ACLK);
        axi_read(ADDR_RES);

        $display("\n--- After Test #2 ---");
        $display("A=%0d B=%0d en=%0b mac_out=%0d",
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.A_mac,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.B_mac,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.en_pulse,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.mac_out );

        axi_write(ADDR_OP, { -16'sd4, 16'sd6 });
        axi_write(ADDR_CTRL, 32'h0);
        axi_write(ADDR_CTRL, 32'h1);
        repeat(7) @(posedge ACLK);
        axi_read(ADDR_RES);

        $display("\n--- After Test #3 ---");
        $display("A=%0d B=%0d en=%0b mac_out=%0d",
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.A_mac,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.B_mac,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.en_pulse,
        DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.mac_out );
            
        $display("\n===== RANDOM SIGNED TESTING START (16-bit mode) =====");

        axi_write(ADDR_CTRL, 32'h2); // bit1 = clear accumulator
        axi_write(ADDR_CTRL, 32'h0);
        repeat(5) @(posedge ACLK);
        expected_acc = 0; // software model reset AFTER HW clear

        // RANDOM TEST LOOP

        for (i = 0; i < 20; i = i + 1) begin

            A_val = ($random % 41) - 20;   // -20 to +20
            B_val = ($random % 41) - 20;
            product = A_val * B_val;
            expected_acc = expected_acc + product;
            // Write operands
            axi_write(ADDR_OP, { A_val[15:0], B_val[15:0] });
            // Generate rising enable pulse
            axi_write(ADDR_CTRL, 32'h0);
            axi_write(ADDR_CTRL, 32'h1);

            // Wait for pipeline latency
            repeat(6) @(posedge ACLK);

            axi_read(ADDR_RES); // hardware accumulator

            if ($signed(RDATA) === expected_acc)
                $display("TEST %0d: A=%0d B=%0d -> product=%0d ACC=%0d  [PASS]", i, A_val, B_val, product, RDATA);
            else
                $display("TEST %0d: A=%0d B=%0d -> product=%0d ACC=%0d expected=%0d  [FAIL]", i, A_val, B_val, product, RDATA, expected_acc);

            @(posedge ACLK);
        end

        $display("===== RANDOM SIGNED TESTING COMPLETE (16-bit mode) =====\n");

        repeat(10) @(posedge ACLK);

        $display("===== TEST COMPLETE =====");
        #50 $finish;

    end

    // VCD Dump
    initial begin
        $dumpfile("axi_mac_dp.vcd");   // VCD name

        // AXI4-Lite signals
        $dumpvars(0, Axi_Mac_dy_TB.AWADDR);
        $dumpvars(0, Axi_Mac_dy_TB.AWVALID);
        $dumpvars(0, Axi_Mac_dy_TB.AWREADY);

        $dumpvars(0, Axi_Mac_dy_TB.WDATA);
        $dumpvars(0, Axi_Mac_dy_TB.WSTRB);
        $dumpvars(0, Axi_Mac_dy_TB.WVALID);
        $dumpvars(0, Axi_Mac_dy_TB.WREADY);

        $dumpvars(0, Axi_Mac_dy_TB.BRESP);
        $dumpvars(0, Axi_Mac_dy_TB.BVALID);
        $dumpvars(0, Axi_Mac_dy_TB.BREADY);

        $dumpvars(0, Axi_Mac_dy_TB.ARADDR);
        $dumpvars(0, Axi_Mac_dy_TB.ARVALID);
        $dumpvars(0, Axi_Mac_dy_TB.ARREADY);

        $dumpvars(0, Axi_Mac_dy_TB.RDATA);
        $dumpvars(0, Axi_Mac_dy_TB.RRESP);
        $dumpvars(0, Axi_Mac_dy_TB.RVALID);
        $dumpvars(0, Axi_Mac_dy_TB.RREADY);
    end

    // Dump INTERNAL MAC signals for waveform debugging
    initial begin
        $dumpvars(0, Axi_Mac_dy_TB.DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.A_mac);
        $dumpvars(0, Axi_Mac_dy_TB.DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.B_mac);
        $dumpvars(0, Axi_Mac_dy_TB.DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.en_pulse);
        $dumpvars(0, Axi_Mac_dy_TB.DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.mac_out);
        $dumpvars(0, Axi_Mac_dy_TB.DUT.Axi4_Lite_Mac_Dy_v1_0_S00_AXI_inst.slv_reg3);
    end

    // Simple AXI handshake monitor
    initial begin
        $display("Time  AWV AWR WV WR BV BR  ARV ARR RV RR");
        forever begin
            @(posedge ACLK);
            $display("%4t   %b   %b   %b  %b  %b  %b   %b   %b   %b  %b",
                     $time,
                     AWVALID, AWREADY,
                     WVALID, WREADY,
                     BVALID, BREADY,
                     ARVALID, ARREADY,
                     RVALID, RREADY);
        end
    end

endmodule
