`timescale 1ns/1ps

module top_tb;

parameter width = 6;

reg  [width-1:0] a, b;
reg              clk, rst_n, cin;
wire [width-1:0] sum;
wire             cout;

integer i, file, console;
reg [width-1:0] exp;
integer coverage_cnt, pass_cnt, ts;

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

// Task - result checker

task add;
input [width:0] exp_val;
begin
    if({cout,sum} !== exp_val) 
        begin
            $fdisplay(console, "[%t] FAIL! : a = %d (%b) b = %d cin = %d | sum = %d (%b) cout = %d | exp_val = %d (%b)", $realtime, a, a, b, b, cin, sum, cout, exp_val, exp_val);
        end
    else
        begin
            $fdisplay(console, "[%t] PASS! : a = %d (%b) b = %d cin = %d | sum = %d (%b) cout = %d", $realtime, a, a, b, b, cin, sum, cout);
            pass_cnt = pass_cnt + 1;
        end
end
endtask

initial begin

    $timeformat(-9, 2, " ns", 10);  // $timeformat(units, precision, suffix, minimum_field_width);
    file = $fopen("Brent_Kung_Adder.log");
    console = file | 32'b1;
    pass_cnt = 0;
    ts = 4096;
    a = 0; b = 0; cin = 0; rst_n = 1;
    #10;
    rst_n = 0; #20;
     @(negedge clk);
        rst_n = 1;
    @(negedge clk);

    $fdisplay(console, "============================================================");
    $fdisplay(console,  "   Brent-Kung %d-bit Adder Verification", width);
    $fdisplay(console, "============================================================");

    for( i = 0; i < ts; i = i + 1)
    begin
        a   =   $random; b   =   $random; cin =   $random %2;
        // repeat (4096) begin
		// 	@(posedge clk);		
		// end
        @(posedge clk);
        exp = a + b + cin;
        add(exp);
    end
    $fdisplay(console, "------------------------------------------------------------");
    $fdisplay(console, "Test cases: %0d | Passed: %0d | Failed: %0d",ts, pass_cnt, ts - pass_cnt);
    $fdisplay(console, "============================================================");
    $finish;
end

endmodule;