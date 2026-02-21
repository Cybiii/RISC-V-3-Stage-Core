`include "Opcode.vh"
`include "ALUop.vh"

module ALUdec(
  input [6:0]       opcode,
  input [2:0]       funct,
  input             add_rshift_type,
  output reg [3:0]  ALUop
);

  // Implement your ALU decoder here, then delete this comment
  always @(*) begin
    case(opcode)
      `OPC_ARI_ITYPE: begin
        // I-type arithmetic instructions
        case(funct)
          `FNC_ADD_SUB: ALUop = `ALU_ADD; // addi no subi
          `FNC_SLL: ALUop = `ALU_SLL;
          `FNC_SLT: ALUop = `ALU_SLT;
          `FNC_SLTU: ALUop = `ALU_SLTU;
          `FNC_XOR: ALUop = `ALU_XOR;
          `FNC_OR: ALUop = `ALU_OR;
          `FNC_AND: ALUop = `ALU_AND;
          `FNC_SRL_SRA: ALUop = add_rshift_type ? `ALU_SRA : `ALU_SRL;
          default: ALUop = `ALU_XXX;
        endcase
      end
      `OPC_ARI_RTYPE: begin
        // R-type arithmetic instructions
        case(funct)
          `FNC_ADD_SUB: ALUop = add_rshift_type ? `ALU_SUB : `ALU_ADD;
          `FNC_SLL: ALUop = `ALU_SLL;
          `FNC_SLT: ALUop = `ALU_SLT;
          `FNC_SLTU: ALUop = `ALU_SLTU;
          `FNC_XOR: ALUop = `ALU_XOR;
          `FNC_OR: ALUop = `ALU_OR;
          `FNC_AND: ALUop = `ALU_AND;
          `FNC_SRL_SRA: ALUop = add_rshift_type ? `ALU_SRA : `ALU_SRL;
          default: ALUop = `ALU_XXX;
        endcase
      end
      `OPC_LUI: begin
        ALUop = `ALU_COPY_B;
      end

      `OPC_AUIPC, `OPC_BRANCH, `OPC_JAL, `OPC_JALR, `OPC_STORE, `OPC_LOAD: begin
        ALUop = `ALU_ADD;
      end

      `OPC_CSR: begin
        case (funct)
          `FNC_RW: ALUop = `ALU_COPY_A;
          `FNC_RWI: ALUop = `ALU_COPY_B;
          default: ALUop = `ALU_XXX;
        endcase
      end

      default:
        ALUop = `ALU_XXX;
    endcase
  end
endmodule
