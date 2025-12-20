`include "Opcode.vh"

module ImmGen(
    input  [31:0] id_instr,
    output reg [31:0] id_imm
);

    always @(*) begin
        case (id_instr[6:0])

            `OPC_LOAD,
            `OPC_JALR,
            `OPC_ARI_ITYPE: begin
                id_imm = {{20{id_instr[31]}}, id_instr[31:20]};
            end

            `OPC_STORE: begin
                id_imm = {{20{id_instr[31]}}, id_instr[31:25], id_instr[11:7]};
            end

            `OPC_BRANCH: begin
                id_imm = {{19{id_instr[31]}}, id_instr[31], id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0};
            end

            `OPC_LUI,
            `OPC_AUIPC: begin
                id_imm = {id_instr[31:12], 12'b0};
            end

            `OPC_JAL: begin
                id_imm = {{11{id_instr[31]}}, id_instr[31], id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0};
            end

            `OPC_CSR: begin
                id_imm = {27'b0, id_instr[19:15]};
            end

            default: begin
                id_imm = 32'b0;
            end
        endcase
    end

endmodule
