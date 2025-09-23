`timescale 1ns/1ps

module top_tb;

  parameter int width = 40;

  // DUT signals
  logic [width-1:0] a, b;
  logic             clk, rst_n, cin;
  logic [width-1:0] sum;
  logic             cout;

  // For tracking expected results
  logic [width-1:0] a_prev, b_prev;
  logic             cin_prev;
  logic [width:0]   exp;

  int i, file;
  int pass_cnt, fail_cnt;
  int ts; // total simulations

  // Temporary vars for randomization
  logic [width-1:0] rand_a, rand_b;
  logic             rand_cin;

  // Struct to store used inputs for uniqueness
  typedef struct packed {
    logic [width-1:0] a, b;
    logic             cin;
  } txn_t;

  txn_t used_inputs[$]; // dynamic array of past inputs

  // DUT instantiation (match actual ports!)
  BK_Top #(.width(width)) dut (
      .A(a),
      .B(b),
      .Cin(cin),
      .clk(clk),
      .rst_n(rst_n),
      .sum(sum),
      .cout(cout)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Waveform dump
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, top_tb);
  end

  // Reset sequence
  initial begin
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
  end

  // Task: Check result (Scoreboard)
  task automatic check_add(input logic [width:0] exp_val);
    if ({cout,sum} !== exp_val) begin
      $fdisplay(file, "[%0t] FAIL: a=%0d b=%0d cin=%0d | sum=%0d cout=%0d | exp=%0d", $realtime, a_prev, b_prev, cin_prev, sum, cout, exp_val);
      fail_cnt++;
    end
    else begin
      $fdisplay(file, "[%0t] PASS: a=%0d b=%0d cin=%0d | sum=%0d cout=%0d", $realtime, a_prev, b_prev, cin_prev, sum, cout);
      pass_cnt++;
    end
  endtask

  function bit already_used(logic [width-1:0] aa,logic [width-1:0] bb,logic cc);
    for (int j = 0; j < used_inputs.size(); j++) begin
      if (used_inputs[j].a == aa && used_inputs[j].b == bb && used_inputs[j].cin == cc)
        return 1;
    end
    return 0;
 endfunction

  // Stimulus
  initial begin
    $timeformat(-9,2," ns",10);

    // Open log file
    file = $fopen("Brent_Kung_Adder.log","w");
    if (file==0) begin
      $error("Cannot open log file!");
      $finish;
    end

    pass_cnt = 0;
    fail_cnt = 0;
    ts = 100; // total test vectors (adjustable)

    // Banner
    $fdisplay(file, "============================================================");
    $fdisplay(file, "   Brent-Kung %0d-bit Adder Verification", width);
    $fdisplay(file, "============================================================");

    // Test loop
    for (i=0; i<ts; i++) begin
      a_prev   = a;
      b_prev   = b;
      cin_prev = cin;

      // Generate unique random inputs
      do begin
        void'(std::randomize(rand_a));
        void'(std::randomize(rand_b));
        void'(std::randomize(rand_cin) with { rand_cin inside {0,1}; });
      end while (already_used(rand_a, rand_b, rand_cin));


      // Store in used list
      used_inputs.push_back('{rand_a, rand_b, rand_cin});

      // Apply to DUT
      a   = rand_a;
      b   = rand_b;
      cin = rand_cin;

      @(posedge clk);

      // Compute expected sum
      exp = {1'b0,a_prev} + {1'b0,b_prev} + cin_prev;

      // Check result
      check_add(exp);
      $fflush(file);
    end

    // Summary
    $fdisplay(file,"------------------------------------------------------------");
    $fdisplay(file,"Test cases: %0d | Passed: %0d | Failed: %0d", ts, pass_cnt, fail_cnt);
    $fdisplay(file,"============================================================");

    $display("Simulation completed. Results written to Brent_Kung_Adder.log");
    $finish;
  end

endmodule
