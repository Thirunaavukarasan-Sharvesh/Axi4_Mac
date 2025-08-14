// Black Cell : Combines two PG pairs into one group PG -> P high (Pij) G high (Gij) and the P low (Pjk) G low (Gjk)

module Black_Box
(
    input   wire  Pij , Gij,    // Propagate/Generate for upper group (i:j)
    input   wire  Pjk , Gjk,    // Propagate/Generate for lower group (j:k)
    output  wire  Pik , Gik     // Combined PG for (i:k)
);

// i -> the highest bit position in the group you’re combining
// k -> the lowest bit position in the group
// j -> a split point in between i and k where we break the group into two subgroups

assign Pik = Pij & Pjk;
assign Gik = Gij | (Pij & Gjk);

endmodule