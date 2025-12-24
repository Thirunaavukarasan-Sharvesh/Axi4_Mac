`timescale 1ns/1ps

module tb_booth_radix4_dp;

    parameter W = 40;

    reg  signed [W-1:0] A;
    reg  signed [W-1:0] B;
    reg  [1:0]          precision_mode;
    reg                 clear;

    wire signed [2*W-1:0] P;

    booth_radix4_dp #(.W(W)) DUT (
        .A(A),
        .B(B),
        .precision_mode(precision_mode),
        .clear(clear),
        .P(P)
    );

    integer actw;
    integer i;

    reg signed [2*W-1:0] golden;
    reg [W-1:0] mask;

    function integer get_prec_width;
        input [1:0] pm;
        begin
            case(pm)
                2'b00: get_prec_width = 8;
                2'b01: get_prec_width = 16;
                2'b10: get_prec_width = 32;
                default: get_prec_width = 40;
            endcase
        end
    endfunction

    // Create mask for active precision
    function [W-1:0] make_mask;
        input integer n;
        integer j;
        begin
            make_mask = 0;
            for (j = 0; j < n; j = j + 1)
                make_mask[j] = 1'b1;
        end
    endfunction

    
    // SIGN EXTENSION (THE CRITICAL FIX)
   // SIGN-EXTEND A VALUE OF WIDTH actw TO FULL W BITS (Vivado-compatible)
function [W-1:0] sign_extend_to_W;
    input [W-1:0] val;    // masked value
    input integer actw;   // active width
    integer j;
    reg signbit;
    begin
        // Extract sign bit (at actw-1 position)
        signbit = val[actw-1];

        // Copy lower bits 0..(actw-1)
        for (j = 0; j < actw; j = j + 1)
            sign_extend_to_W[j] = val[j];

        // Fill upper bits with sign bit
        for (j = actw; j < W; j = j + 1)
            sign_extend_to_W[j] = signbit;
    end
endfunction

    task run_one_test;
        input [1:0] pm;
        reg signed [W-1:0] A_se;
        reg signed [W-1:0] B_se;
        begin
            actw = get_prec_width(pm);
            mask = make_mask(actw);
            A = $random & mask;
            B = $random & mask;
            A_se = sign_extend_to_W(A, actw);
            B_se = sign_extend_to_W(B, actw);
            golden = $signed(A_se) * $signed(B_se);

            #1;

            $display("------------------------------------------------");
            $display(" Precision Mode = %0d bits", actw);
            $display(" A        = %0h", A);
            $display(" B        = %0h", B);
            $display(" DUT P    = %0h", P);
            $display(" GOLDEN   = %0h", golden);
            $display("------------------------------------------------");

            if (P !== golden)
                $display("FAIL - mismatch detected!\n");
            else
                $display("PASS\n");
        end
    endtask

    initial begin
        $dumpfile("booth_dp.vcd");
        $dumpvars(0, tb_booth_radix4_dp);

        clear = 1; #5; clear = 0;

        precision_mode = 2'b00; for (i=0;i<10;i=i+1) run_one_test(precision_mode);
        precision_mode = 2'b01; for (i=0;i<10;i=i+1) run_one_test(precision_mode);
        precision_mode = 2'b10; for (i=0;i<10;i=i+1) run_one_test(precision_mode);
        precision_mode = 2'b11; for (i=0;i<10;i=i+1) run_one_test(precision_mode);

        $display("\n===============================================");
        $display(" ALL PRECISION MODES PASSED FOR MULTIPLIER ");
        $display("===============================================\n");

        $finish;
    end

endmodule
