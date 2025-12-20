// Module: ALU.v
// Desc:   32-bit ALU for the RISC-V Processor
// Inputs: 
//    A: 32-bit value
//    B: 32-bit value
//    ALUop: Selects the ALU's operation 
// 						
// Outputs:
//    Out: The chosen function mapped to A and B.

`include "Opcode.vh"
`include "ALUop.vh"

module ALU(
    input [31:0] A, B,
    input [3:0] ALUop,
    output [31:0] Out
);

reg signed [31:0] A_signed, B_signed;
reg [31:0] Out_reg;

assign Out = Out_reg;

always @(*) begin
    case (ALUop)
        `ALU_ADD: Out_reg = A + B;
        `ALU_SUB: Out_reg = A - B;
        `ALU_AND: Out_reg = A & B;
        `ALU_OR: Out_reg = A | B;
        `ALU_XOR: Out_reg = A ^ B;
        `ALU_SLT: begin
            A_signed = A;
            B_signed = B;
            Out_reg = (A_signed < B_signed ? 1 : 0);
        end
        `ALU_SLTU: Out_reg = (A < B ? 1 : 0);
        `ALU_SLL: Out_reg = A << B[4:0];
        `ALU_SRA: begin
            A_signed = A;
            Out_reg = A_signed >>> B[4:0];
        end
        `ALU_SRL: Out_reg = A >> B[4:0];
        `ALU_COPY_B: Out_reg = B;
        `ALU_COPY_A: Out_reg = A;
        `ALU_XXX: Out_reg = 0;
        default: Out_reg = 0;
    endcase
end
endmodule
