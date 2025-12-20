`include "const.vh"
`include "Opcode.vh"

module Riscv151(
  input clk,
  input reset,

  // Memory system ports
  output [31:0] dcache_addr,
  output [31:0] icache_addr,
  output [3:0] dcache_we,
  output reg dcache_re,
  output icache_re,
  output [31:0] dcache_din,
  input [31:0] dcache_dout,
  input [31:0] icache_dout,
  input stall,
  output [31:0] csr
);

  reg [31:0] pc_reg;
  reg [31:0] ex_pc;
  reg [31:0] wb_alu_out;
  reg [31:0] wb_pc;
  reg [31:0] wb_instr;
  reg [31:0] csr_tohost;
  reg ex_nop;

  reg [31:0] wb_wdata;
  wire [31:0] id_rs1_data;
  wire [31:0] id_rs2_data;
  reg [31:0] ex_rs1_data;
  reg [31:0] ex_rs2_data;
  wire [3:0] ex_ALUop;
  reg [31:0] ex_alu_a;
  reg [31:0] ex_alu_b;
  wire [31:0] ex_alu_out;
  wire [31:0] id_imm;
  wire [31:0] mem_load_data;
  reg [31:0] ex_instr;

  // control
  wire wb_RegWEn;
  wire ex_BrUn;
  wire ex_BrEq;
  wire ex_BrLt;
  wire ex_MemRW;
  wire ex_ASel;
  wire ex_BSel;
  wire ex_PCSel;
  wire [1:0] wb_WBSel;
  wire ex_CSREn;
  wire [1:0] ex_fwd1;
  wire [1:0] ex_fwd2;

  assign icache_re = ~stall;
  assign icache_addr = pc_reg;
  assign dcache_addr = ex_alu_out;
  assign csr = csr_tohost;


  // ============================================================================
  // COMBINATIONAL LOGIC
  // ============================================================================


  always @(*) begin
    dcache_re = 0;

    if (ex_nop) ex_instr = `INSTR_NOP;
    else ex_instr = icache_dout;

    case (ex_fwd1)
      2'b00: ex_rs1_data = id_rs1_data;
      2'b01: ex_rs1_data = wb_alu_out;
      2'b10: ex_rs1_data = mem_load_data;
      default: ex_rs1_data = id_rs1_data;
    endcase

    case (ex_fwd2)
      2'b00: ex_rs2_data = id_rs2_data;
      2'b01: ex_rs2_data = wb_alu_out;
      2'b10: ex_rs2_data = mem_load_data;
      default: ex_rs2_data = id_rs2_data;
    endcase

    if (ex_ASel) ex_alu_a = ex_pc;
    else ex_alu_a = ex_rs1_data;

    if (ex_BSel) ex_alu_b = id_imm;
    else ex_alu_b = ex_rs2_data;

    case (wb_WBSel)
      2'b00: wb_wdata = wb_alu_out;
      2'b01: wb_wdata = mem_load_data;
      2'b10: wb_wdata = wb_pc + 4;
      default: wb_wdata = 32'b0;
    endcase
    
    if (ex_instr[6:0] == `OPC_LOAD)
      dcache_re = 1'b1;
  end


  // ============================================================================
  // SEQUENTIAL LOGIC
  // ============================================================================


  always @(posedge clk) begin
    if (reset) begin
      pc_reg <= `PC_RESET;
      ex_pc <= 32'h0;
      wb_alu_out <= 32'h0;
      wb_pc <= 32'h0;
      wb_instr <= `INSTR_NOP;
      csr_tohost <= 32'b0;
      ex_nop <= 1'b0;
    end
    else if (!stall) begin
      case (ex_PCSel)
        1'b0: pc_reg <= pc_reg + 4;
        1'b1: pc_reg <= ex_alu_out;
      endcase

      ex_pc <= pc_reg;
      wb_pc <= ex_pc;
      wb_alu_out <= ex_alu_out;
      wb_instr <= ex_instr;
      ex_nop <= ex_PCSel;

      if (ex_CSREn)
        csr_tohost <= ex_alu_out;
    end
  end


  // ============================================================================
  // MODULE INSTANTIATIONS
  // ============================================================================

  // Control
  Control control_unit(
      .ex_instr(ex_instr),
      .wb_instr(wb_instr),
      .ex_BrEq(ex_BrEq),
      .ex_BrLt(ex_BrLt),
      .ex_BrUn(ex_BrUn),
      .ex_ASel(ex_ASel),
      .ex_BSel(ex_BSel),
      .ex_MemRW(ex_MemRW),
      .ex_PCSel(ex_PCSel),
      .ex_fwd1(ex_fwd1),
      .ex_fwd2(ex_fwd2),
      .ex_CSREn(ex_CSREn),
      .wb_WBSel(wb_WBSel),
      .wb_RegWEn(wb_RegWEn)
  );

  // Register File
  RegFile RegFile(
      .rs2_addr(ex_instr[24:20]),
      .rs1_addr(ex_instr[19:15]),
      .rd_addr(wb_instr[11:7]),
      .wdata(wb_wdata),
      .RegWEn(wb_RegWEn),
      .clk(clk),
      .reset(reset),
      .rs1_data(id_rs1_data),
      .rs2_data(id_rs2_data)
  );

  // Branch comparator
  BranchComp BranchComp(
      .rs1_data(ex_rs1_data),
      .rs2_data(ex_rs2_data),
      .BrUn(ex_BrUn),
      .BrEq(ex_BrEq),
      .BrLt(ex_BrLt)
  );

  // ImmGen
  ImmGen ImmGen(
      .id_instr(ex_instr),
      .id_imm(id_imm)
  );

  // ALU
  ALU ALU(
      .A(ex_alu_a),
      .B(ex_alu_b),
      .ALUop(ex_ALUop),
      .Out(ex_alu_out)
  );


  // ALUdec
  ALUdec ALUdec(
      .opcode(ex_instr[6:0]),
      .funct(ex_instr[14:12]),
      .add_rshift_type(ex_instr[30]),
      .ALUop(ex_ALUop)
  );


  // PartialStore
  PartialStore PartialStore(
      .id_instr(ex_instr),
      .ex_mem_addr(ex_alu_out),
      .ex_rs2_data(ex_rs2_data),
      .ex_MemRW(ex_MemRW),
      .ex_store_data(dcache_din),
      .ex_write_mask(dcache_we)
  );


  // PartialLoad
  PartialLoad PartialLoad(
      .wb_instr(wb_instr),
      .wb_mem_addr(wb_alu_out),
      .mem_rdata(dcache_dout),
      .mem_load_data(mem_load_data)
  );



  // ============================================================================
  // ASSERTIONS
  // ============================================================================

    // 1) PC resets correctly
  property pc_reset_check;
    @(posedge clk) reset |-> ##1 (pc_reg == `PC_RESET);
  endproperty
  assert property (pc_reset_check) else $error("PC not reset to PC_RESET");

  // 2) Store write mask has correct number of ones
  property store_write_mask_check;
    @(posedge clk)
      (ex_MemRW && ex_instr[6:0] == `OPC_STORE) |->
        ((ex_instr[14:12] == 3'b000 && $countones(dcache_we) == 1) ||  // sb: 1 byte
         (ex_instr[14:12] == 3'b001 && $countones(dcache_we) == 2) ||  // sh: 2 bytes
         (ex_instr[14:12] == 3'b010 && $countones(dcache_we) == 4));   // sw: 4 bytes
  endproperty
  assert property (store_write_mask_check) else $error("Store write mask incorrect");

  // 3) lb sign extension
  property lb_sign_extension_check;
    @(posedge clk)
      (wb_instr[6:0] == `OPC_LOAD &&
       wb_instr[14:12] == 3'b000 && wb_instr[11:7] != 5'b0 && wb_WBSel == 2'b01)
      |->
      ((mem_load_data[31:8] == 24'h000000) || (mem_load_data[31:8] == 24'hFFFFFF));
  endproperty
  assert property (lb_sign_extension_check) else $error("lb sign extension incorrect");

  // 4) lh sign extension
  property lh_sign_extension_check;
    @(posedge clk)
      (wb_instr[6:0] == `OPC_LOAD &&
       wb_instr[14:12] == 3'b001 && wb_instr[11:7] != 5'b0 && wb_WBSel == 2'b01)
      |->
      ((mem_load_data[31:16] == 16'h0000) || (mem_load_data[31:16] == 16'hFFFF));
  endproperty
  assert property (lh_sign_extension_check) else $error("lh sign extension incorrect");

  // 5) x0 must always read as 0 (rs1/rs2)
  property x0_always_zero_rs1;
    @(posedge clk) (ex_instr[19:15] == 5'b0) |-> (id_rs1_data == 32'b0);
  endproperty
  assert property (x0_always_zero_rs1) else $error("x0 (rs1) not zero");

  property x0_always_zero_rs2;
    @(posedge clk) (ex_instr[24:20] == 5'b0) |-> (id_rs2_data == 32'b0);
  endproperty
  assert property (x0_always_zero_rs2) else $error("x0 (rs2) not zero");

        
endmodule
