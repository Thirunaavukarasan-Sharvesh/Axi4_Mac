`timescale 1ns/1ps

module BK_Top #(parameter width = 40)(
    input                  clk,
    input                  rst_n,
    input  [width-1:0]     A,
    input  [width-1:0]     B,
    input                  Cin,
    output reg [width-1:0] sum,
    output reg             cout
);

    wire [width-1:0] p, g;     
    wire [width:0]   c; 
    assign c[0] = Cin;

    //==========================================================
    // Step 1: PG boxes
    //==========================================================
    genvar i;
    generate
        for (i = 0; i < width; i = i + 1) begin : gen_pg
            PG pg_box (
                .A(A[i]),
                .B(B[i]),
                .P(p[i]),
                .G(g[i])
            );
        end
    endgenerate

    //==========================================================
    // Step 2: Prefix Tree (Brent-Kung)
    //==========================================================
    // NOTE: For clarity, this is not fully expanded.
    // Normally you connect multiple BlackCells and GreyCells
    // layer by layer depending on 'width'.
    // Example below shows for width=8, scale similarly for 40.
    //==========================================================

    wire [width-1:0] G [0:$clog2(width)];
    wire [width-1:0] P [0:$clog2(width)];

    // Initialize level 0
    generate
        for (i = 0; i < width; i = i + 1) begin : init_level
            assign G[0][i] = g[i];
            assign P[0][i] = p[i];
        end
    endgenerate

    // Build prefix tree using BlackCell/GreyCell

    genvar j, k;
    generate
        for (j = 1; j <= $clog2(width); j = j + 1) begin : levels
            for (k = 0; k < width; k = k + 1) begin : cells
                if (k >= (1 << (j-1))) begin
                    Black_Box bc (
                        .Gjk(G[j-1][k-(1<<(j-1))]),
                        .Pjk(P[j-1][k-(1<<(j-1))]),
                        .Gij(G[j-1][k]),
                        .Pij(P[j-1][k]),
                        .Gik(G[j][k]),
                        .Pik(P[j][k])
                    );
                end else begin
                    assign G[j][k] = G[j-1][k];
                    assign P[j][k] = P[j-1][k];
                end
            end
        end
    endgenerate

    // Carries from grey cells

    generate
        for (i = 0; i < width; i = i + 1) begin : carry_assign
            Grey_Box gc (
                .Gjk(c[0]),
                .Pij(P[$clog2(width)][i]),
                .Gij(G[$clog2(width)][i]),
                .Gik(c[i+1])
            );
        end
    endgenerate

    //==========================================================
    // Step 3: Final sum and cout
    //==========================================================
    wire [width-1:0] sum_comb;
    wire cout_comb;

    assign sum_comb  = p ^ c[width-1:0];
    assign cout_comb = c[width];

    // Sequential outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum  <= {width{1'b0}};
            cout <= 1'b0;
        end else begin
            sum  <= sum_comb;
            cout <= cout_comb;
        end
    end

endmodule
