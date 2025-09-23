`timescale 1ns/1ps

module top_tb;

parameter width = 6;

reg  [width-1:0] a, b;
reg              clk, rst_n, cin;
wire [width-1:0] sum;
wire             cout;

integer i, j, k, file;
reg [width:0] exp;
integer pass_cnt, fail_cnt, total_tests;

Top #(.width(width)) dut
(
    .A(a),
    .B(b),
    .Cin(cin),
    .clk(clk),
    .rst_n(rst_n),
    .sum(sum),
    .cout(cout)
);

initial clk = 0;
always #5 clk = ~clk;

task check_result;
input [width-1:0] test_a, test_b;
input test_cin;
input [width:0] expected;
    if({cout,sum} !== expected) 
        begin
            $fdisplay(file, "[%t] FAIL! : a = %d (%b) b = %d (%b) cin = %d | sum = %d (%b) cout = %d | exp = %d (%b)", 
                     $realtime, test_a, test_a, test_b, test_b, test_cin, sum, sum, cout, expected, expected);
            $display("FAIL: a=%d b=%d cin=%d | got=%d expected=%d", test_a, test_b, test_cin, {cout,sum}, expected);
            fail_cnt = fail_cnt + 1;
        end
    else
        begin
            if (pass_cnt % 1000 == 0) begin
                $fdisplay(file, "[%t] PASS! : a = %d (%b) b = %d (%b) cin = %d | sum = %d (%b) cout = %d", 
                         $realtime, test_a, test_a, test_b, test_b, test_cin, sum, sum, cout);
            end
            pass_cnt = pass_cnt + 1;
        end
endtask

initial begin
    $timeformat(-9, 2, " ns", 10);
    
    file = $fopen("C:/Users/thiru/Music/Final_Year_Project/Axi4_Mac/MAC_Unit/src/Adder/Brent_Kung_Adder.log", "w");
    if (file == 0) begin
        $display("ERROR: Could not open log file!");
        $finish;
    end
    
    $fdisplay(file, "Log Start");
    pass_cnt = 0;
    fail_cnt = 0;
    total_tests = 0;
    
    // Reset sequence
    a = 0; b = 0; cin = 0; rst_n = 0;
    #20;
    rst_n = 1;
    @(posedge clk);
    
    $fdisplay(file, "============================================================");
    $fdisplay(file, "   Brent-Kung %d-bit Adder EXHAUSTIVE Verification", width);
    $fdisplay(file, "   Testing ALL possible combinations systematically");
    $fdisplay(file, "============================================================");
    
    $display("Starting EXHAUSTIVE test of all %d combinations...", (1<<width) * (1<<width) * 2);

    // SYSTEMATIC APPROACH: Test every single possible combination
    for (i = 0; i < (1 << width); i = i + 1) begin        // a: 0 to 63
        for (j = 0; j < (1 << width); j = j + 1) begin    // b: 0 to 63  
            for (k = 0; k < 2; k = k + 1) begin           // cin: 0 to 1
                
                // Set inputs
                a = i;
                b = j; 
                cin = k;
                
                // Wait for combinational logic + register
                @(posedge clk);
                #1; // Small delay for signal settling
                
                // Calculate expected result
                exp = i + j + k;
                
                // Check result
                check_result(i, j, k, exp);
                total_tests = total_tests + 1;
                
                // Progress update every 1024 tests
                if (total_tests % 1024 == 0) begin
                    $display("Progress: %d/%d tests | Pass: %d | Fail: %d | Current: a=%d b=%d cin=%d", 
                            total_tests, 8192, pass_cnt, fail_cnt, i, j, k);
                    $fflush(file);
                    
                    // Early exit on failures (indicates design problem)
                    if (fail_cnt > 5) begin
                        $display("ERROR: Multiple failures detected. Design may have issues.");
                        $display("Stopping at test %d to investigate.", total_tests);
                        //break;
                    end
                end
            end
        end
    end

    // Final summary
    $fdisplay(file, "------------------------------------------------------------");
    $fdisplay(file, "EXHAUSTIVE TEST COMPLETE");
    $fdisplay(file, "Total combinations tested: %d", total_tests);
    $fdisplay(file, "Passed: %d | Failed: %d", pass_cnt, fail_cnt);
    if (total_tests > 0) begin
        $fdisplay(file, "Pass Rate: %0.2f%%", (pass_cnt * 100.0) / total_tests);
    end
    $fdisplay(file, "============================================================");
    
    $display("============================================================");
    $display("EXHAUSTIVE VERIFICATION COMPLETE!");
    $display("Total combinations tested: %d out of %d possible", total_tests, 8192);
    $display("Passed: %d | Failed: %d", pass_cnt, fail_cnt);
    if (total_tests > 0) begin
        $display("Pass Rate: %0.2f%%", (pass_cnt * 100.0) / total_tests);
        if (fail_cnt == 0) begin
            $display("*** PERFECT! ALL TESTS PASSED! ***");
            $display("Your 6-bit Brent-Kung adder is 100%% verified!");
        end
    end
    $display("============================================================");
    
    $fclose(file);
    $finish;
end

endmodule