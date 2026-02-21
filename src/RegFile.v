module RegFile (
    input [4:0] rs2_addr, // these 4 bits will be handled by the module instantiating RegFile
    input [4:0] rs1_addr, // so will these
    input [4:0] rd_addr,  // and these
    input [31:0] wdata,
    input RegWEn,
    input clk,

    input reset,

    output [31:0] rs1_data,
    output [31:0] rs2_data
);

    // An array of 32 registers, each 32 bits wide
    reg [31:0] regs [0:31];

    // Read ports
    assign rs1_data = (rs1_addr != 0) ? regs[rs1_addr] : 32'b0;
    assign rs2_data = (rs2_addr != 0) ? regs[rs2_addr] : 32'b0;

    // Write port  
    always @(posedge clk) begin
        // Handle reset FIRST, with higher priority
        if (reset) begin
            // Initialize all registers to zero on reset
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else if (RegWEn && (rd_addr != 0)) begin
            regs[rd_addr] <= wdata;
        end
    end

endmodule