`timescale 1ns/1ps

module accumulator_bk_dp_tb;

    parameter ACCW = 32;

    reg clk, rst_n, clear, en;
    reg [1:0] precision_mode;
    reg signed [ACCW-1:0] data_in;

    wire signed [ACCW-1:0] acc_out;
    wire ovf_flag;

    accumulator_dp #(.ACC_WIDTH(ACCW)) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .en(en),
        .precision_mode(precision_mode),
        .data_in(data_in),
        .acc_out(acc_out),
        .ovf_flag(ovf_flag)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Golden accumulator
    reg signed [31:0] golden_acc;

    integer pm, i;
    integer total_tests = 0;
    integer total_pass  = 0;
    integer total_fail  = 0;

    integer mode_pass0, mode_pass1, mode_pass2;
    integer mode_fail0, mode_fail1, mode_fail2;

    function integer get_prec_width(input [1:0] pm);
        case (pm)
            2'b00: get_prec_width = 16;
            2'b01: get_prec_width = 32;
            default: get_prec_width = 32;
        endcase
    endfunction

    function [31:0] mask_input;
        input [31:0] val;
        input [1:0] pm;

        integer aw, k;
        reg signbit;
        reg [31:0] out;
    begin
        aw = get_prec_width(pm);
        signbit = val[aw-1];

        for (k = 0; k < aw; k = k + 1)
            out[k] = val[k];

        for (k = aw; k < 32; k = k + 1)
            out[k] = signbit;

        mask_input = out;
    end
    endfunction

    initial begin
        $dumpfile("accumulator_bk_dp_tb.vcd");
        $dumpvars(0, accumulator_bk_dp_tb);

        clear = 0;
        en = 0;
        data_in = 0;

        mode_pass0 = 0;
        mode_pass1 = 0;
        mode_pass2 = 0;

        mode_fail0 = 0;
        mode_fail1 = 0;
        mode_fail2 = 0;

        rst_n = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // Test 3 precision modes (0,1,2)
        for (pm = 0; pm < 3; pm = pm + 1) begin

            precision_mode = pm;
            golden_acc = 0;

            $display("\n===== Testing Precision Mode %0d =====", pm);

            for (i = 0; i < 20; i = i + 1) begin
            
                // Generate test data
                data_in = mask_input($random, pm);
                clear = (i == 0);
                en = 1;

                // Apply inputs at clock edge
                @(posedge clk);
                
                // Update golden model
                if (clear)
                    golden_acc = 0;
                else
                    golden_acc = golden_acc + mask_input(data_in, pm);

                // Wait for DUT to update (one more clock)
                @(posedge clk);
                #1; // Small delta delay to ensure signals settle

                // Now check the result
                total_tests = total_tests + 1;

                if (acc_out === golden_acc) begin
                    total_pass = total_pass + 1;

                    case(pm)
                        0: mode_pass0 = mode_pass0 + 1;
                        1: mode_pass1 = mode_pass1 + 1;
                        2: mode_pass2 = mode_pass2 + 1;
                    endcase
                end
                else begin
                    total_fail = total_fail + 1;

                    case(pm)
                        0: mode_fail0 = mode_fail0 + 1;
                        1: mode_fail1 = mode_fail1 + 1;
                        2: mode_fail2 = mode_fail2 + 1;
                    endcase

                    $display("? FAIL PM=%0d i=%0d", pm, i);
                    $display("  data_in   = %h", data_in);
                    $display("  DUT out   = %h", acc_out);
                    $display("  GOLDEN    = %h", golden_acc);
                end
            end

            $display("? Mode %0d Summary: PASS=%0d FAIL=%0d",
                pm,
                (pm==0)?mode_pass0:(pm==1)?mode_pass1:mode_pass2,
                (pm==0)?mode_fail0:(pm==1)?mode_fail1:mode_fail2
            );

        end

        // Final summary
        $display("\n=====================================");
        $display(" FINAL SUMMARY");
        $display("=====================================");
        $display(" Total Tests = %0d", total_tests);
        $display(" Passed      = %0d", total_pass);
        $display(" Failed      = %0d", total_fail);
        $display("=====================================\n");

        $finish;
    end

endmodule