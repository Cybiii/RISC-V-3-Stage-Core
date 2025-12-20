module BranchComp(

    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input BrUn,              // 1 = unsigned comparison, 0 = signed comparison

    output BrEq,
    output BrLt

);

    // Signed comparison wires
    wire signed [31:0] rs1_signed = $signed(rs1_data);
    wire signed [31:0] rs2_signed = $signed(rs2_data);
    
    // Equal comparison
    assign BrEq = (rs1_data == rs2_data);

    // Less than comparison
    assign BrLt = BrUn ? (rs1_data < rs2_data) : (rs1_signed < rs2_signed);

endmodule