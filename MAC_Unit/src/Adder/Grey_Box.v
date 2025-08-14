module Grey_Box
(
    input  wire  Pij,Gij,Gjk,
    output wire  Gik
);

assign Gik = Gij | (Pij & Gjk);

endmodule