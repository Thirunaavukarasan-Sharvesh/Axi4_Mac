`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.12.2025 19:46:17
// Design Name: 
// Module Name: mac_top_dp_tb
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

module mac_top_dp_tb;

    parameter W         = 40;
    parameter ACC_WIDTH = 32;

    // DUT I/O
    reg                     clk;
    reg                     rst_n;
    reg                     en;
    reg                     clear;
    reg      [1:0]          precision_mode;
    reg signed [W-1:0]      A;
    reg signed [W-1:0]      B;

    wire signed [ACC_WIDTH-1:0] mac_out;
    wire                        mac_ovf;

    mac_top_dp #(
        .W(W),
        .ACC_WIDTH(ACC_WIDTH)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .clear(clear),
        .precision_mode(precision_mode),
        .A(A),
        .B(B),
        .mac_out(mac_out),
        .mac_ovf(mac_ovf)
    );

    always #5 clk = ~clk;

    reg signed [31:0] golden_acc;
    reg signed [31:0] product_masked;
    reg signed [31:0] golden_acc_prev;
    
    // Operand masking - must MATCH multiplier behavior

    task mask_operand;
        input [1:0] pm;
        input signed [W-1:0] x;
        output signed [W-1:0] x_masked;
        integer w, i;
        reg signed [W-1:0] tmp;
    begin
        // active width
        case (pm)
            2'b00: w = 8;
            2'b01: w = 16;
            2'b10: w = 32;
            default: w = 40;
        endcase
        // copy lower w bits
        for (i = 0; i < w; i = i + 1)
            tmp[i] = x[i];

        // sign-extend upper bits from bit w-1
        for (i = w; i < W; i = i + 1)
            tmp[i] = x[w-1];

        x_masked = tmp;
    end
    endtask

    // GOLDEN PRODUCT = mask(A)*mask(B) THEN TRUNCATE LIKE MAC
    task mask_and_truncate_product;
        input [1:0] pm;
        input signed [W-1:0] a_in;
        input signed [W-1:0] b_in;
        output signed [31:0] masked_prod;

        reg signed [W-1:0] a_m, b_m;
        reg signed [63:0] prod_full;
    begin
        mask_operand(pm, a_in, a_m);
        mask_operand(pm, b_in, b_m);

        // Multiply masked operands
        prod_full = a_m * b_m;

        // Truncate exactly like mac_top_dp
        case (pm)
            2'b00: masked_prod = {{16{prod_full[15]}}, prod_full[15:0]}; // 16-bit product ? sign-extend
            2'b01: masked_prod = prod_full[31:0];                         // 32-bit product (16x16)
            default: masked_prod = prod_full[31:0];                       // 32/40 mode ? lower 32 bits
        endcase
    end
    endtask

    integer i;
    integer pass_cnt, fail_cnt;

    task run_precision_mode;
    input [1:0] pm;
begin
    $display("\n===== Testing Precision Mode %0d =====", pm);

    precision_mode   = pm;
    golden_acc       = 0;
    golden_acc_prev  = 0;
    clear = 1;
    en    = 0;
    repeat(2) @(posedge clk);   // keep this as 2
    clear = 0;
    pass_cnt = 0;
    fail_cnt = 0;

    for (i = 1; i <= 20; i = i + 1) begin
       
        case (pm)
            2'b00: begin
                A = $signed($random % 128);      // 8-bit-ish signed
                B = $signed($random % 128);
            end

            2'b01: begin
                A = $signed($random % 32768);    // 16-bit-ish signed
                B = $signed($random % 32768);
            end

            default: begin
                A = $signed($random);            // full 32/40-bit range
                B = $signed($random);
            end
        endcase

        @(posedge clk);
        en = 1;
        // Compute current operation's product for golden model
        mask_and_truncate_product(pm, A, B, product_masked);
        golden_acc = golden_acc + product_masked;

        // On this next clock edge the DUT accumulator updates mac_out
        @(posedge clk);
        en = 0;
        #1;

        if (mac_out === golden_acc_prev) begin
            pass_cnt = pass_cnt + 1;
        end else begin
            fail_cnt = fail_cnt + 1;
            $display("? FAIL PM=%0d i=%0d", pm, i);
            $display("  A         = %0d", A);
            $display("  B         = %0d", B);
            $display("  DUT out   = %0d", mac_out);
            $display("  GOLDEN    = %0d", golden_acc_prev);
        end

        // Update previous golden for NEXT iteration
        golden_acc_prev = golden_acc;
    end

    $display("? Mode %0d Summary: PASS=%0d FAIL=%0d", pm, pass_cnt, fail_cnt);
end
endtask

    initial begin
        clk   = 0;
        rst_n = 0;
        en    = 0;
        clear = 0;
        precision_mode = 0;
        A = 0;
        B = 0;

        repeat(5) @(posedge clk);
        rst_n = 1;
        run_precision_mode(2'b00);
        run_precision_mode(2'b01);
        run_precision_mode(2'b10);
        run_precision_mode(2'b11);

        $display("\n=====================================");
        $display(" TEST COMPLETE ");
        $display("=====================================");
        $finish;
    end

endmodule

