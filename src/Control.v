`include "Opcode.vh"
`include "ALUop.vh" 

`define IMM_I_TYPE 3'b000
`define IMM_S_TYPE 3'b001
`define IMM_B_TYPE 3'b010
`define IMM_U_TYPE 3'b011
`define IMM_J_TYPE 3'b100

`define WB_ALU  2'b00
`define WB_MEM  2'b01
`define WB_PC4  2'b10

`define PCSEL_NEXT 1'b0
`define PCSEL_JUMP 1'b1

module Control(
    input  [31:0] ex_instr,
    input  [31:0] wb_instr,
    input         ex_BrEq,
    input         ex_BrLt,

    output reg ex_BrUn,
    output reg ex_ASel,
    output reg ex_BSel,
    output reg ex_MemRW,
    output reg ex_PCSel,

    output reg [1:0] ex_fwd1,
    output reg [1:0] ex_fwd2,

    output reg ex_CSREn,

    output reg [1:0] wb_WBSel,
    output reg       wb_RegWEn
);

    wire [6:0] ex_opcode = ex_instr[6:0];
    wire [2:0] ex_funct3 = ex_instr[14:12];
    wire [4:0] ex_rd = ex_instr[11:7];
    wire [4:0] ex_rs1 = ex_instr[19:15];
    wire [4:0] ex_rs2 = ex_instr[24:20];
    wire [6:0] ex_funct7 = ex_instr[31:25];

    wire [6:0] wb_opcode = wb_instr[6:0];
    wire [2:0] wb_funct3 = wb_instr[14:12];
    wire [4:0] wb_rd = wb_instr[11:7];

    reg ex_branch_cond_met;
    reg wb_RegWEn_internal;
    reg wb_is_load;
    reg [2:0] ex_imm_sel;
    reg [3:0] ex_alu_op;
    wire ex_is_rshift_type = ex_funct7[5];

    // Determine the branch condition
    always @(*) begin
        case (ex_funct3)
            `FNC_BEQ: ex_branch_cond_met = ex_BrEq;
            `FNC_BNE: ex_branch_cond_met = ~ex_BrEq;
            `FNC_BLT: ex_branch_cond_met = ex_BrLt;
            `FNC_BGE: ex_branch_cond_met = ~ex_BrLt;
            `FNC_BLTU: ex_branch_cond_met = ex_BrLt;
            `FNC_BGEU: ex_branch_cond_met = ~ex_BrLt;
            default: ex_branch_cond_met = 1'b0;
        endcase
    end

    wire ex_branch_taken = (ex_opcode == `OPC_BRANCH) && ex_branch_cond_met;
    wire ex_jump_taken = (ex_opcode == `OPC_JAL) || (ex_opcode == `OPC_JALR);

    always @(*) begin
        ex_BrUn = 1'b0;
        ex_ASel = 1'b0;
        ex_BSel = 1'b0;
        ex_MemRW = 1'b0;
        ex_PCSel = `PCSEL_NEXT;
        ex_CSREn = 1'b0;
        ex_imm_sel = `IMM_I_TYPE;

        wb_WBSel = `WB_ALU;
        wb_RegWEn = 1'b0;
        wb_RegWEn_internal = 1'b0;
        wb_is_load = 1'b0;

        ex_fwd1 = 2'b00;
        ex_fwd2 = 2'b00;

        // Only modify the control signals that aren't already default-ly correct
        case (ex_opcode)

            `OPC_ARI_RTYPE: begin
                ex_ASel = 1'b0;
                ex_BSel = 1'b0;
            end

            `OPC_ARI_ITYPE: begin
                ex_ASel = 1'b0;
                ex_BSel = 1'b1;
                ex_imm_sel = `IMM_I_TYPE;
            end

            `OPC_LOAD: begin
                ex_ASel = 1'b0;
                ex_BSel = 1'b1;
                ex_MemRW = 1'b0;
                ex_imm_sel = `IMM_I_TYPE;
            end

            `OPC_STORE: begin
                ex_ASel = 1'b0;
                ex_BSel = 1'b1;
                ex_MemRW = 1'b1;
                ex_imm_sel = `IMM_S_TYPE;
            end

            `OPC_BRANCH: begin
                ex_ASel = 1'b1;
                ex_BSel = 1'b1;
                ex_imm_sel = `IMM_B_TYPE;
                ex_BrUn = (ex_funct3 == `FNC_BLTU) || (ex_funct3 == `FNC_BGEU);
                ex_PCSel = ex_branch_taken ? `PCSEL_JUMP : `PCSEL_NEXT;
            end

            `OPC_JAL: begin
                ex_ASel = 1'b1;
                ex_BSel = 1'b1;
                ex_imm_sel = `IMM_J_TYPE;
                ex_PCSel = `PCSEL_JUMP;
            end

            `OPC_JALR: begin
                ex_ASel = 1'b0;
                ex_BSel = 1'b1;
                ex_imm_sel = `IMM_I_TYPE;
                ex_PCSel = `PCSEL_JUMP;
            end

            `OPC_LUI: begin
                ex_ASel = 1'b0;
                ex_BSel = 1'b1;
                ex_imm_sel = `IMM_U_TYPE;
            end

            `OPC_AUIPC: begin
                ex_ASel = 1'b1;
                ex_BSel = 1'b1;
                ex_imm_sel = `IMM_U_TYPE;
            end

            `OPC_CSR: begin
                ex_imm_sel = `IMM_I_TYPE;
                case (ex_funct3)
                    `FNC_RW: begin
                        ex_ASel = 1'b0;
                        ex_CSREn = 1'b1;
                    end
                    `FNC_RWI: begin
                        ex_BSel = 1'b1;
                        ex_CSREn = 1'b1;
                    end
                endcase
            end
        endcase

        case (wb_opcode)

            `OPC_ARI_RTYPE,
            `OPC_ARI_ITYPE,
            `OPC_LUI,
            `OPC_AUIPC: begin
                wb_RegWEn = 1'b1;
                wb_WBSel = `WB_ALU;
                wb_RegWEn_internal = (wb_rd != 0);
            end

            `OPC_LOAD: begin
                wb_RegWEn = 1'b1;
                wb_WBSel = `WB_MEM;
                wb_RegWEn_internal = (wb_rd != 0);
                wb_is_load = 1'b1;
            end

            `OPC_JAL,
            `OPC_JALR: begin
                wb_RegWEn = 1'b1;
                wb_WBSel = `WB_PC4;
                wb_RegWEn_internal = (wb_rd != 0);
            end
        endcase

        if (wb_RegWEn_internal && (wb_rd == ex_rs1)) begin
            ex_fwd1 = wb_is_load ? 2'b10 : 2'b01;
        end else begin
            ex_fwd1 = 2'b00;
        end

        if (wb_RegWEn_internal && (wb_rd == ex_rs2)) begin
            ex_fwd2 = wb_is_load ? 2'b10 : 2'b01;
        end else begin
            ex_fwd2 = 2'b00;
        end
    end
endmodule
