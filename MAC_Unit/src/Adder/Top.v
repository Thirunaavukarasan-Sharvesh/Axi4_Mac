// Brent_Kung_6bit:
//   Stage0_PG: # Single-bit PG cells
//     PG0: {in: [A0, B0], out: [P0, G0]}
//     PG1: {in: [A1, B1], out: [P1, G1]}
//     PG2: {in: [A2, B2], out: [P2, G2]}
//     PG3: {in: [A3, B3], out: [P3, G3]}
//     PG4: {in: [A4, B4], out: [P4, G4]}
//     PG5: {in: [A5, B5], out: [P5, G5]}

//   Stage1_Black: # First-level merges
//     B1:  {in: [P1, G1, P0, G0], out: [P1_0, G1_0]}
//     B3:  {in: [P3, G3, P2, G2], out: [P3_2, G3_2]}
//     B5:  {in: [P5, G5, P4, G4], out: [P5_4, G5_4]}

//   Stage2_Black: # Second-level merges
//     B3_0: {in: [P3_2, G3_2, P1_0, G1_0], out: [P3_0, G3_0]}

//   Stage3_Black: # Root merge
//     B5_0: {in: [P5_4, G5_4, P3_0, G3_0], out: [P5_0, G5_0]}

//   Stage4_Grey: # Final carry outputs
//     Gray2: {in: [P2, G2, G1_0], out: [G2_0]}   # Carry into bit3
//     Gray4: {in: [P4, G4, G3_0], out: [G4_0]}   # Carry into bit5
//     Gray5: {in: [P5, G5, G4_0], out: [G5_0]}   # Final carry-out

module Brent_Kung_addr#(
    parameter width = 6
)
(
    input  wire [width-1:0]   A,
    input  wire [width-1:0]   B,
    input  wire             Cin,
    input  wire             clk,
    input  wire             rst_n,
    output reg [width-1:0] sum,
    output reg             cout
);

wire c0, c1, c2, c3, c4, c5, c6;
// instaniation of PG block 

wire P0, P1, P2, P3, P4, P5;
wire G0, G1, G2, G3, G4, G5;

PG pg0(.A(A[0]), .B(B[0]), .P(P0), .G(G0));
PG pg1(.A(A[1]), .B(B[1]), .P(P1), .G(G1));
PG pg2(.A(A[2]), .B(B[2]), .P(P2), .G(G2));
PG pg3(.A(A[3]), .B(B[3]), .P(P3), .G(G3));
PG pg4(.A(A[4]), .B(B[4]), .P(P4), .G(G4));
PG pg5(.A(A[5]), .B(B[5]), .P(P5), .G(G5));

// instaniation of the black box 

wire P1_0, P3_2, P5_4;
wire G1_0, G3_2, G5_4;

Black_Box bb1(.Pij(P1), .Gij(G1), .Pjk(P0), .Gjk(G0), .Pik(P1_0), .Gik(G1_0));
Black_Box bb3(.Pij(P3), .Gij(G3), .Pjk(P2), .Gjk(G2), .Pik(P3_2), .Gik(G3_2));
Black_Box bb5(.Pij(P5), .Gij(G5), .Pjk(P4), .Gjk(G4), .Pik(P5_4), .Gik(G5_4));

// 2nd time 

wire P3_0, G3_0;

Black_Box bb3_0(.Pij(P3_2), .Gij(G3_2), .Pjk(P1_0), .Gjk(G1_0), .Pik(P3_0), .Gik(G3_0));

// stage 3 

wire P5_0, G5_0;

Black_Box bb5_0(.Pij(P5_4), .Gij(G5_4), .Pjk(P3_0), .Gjk(G3_0), .Pik(P5_0), .Gik(G5_0));

// instanitation of Grey Block

wire G2_0, G4_0;

Grey_Box gb2(.Pij(P2), .Gij(G2), .Gjk(G1_0), .Gik(G2_0));
Grey_Box gb4(.Pij(P4), .Gij(G4), .Gjk(G3_0), .Gik(G4_0));

//Carry signals and sum declarations

assign c0 = Cin;
assign c1 = G0  | (P0 & Cin);
assign c2 = G1_0 | (P1_0 & Cin);
assign c3 = G2_0 | (P2 & Cin);
assign c4 = G3_0 | (P3_0 & Cin);
assign c5 = G4_0 | (P4 & Cin);
assign c6 = G5_0 | (P5 & Cin);

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        begin
            {sum,cout} <= 0;
        end

    else
        begin
            //sum 
             sum[0] <= P0 ^ c0;
             sum[1] <= P1 ^ c1;
             sum[2] <= P2 ^ c2;
             sum[3] <= P3 ^ c3;
             sum[4] <= P4 ^ c4;
             sum[5] <= P5 ^ c5;
             cout   <= c6;
        end
end

endmodule