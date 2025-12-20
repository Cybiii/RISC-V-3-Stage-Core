`include "Opcode.vh"

module PartialStore(
    input  [31:0] id_instr,
    input  [31:0] ex_mem_addr,
    input  [31:0] ex_rs2_data,
    input         ex_MemRW,
    output reg [31:0] ex_store_data,
    output reg [3:0]  ex_write_mask
);

    always @(*) begin
        if (!ex_MemRW) begin
            ex_store_data = 32'b0;
            ex_write_mask = 4'b0000;
        end else begin
            case (id_instr[14:12])
                `FNC_SB: begin
                    case (ex_mem_addr[1:0])
                        2'b00: begin
                            ex_store_data = {24'b0, ex_rs2_data[7:0]};
                            ex_write_mask = 4'b0001;
                        end
                        2'b01: begin
                            ex_store_data = {16'b0, ex_rs2_data[7:0], 8'b0};
                            ex_write_mask = 4'b0010;
                        end
                        2'b10: begin
                            ex_store_data = {8'b0, ex_rs2_data[7:0], 16'b0};
                            ex_write_mask = 4'b0100;
                        end
                        2'b11: begin
                            ex_store_data = {ex_rs2_data[7:0], 24'b0};
                            ex_write_mask = 4'b1000;
                        end
                        default: begin
                            ex_store_data = 32'b0;
                            ex_write_mask = 4'b0000;
                        end
                    endcase
                end

                `FNC_SH: begin
                    case (ex_mem_addr[1])
                        1'b0: begin
                            ex_store_data = {16'b0, ex_rs2_data[15:0]};
                            ex_write_mask = 4'b0011;
                        end
                        1'b1: begin
                            ex_store_data = {ex_rs2_data[15:0], 16'b0};
                            ex_write_mask = 4'b1100;
                        end
                        default: begin
                            ex_store_data = 32'b0;
                            ex_write_mask = 4'b0000;
                        end
                    endcase
                end

                `FNC_SW: begin
                    ex_store_data = ex_rs2_data;
                    ex_write_mask = 4'b1111;
                end

                default: begin
                    ex_store_data = 32'b0;
                    ex_write_mask = 4'b0000;
                end
            endcase
        end
    end

endmodule
