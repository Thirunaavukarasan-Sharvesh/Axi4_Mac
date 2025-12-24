`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thirunaavukarasan S and Sriram N
// 
// Create Date: 09.12.2025 10:18:53
// Design Name: SoC top module for RISC V processor integrating RAM and MAC peripheral 
// Module Name: soc_top
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

module soc_top (
    input  wire clk,
    input  wire resetn
);

    // PicoRV32 AXI master signals

    wire        cpu_awvalid;
    wire        cpu_awready;
    wire [31:0] cpu_awaddr;
    wire [2:0]  cpu_awprot;
    wire        cpu_wvalid;
    wire        cpu_wready;
    wire [31:0] cpu_wdata;
    wire [3:0]  cpu_wstrb;
    wire        cpu_bvalid;
    wire        cpu_bready;
    wire        cpu_arvalid;
    wire        cpu_arready;
    wire [31:0] cpu_araddr;
    wire [2:0]  cpu_arprot;
    wire        cpu_rvalid;
    wire        cpu_rready;
    wire [31:0] cpu_rdata;
    wire        trap;

    // Instantiate PicoRV32 AXI CPU

    picorv32_axi #(
        .ENABLE_MUL      (0),
        .ENABLE_DIV      (0),
        .ENABLE_PCPI     (0),
        .ENABLE_IRQ      (0),
        .PROGADDR_RESET  (32'h0000_0000),
        .STACKADDR       (32'h0001_FFFC)
    ) cpu (
        .clk              (clk),
        .resetn           (resetn),
        .trap             (trap),

        .mem_axi_awvalid  (cpu_awvalid),
        .mem_axi_awready  (cpu_awready),
        .mem_axi_awaddr   (cpu_awaddr),
        .mem_axi_awprot   (cpu_awprot),

        .mem_axi_wvalid   (cpu_wvalid),
        .mem_axi_wready   (cpu_wready),
        .mem_axi_wdata    (cpu_wdata),
        .mem_axi_wstrb    (cpu_wstrb),

        .mem_axi_bvalid   (cpu_bvalid),
        .mem_axi_bready   (cpu_bready),

        .mem_axi_arvalid  (cpu_arvalid),
        .mem_axi_arready  (cpu_arready),
        .mem_axi_araddr   (cpu_araddr),
        .mem_axi_arprot   (cpu_arprot),

        .mem_axi_rvalid   (cpu_rvalid),
        .mem_axi_rready   (cpu_rready),
        .mem_axi_rdata    (cpu_rdata),

        .pcpi_valid       (),
        .pcpi_insn        (),
        .pcpi_rs1         (),
        .pcpi_rs2         (),
        .pcpi_wr          (1'b0),
        .pcpi_rd          (32'b0),
        .pcpi_wait        (1'b0),
        .pcpi_ready       (1'b0),

        .irq              (32'b0),
        .eoi              (),

        .trace_valid      (),
        .trace_data       ()
    );


    // Address decoding

    // RAM: 0x0000_0000 - 0x0001_FFFF (128 KB)
    wire sel_ram_aw = (cpu_awaddr[31:17] == 15'h0000);
    wire sel_ram_ar = (cpu_araddr[31:17] == 15'h0000);

    // MAC: 0x4000_0000 - 0x4000_0008
    wire sel_mac_aw = (cpu_awaddr[31:12] == 20'h40000);
    wire sel_mac_ar = (cpu_araddr[31:12] == 20'h40000);

    // RAM instance (simple synchronous RAM from ram.v)

    reg         ram_wen;
    reg  [3:0]  ram_wstrb;
    reg  [31:0] ram_addr;
    reg  [31:0] ram_wdata;
    wire [31:0] ram_rdata;

    ram #(
        .MEM_SIZE (128*1024),
        .INIT_FILE("firmware.hex")
    ) ram_inst (
        .clk   (clk),
        .wen   (ram_wen),
        .wstrb (ram_wstrb),
        .addr  (ram_addr),
        .wdata (ram_wdata),
        .rdata (ram_rdata)
    );

    // MAC AXI-Lite peripheral

    wire        mac_awready;
    wire        mac_wready;
    wire        mac_bvalid;
    wire [1:0]  mac_bresp;
    wire        mac_arready;
    wire        mac_rvalid;
    wire [31:0] mac_rdata;
    wire [1:0]  mac_rresp;

    Axi4_Lite_Mac_Dy_v1_0 mac_inst (
        .s00_axi_aclk    (clk),
        .s00_axi_aresetn (resetn),

        .s00_axi_awaddr  (cpu_awaddr[3:0]),
        .s00_axi_awprot  (3'b000),
        .s00_axi_awvalid (cpu_awvalid & sel_mac_aw),
        .s00_axi_awready (mac_awready),

        .s00_axi_wdata   (cpu_wdata),
        .s00_axi_wstrb   (cpu_wstrb),
        .s00_axi_wvalid  (cpu_wvalid & sel_mac_aw),
        .s00_axi_wready  (mac_wready),

        .s00_axi_bresp   (mac_bresp),
        .s00_axi_bvalid  (mac_bvalid),
        .s00_axi_bready  (cpu_bready),

        .s00_axi_araddr  (cpu_araddr[3:0]),
        .s00_axi_arprot  (3'b000),
        .s00_axi_arvalid (cpu_arvalid & sel_mac_ar),
        .s00_axi_arready (mac_arready),

        .s00_axi_rdata   (mac_rdata),
        .s00_axi_rresp   (mac_rresp),
        .s00_axi_rvalid  (mac_rvalid),
        .s00_axi_rready  (cpu_rready)
    );

    // AXI WRITE routing (RAM / MAC)

    always @(*) begin
        ram_wen   = 1'b0;
        ram_wstrb = 4'b0000;
        ram_addr  = cpu_awaddr;
        ram_wdata = cpu_wdata;

        if (sel_ram_aw && cpu_wvalid) begin
            ram_wen   = 1'b1;
            ram_wstrb = cpu_wstrb;
            ram_addr  = cpu_awaddr;
        end
    end

    assign cpu_awready = sel_ram_aw ? 1'b1 : sel_mac_aw ? mac_awready : 1'b1;
    assign cpu_wready = sel_ram_aw ? 1'b1 : sel_mac_aw ? mac_wready : 1'b1;
    assign cpu_bvalid = sel_ram_aw ? cpu_wvalid : sel_mac_aw ? mac_bvalid : 1'b1;

    // AXI READ routing (RAM / MAC)
    // ARREADY

    assign cpu_arready = sel_ram_ar ? 1'b1 : sel_mac_ar ? mac_arready : 1'b0;
    reg ram_rvalid_reg;

    always @(posedge clk) begin
        if (!resetn)
            ram_rvalid_reg <= 1'b0;
        else if (cpu_arvalid && sel_ram_ar)
            ram_rvalid_reg <= 1'b1;
        else if (cpu_rready)
            ram_rvalid_reg <= 1'b0;
    end

    assign cpu_rvalid = sel_ram_ar ? ram_rvalid_reg : sel_mac_ar ? mac_rvalid : 1'b0;
    assign cpu_rdata = sel_ram_ar ? ram_rdata : sel_mac_ar ? mac_rdata : 32'h0000_0000;

endmodule
