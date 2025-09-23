`timescale 1ns/1ps

module PG
(
    input   wire  A,B,
    output  wire  P,G
);

assign P = A ^ B;
assign G = A & B;

endmodule