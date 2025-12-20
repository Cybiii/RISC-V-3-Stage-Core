// .___      .___          /\ __    .__  .__ __              __  .__    .__                 ___ 
// |   |   __| _/____   ___)//  |_  |  | |__|  | __ ____   _/  |_|  |__ |__| ______  /\    /  / 
// |   |  / __ |/  _ \ /    \   __\ |  | |  |  |/ // __ \  \   __\  |  \|  |/  ___/  \/   /  /  
// |   | / /_/ (  <_> )   |  \  |   |  |_|  |    <\  ___/   |  | |   Y  \  |\___ \   /\  (  (   
// |___| \____ |\____/|___|  /__|   |____/__|__|_ \\___  >  |__| |___|  /__/____  >  \/   \  \  
//            \/           \/                    \/    \/             \/        \/         \__\ 


`include "util.vh"
`include "const.vh"

module cache #
(
  parameter LINES = 64,
  parameter CPU_WIDTH = `CPU_INST_BITS,
  parameter WORD_ADDR_BITS = `CPU_ADDR_BITS-`ceilLog2(`CPU_INST_BITS/8)
)
(
  input clk,
  input reset,

  input cpu_req_valid,
  output reg cpu_req_ready,
  input [WORD_ADDR_BITS-1:0] cpu_req_addr,
  input [CPU_WIDTH-1:0] cpu_req_data,
  input [3:0] cpu_req_write,

  output reg cpu_resp_valid,
  output reg [CPU_WIDTH-1:0] cpu_resp_data,

  output reg mem_req_valid,
  input mem_req_ready,
  output reg [WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_req_addr,
  output reg mem_req_rw,
  output reg mem_req_data_valid,
  input mem_req_data_ready,
  output [`MEM_DATA_BITS-1:0] mem_req_data_bits,
  output reg [(`MEM_DATA_BITS/8)-1:0] mem_req_data_mask,

  input mem_resp_valid,
  input [`MEM_DATA_BITS-1:0] mem_resp_data
);

  localparam IDLE = 3'b000;
  localparam CHECK_HIT = 3'b001;
  localparam WRITE_TO_MEM = 3'b010;
  localparam LOAD_FROM_MEM = 3'b011;
  localparam METADATA_REWRITE = 3'b100;

  localparam MEM_ADDR_BITS = WORD_ADDR_BITS-`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH);

  reg [2:0] state, next_state;

  reg [WORD_ADDR_BITS-1:0] delayed_addr;
  reg [CPU_WIDTH-1:0] delayed_data;
  reg [3:0] delayed_mask;

  reg mdata_we;
  wire [3:0] mdata_wmask;
  reg [5:0] mdata_line_index;
  wire [31:0] mdata_dout;
  reg [31:0] mdata_din;

  assign mdata_wmask = 4'b1111;

  reg cache0_we, cache1_we, cache2_we, cache3_we;
  reg [3:0] cache_wmask;
  reg [7:0] cache_line_index;

    /* 
      e.g. if we want to write to line 0, we update line 0 in all 4 caches,
      but to meet the correct line size, we update the next 4 addresses in all
      4 of the cache SRAMs. This will require 4 cycles (4 writes for each SRAM)
  */

  reg [31:0] cache0_din, cache1_din, cache2_din, cache3_din;
  wire [31:0] cache0_dout, cache1_dout, cache2_dout, cache3_dout;
  
  reg [2:0] sram_access_cycle, next_sram_access_cycle;

  wire [19:0] cpu_tag = cpu_req_addr[29:10];
  wire [5:0] cpu_index = cpu_req_addr[9:4];
  wire [1:0] cpu_word_offset = cpu_req_addr[3:2];

  wire [19:0] delayed_tag = delayed_addr[29:10];
  wire [5:0] delayed_index = delayed_addr[9:4];
  wire [1:0] delayed_word_offset = delayed_addr[3:2];
  wire [MEM_ADDR_BITS-1:0] delayed_line_base = {delayed_addr[29:4], 2'b00};

  wire [19:0] mdata_tag = mdata_dout[31:12];
  wire mdata_dirty = mdata_dout[11];
  wire mdata_valid = mdata_dout[10];

  wire hit = mdata_valid && (mdata_tag == delayed_tag);
  wire line_dirty = mdata_valid && mdata_dirty;
  wire is_read = (delayed_mask == 4'b0000);
  wire is_write = ~is_read;





// ███    ███ ███████ ████████  █████  ██████   █████  ████████  █████      ███████ ██████   █████  ███    ███ 
// ████  ████ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██     ██      ██   ██ ██   ██ ████  ████ 
// ██ ████ ██ █████      ██    ███████ ██   ██ ███████    ██    ███████     ███████ ██████  ███████ ██ ████ ██ 
// ██  ██  ██ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██          ██ ██   ██ ██   ██ ██  ██  ██ 
// ██      ██ ███████    ██    ██   ██ ██████  ██   ██    ██    ██   ██     ███████ ██   ██ ██   ██ ██      ██ 

 
 
 
  sram22_64x32m4w8 metadata (
    .clk(clk),
    .we(mdata_we),
    .wmask(mdata_wmask),
    .addr(mdata_line_index),
    .din(mdata_din),
    .dout(mdata_dout)
  );





  //  ██████  █████   ██████ ██   ██ ███████     ███████ ██████   █████  ███    ███ ███████ 
  // ██      ██   ██ ██      ██   ██ ██          ██      ██   ██ ██   ██ ████  ████ ██      
  // ██      ███████ ██      ███████ █████       ███████ ██████  ███████ ██ ████ ██ ███████ 
  // ██      ██   ██ ██      ██   ██ ██               ██ ██   ██ ██   ██ ██  ██  ██      ██ 
  //  ██████ ██   ██  ██████ ██   ██ ███████     ███████ ██   ██ ██   ██ ██      ██ ███████ 

 
 
 
 
  sram22_256x32m4w8 cache0 (
    .clk(clk),
    .we(cache0_we),
    .wmask(cache_wmask),
    .addr(cache_line_index),
    .din(cache0_din),
    .dout(cache0_dout)
  );

  sram22_256x32m4w8 cache1 (
    .clk(clk),
    .we(cache1_we),
    .wmask(cache_wmask),
    .addr(cache_line_index),
    .din(cache1_din),
    .dout(cache1_dout)
  );

  sram22_256x32m4w8 cache2 (
    .clk(clk),
    .we(cache2_we),
    .wmask(cache_wmask),
    .addr(cache_line_index),
    .din(cache2_din),
    .dout(cache2_dout)
  );

  sram22_256x32m4w8 cache3 (
    .clk(clk),
    .we(cache3_we),
    .wmask(cache_wmask),
    .addr(cache_line_index),
    .din(cache3_din),
    .dout(cache3_dout)
  );




  //  ██████  ██████  ███    ███ ██████  ██ ███    ██  █████  ████████ ██  ██████  ███    ██  █████  ██          ██       ██████   ██████  ██  ██████ 
  // ██      ██    ██ ████  ████ ██   ██ ██ ████   ██ ██   ██    ██    ██ ██    ██ ████   ██ ██   ██ ██          ██      ██    ██ ██       ██ ██      
  // ██      ██    ██ ██ ████ ██ ██████  ██ ██ ██  ██ ███████    ██    ██ ██    ██ ██ ██  ██ ███████ ██          ██      ██    ██ ██   ███ ██ ██      
  // ██      ██    ██ ██  ██  ██ ██   ██ ██ ██  ██ ██ ██   ██    ██    ██ ██    ██ ██  ██ ██ ██   ██ ██          ██      ██    ██ ██    ██ ██ ██      
  //  ██████  ██████  ██      ██ ██████  ██ ██   ████ ██   ██    ██    ██  ██████  ██   ████ ██   ██ ███████     ███████  ██████   ██████  ██  ██████ 


   /*
    How the TIO Partioning Works: 
      - Need to look at address index * 4 (and then the 3 following ones)
      - First 2 address bits tell me what SRAM it's stored in, since it'll look like: 
      
      SRAM 0 - SRAM 1 - SRAM 2 - SRAM 3)
      Word 0   Word 1   Word 2   Word 3    Starting address
      Word 4   Word 5   Word 6   Word 7    +1
      Word 8   Word 9   Word 10  Word 11   +2
      Word 12  Word 13  Word 14  Word 15   +3

      - Resultantly, the next 2 bits (what multiple of 4?) will tell me which specific word to choose
      - Thus we need 4 offset bits to pick out the correct word, and partial load/store will take care of the rest
      - 6 index bits will determine which cache line to look at (since there's 64)
      - The remaining 20 bits will be Tag

    Metadata Partioning:

    Bits 31                    12     11      10       9                0            
         -------- TAG ----------     Dirty   Valid     ###### Empty #####
  */

  // TIO: writeback data is directly the 4 bank outputs

  // Always gonna be this when we're pushing to memory
  assign mem_req_data_bits = {cache3_dout, cache2_dout, cache1_dout, cache0_dout};

  always @(*) begin
    // Default values to avoid latches
    next_state = state;
    cpu_req_ready = 1'b0;
    cpu_resp_valid = 1'b0;
    mem_req_valid = 1'b0;
    mem_req_addr = {MEM_ADDR_BITS{1'b0}};
    mem_req_rw = 1'b0;
    mem_req_data_valid = 1'b0;
    mem_req_data_mask = {(`MEM_DATA_BITS/8){1'b0}};
    mdata_we = 1'b0;
    mdata_din = 32'b0;
    cache_line_index = 8'b0;
    cache_wmask = 4'b0000;
    cache0_we = 1'b0;
    cache1_we = 1'b0;
    cache2_we = 1'b0;
    cache3_we = 1'b0;
    cache0_din = 32'b0;
    cache1_din = 32'b0;
    cache2_din = 32'b0;
    cache3_din = 32'b0;
    next_sram_access_cycle = sram_access_cycle;
    mdata_line_index = 6'b0;

    case (state)
      IDLE: begin
        cpu_req_ready = 1'b1;
        if (cpu_req_valid) begin
          cache_line_index = {cpu_index, cpu_word_offset};
          mdata_line_index = cpu_index;
          next_state = CHECK_HIT;
        end else begin
          next_state = IDLE;
        end
      end

      CHECK_HIT: begin // Either we HIT and respond, or MISS and go to memory operations
      
        mdata_line_index = delayed_index;
        cache_line_index = {delayed_index, delayed_word_offset};

        /*
          CACHE HIT CACHE HIT CACHE HIT CACHE HIT CACHE HIT CACHE HIT CACHE HIT CACHE HIT
        */

        if (hit) begin

          if (is_write) begin
            // Prepare in case of writes
            cache_wmask = delayed_mask;
            cache0_din = delayed_data;
            cache1_din = delayed_data;
            cache2_din = delayed_data;
            cache3_din = delayed_data;

            mdata_we = 1'b1;
            mdata_din = {mdata_tag, 1'b1, mdata_valid, 10'b0};

            case (delayed_addr[1:0]) // which SRAM to write to
              2'b00: begin
                cache0_we = 1'b1;
              end
              2'b01: begin
                cache1_we = 1'b1;
              end
              2'b10: begin
                cache2_we = 1'b1;
              end
              2'b11: begin
                cache3_we = 1'b1;
              end
            endcase


          // READ HIT
          end else begin
            
            
            case (delayed_addr[1:0])
              2'b00: begin
                cpu_resp_data = cache0_dout;
              end
              2'b01: begin
                cpu_resp_data = cache1_dout;
              end
              2'b10: begin
                cpu_resp_data = cache2_dout;
              end
              2'b11: begin
                cpu_resp_data = cache3_dout;
              end
            endcase
            cpu_resp_valid = 1'b1;
          end

          // On hit, we go back to IDLE (no pipelining)
          next_state = IDLE;

        /*
          CACHE MISS CACHE MISS CACHE MISS CACHE MISS CACHE MISS CACHE MISS CACHE MISS CACHE MISS
        */

        end else begin
          
          
          if (line_dirty) begin
            cache_line_index = {delayed_index, 2'b00};
            next_sram_access_cycle = 3'b000;
            next_state = WRITE_TO_MEM;
          end else begin
            mem_req_addr = delayed_line_base;
            mem_req_valid = 1'b1;
            next_sram_access_cycle = 3'b000;
            next_state = LOAD_FROM_MEM;
          end
        end
      end


      // We'll keep track of the 4 cycles as we write all 16 words (4 words at a time) to memory
      WRITE_TO_MEM: begin
        mdata_line_index = delayed_index;

        if (sram_access_cycle == 3'd4) begin

          mem_req_valid = 1'b1; // writing to memory

          if (mem_req_ready) begin
            next_sram_access_cycle = 3'b000;
            mem_req_addr = delayed_line_base;
            next_state = LOAD_FROM_MEM;
          end else begin
            next_state = WRITE_TO_MEM;
          end

        end else begin

          mem_req_valid = 1'b1;
          mem_req_addr = {mdata_tag, delayed_index, sram_access_cycle[1:0]};
          mem_req_rw = 1'b1;
          mem_req_data_valid = 1'b1;
          mem_req_data_mask = 16'hFFFF;

          if (mem_req_data_ready) begin
            next_sram_access_cycle = sram_access_cycle + 1'b1;
            cache_line_index = {delayed_index, sram_access_cycle[1:0] + 1'b1};
          end else begin
            cache_line_index = {delayed_index, sram_access_cycle[1:0]};
          end

          next_state = WRITE_TO_MEM;

        end
      end



      LOAD_FROM_MEM: begin
        mdata_line_index = delayed_index;

        // for the first 4 cycles we're just gonna write
        if (sram_access_cycle < 3'd4) begin
          
          
          cache_wmask = 4'b1111;
          cache_line_index = {delayed_index, sram_access_cycle[1:0]};

          cache0_din = mem_resp_data[31:0]; // writing these values
          cache1_din = mem_resp_data[63:32];
          cache2_din = mem_resp_data[95:64];
          cache3_din = mem_resp_data[127:96];

          cache0_we = 1'b1; // to all the srams
          cache1_we = 1'b1;
          cache2_we = 1'b1;
          cache3_we = 1'b1;

          next_sram_access_cycle = sram_access_cycle + 1'b1;
          

          next_state = LOAD_FROM_MEM;  // stay in this state until done

        end else begin
          // we're done writing, so now we can get ready to update the metadata
          mdata_we = 1'b1;
          mdata_din = {delayed_tag, 1'b0, 1'b1, 10'b0};
          next_sram_access_cycle = 3'b000;
          
          next_state = METADATA_REWRITE;
          
        end
      end

      // This one cycle delay allows me to go straight to checking hit when there's a memory access followed by another memory access
      // This rewrite used to be at the end of LOAD_FROM_MEM
      METADATA_REWRITE: begin
        cache_line_index = {delayed_index, delayed_word_offset};
        mdata_line_index = delayed_index;
        next_state = CHECK_HIT;
      end

      default: begin
        next_state = IDLE;
      end
    endcase
  end


  // ███████ ███████  ██████  ██    ██ ███████ ███    ██ ████████ ██  █████  ██          ██       ██████   ██████  ██  ██████ 
  // ██      ██      ██    ██ ██    ██ ██      ████   ██    ██    ██ ██   ██ ██          ██      ██    ██ ██       ██ ██      
  // ███████ █████   ██    ██ ██    ██ █████   ██ ██  ██    ██    ██ ███████ ██          ██      ██    ██ ██   ███ ██ ██      
  //      ██ ██      ██ ▄▄ ██ ██    ██ ██      ██  ██ ██    ██    ██ ██   ██ ██          ██      ██    ██ ██    ██ ██ ██      
  // ███████ ███████  ██████   ██████  ███████ ██   ████    ██    ██ ██   ██ ███████     ███████  ██████   ██████  ██  ██████ 
  //                     ▀▀



  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      sram_access_cycle <= 0;
      delayed_addr <= 0;
      delayed_data <= 0;
      delayed_mask <= 0;
    end else begin
      state <= next_state;
      sram_access_cycle <= next_sram_access_cycle;

      if (state == IDLE && next_state == CHECK_HIT) begin
        delayed_addr <= cpu_req_addr;
        delayed_data <= cpu_req_data;
        delayed_mask <= cpu_req_write;
      end
    end
  end

endmodule
