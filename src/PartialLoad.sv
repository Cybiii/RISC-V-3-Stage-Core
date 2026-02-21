`include "Opcode.vh"

module PartialLoad(
    input  [31:0] wb_instr,
    input  [31:0] wb_mem_addr,
    input  [31:0] mem_rdata,
    output reg [31:0] mem_load_data
);

    always @(*) begin
        if (wb_instr[14:12] == `FNC_LB) begin
            case (wb_mem_addr[1:0])
                2'b00: mem_load_data = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
                2'b01: mem_load_data = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
                2'b10: mem_load_data = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
                2'b11: mem_load_data = {{24{mem_rdata[31]}}, mem_rdata[31:24]};
                default: mem_load_data = 32'b0;
            endcase

        end else if (wb_instr[14:12] == `FNC_LH) begin
            case (wb_mem_addr[1])
                1'b0: mem_load_data = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
                1'b1: mem_load_data = {{16{mem_rdata[31]}}, mem_rdata[31:16]};
                default: mem_load_data = 32'b0;
            endcase

        end else if (wb_instr[14:12] == `FNC_LW) begin
            mem_load_data = mem_rdata;

        end else if (wb_instr[14:12] == `FNC_LBU) begin
            case (wb_mem_addr[1:0])
                2'b00: mem_load_data = {24'b0, mem_rdata[7:0]};
                2'b01: mem_load_data = {24'b0, mem_rdata[15:8]};
                2'b10: mem_load_data = {24'b0, mem_rdata[23:16]};
                2'b11: mem_load_data = {24'b0, mem_rdata[31:24]};
                default: mem_load_data = 32'b0;
            endcase

        end else if (wb_instr[14:12] == `FNC_LHU) begin
            case (wb_mem_addr[1])
                1'b0: mem_load_data = {16'b0, mem_rdata[15:0]};
                1'b1: mem_load_data = {16'b0, mem_rdata[31:16]};
                default: mem_load_data = 32'b0;
            endcase

        end else begin
            mem_load_data = 32'b0;
        end
    end

endmodule
