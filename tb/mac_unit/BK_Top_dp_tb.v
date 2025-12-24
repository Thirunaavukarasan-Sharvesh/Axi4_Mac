`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.12.2025 08:13:10
// Design Name: 
// Module Name: BK_Top_dp_tb
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
`timescale 1ns/1ps

module BK_Top_dp_tb;

    parameter WIDTH = 48;

    // DUT Inputs
    reg  [WIDTH-1:0] A, B;
    reg              Cin;

    // DUT Outputs
    wire [WIDTH-1:0] sum;
    wire             cout;

    BK_Top_dp #(.width(WIDTH)) DUT (
        .A(A),
        .B(B),
        .Cin(Cin),
        .sum(sum),
        .cout(cout)
    );

    // ---------------------------------------------
    // Variables (Declared ONLY at module level!)
    // ---------------------------------------------
    integer pm, i;
    integer actw;

    integer total_tests = 0;
    integer total_pass  = 0;
    integer total_fail  = 0;

    integer mode_pass[0:3];
    integer mode_fail[0:3];

    reg [WIDTH-1:0] mask_val;     // moved out of loop ?
    reg [WIDTH:0]   golden_val;   // moved out of loop ?

    // ---------------------------------------------
    // Precision Width function
    // ---------------------------------------------
    function integer get_prec_width;
        input integer pm;
        begin
            case(pm)
                0: get_prec_width = 8;
                1: get_prec_width = 16;
                2: get_prec_width = 32;
                3: get_prec_width = 40;
                default: get_prec_width = WIDTH;
            endcase
        end
    endfunction

    // ---------------------------------------------
    // Golden Adder
    // ---------------------------------------------
    function [WIDTH:0] golden_add;
        input [WIDTH-1:0] A_in;
        input [WIDTH-1:0] B_in;
        input              Cin_in;
        input integer      pm;
        integer actw2;
        reg [WIDTH-1:0] mask2;
        begin
            actw2 = get_prec_width(pm);

            if (actw2 == WIDTH)
                mask2 = {WIDTH{1'b1}};
            else
                mask2 = (1 << actw2) - 1;

            golden_add = (A_in & mask2) + (B_in & mask2) + Cin_in;
        end
    endfunction

    // ---------------------------------------------
    // MAIN TEST SEQUENCE
    // ---------------------------------------------
    initial begin

        $dumpfile("bk_top_dp_tb.vcd");
        $dumpvars(0, BK_Top_dp_tb);

        // Clear per-mode counters
        for (pm = 0; pm < 4; pm = pm + 1) begin
            mode_pass[pm] = 0;
            mode_fail[pm] = 0;
        end

        // --------------------------
        // Test All Precision Modes
        // --------------------------
        for (pm = 0; pm < 4; pm = pm + 1) begin

            actw = get_prec_width(pm);
            $display("\n===== Testing Precision Mode %0d (%0d bits) =====", pm, actw);

            for (i = 0; i < 20; i = i + 1) begin

                // Compute mask
                if (actw == WIDTH)
                    mask_val = {WIDTH{1'b1}};
                else
                    mask_val = (1 << actw) - 1;

                // Apply mask to random inputs
                A   = $random & mask_val;
                B   = $random & mask_val;
                Cin = $random % 2;

                #1;

                golden_val = golden_add(A, B, Cin, pm);

                total_tests = total_tests + 1;

                if (sum === golden_val[WIDTH-1:0] && cout === golden_val[WIDTH]) begin
                    mode_pass[pm] = mode_pass[pm] + 1;
                    total_pass    = total_pass + 1;
                end
                else begin
                    mode_fail[pm] = mode_fail[pm] + 1;
                    total_fail    = total_fail + 1;

                    $display("? FAIL (PM=%0d i=%0d)", pm, i);
                    $display("  A=%h", A);
                    $display("  B=%h", B);
                    $display("  Cin=%0d", Cin);
                    $display("  DUT:    sum=%h cout=%0d", sum, cout);
                    $display("  GOLDEN: sum=%h cout=%0d",
                              golden_val[WIDTH-1:0], golden_val[WIDTH]);
                end
            end

            $display("? Mode %0d Summary: PASS=%0d  FAIL=%0d",
                     pm, mode_pass[pm], mode_fail[pm]);
        end

        // --------------------------
        // FINAL SUMMARY
        // --------------------------
        $display("\n============================================");
        $display("                FINAL SUMMARY");
        $display("============================================");
        $display(" Total Tests Run  = %0d", total_tests);
        $display(" Total Passed     = %0d", total_pass);
        $display(" Total Failed     = %0d", total_fail);

        if (total_fail == 0)
            $display(" RESULT: ? ALL TESTS PASSED");
        else
            $display(" RESULT: ? SOME TESTS FAILED");

        $display("============================================\n");

        $finish;

    end

endmodule
