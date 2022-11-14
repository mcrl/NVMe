// NVMe Configurator
// Bit layout:
//   All TLPs:
//     Unused - bits 31-29
//     Dword - bits 28-18 : Dword 
//     Type - bits 17-16: 00=CfgRd, 01=CfgWr, 10=MemRd, 11=MemWr
//   Cfg TLPs:
//     Function Number (2 LSb) - bits 15-14
//     Register Number - bits 13-4
//     1DW BE - bits 3-0
//   Mem TLPs:
//     Offsets - bits 15-0
//     Payload Data - bits 31-0
//
// Unused        Type                                           - All TLPs (even)
// |-----------| |-|
//                    Func  Register  1DW
//                    Num    Number    BE                       - Cfg TLPs (even)
//                    ||   |--------| |--|
//
//                            Offsets                           - Mem TLPs (even)
//                    |------------------|
//
//  Payload Data
// |-------_--------_--------_-------|                          - All TLPs (odd)



module configurator #(
  // Configurator Parameters
  parameter ROM_FILE                    = "nvme_cfg_rom.data",   // Location of configuration rom data file
  parameter ROM_SIZE                    = 8,                    // Number of entries in configuration rom
  parameter ROM_ADDR_WIDTH              = (ROM_SIZE-1 < 2  )  ? 2 :
                                          (ROM_SIZE-1 < 4  )  ? 3 :
                                          (ROM_SIZE-1 < 8  )  ? 4 :
                                          (ROM_SIZE-1 < 16 )  ? 5 :
                                          (ROM_SIZE-1 < 32 )  ? 6 :
                                                                7,
  parameter        AXI4_RQ_TUSER_WIDTH    = 62,
  parameter        AXI4_RC_TUSER_WIDTH    = 75,
  parameter        C_DATA_WIDTH           = 128,
  parameter        KEEP_WIDTH             = C_DATA_WIDTH / 32
) (

  // System Interface
  
  input                 user_clk,
  input                 user_reset,
  input                 user_lnk_up,

  // Controller Interface

  input                 start_config,
  output reg            cfg_done,

  // PCIe Arbiter AXIS Interface 

  output reg        [C_DATA_WIDTH-1:0]  s_axis_rq_tdata,
  output reg [AXI4_RQ_TUSER_WIDTH-1:0]  s_axis_rq_tuser,
  output reg          [KEEP_WIDTH-1:0]  s_axis_rq_tkeep,
  output reg                            s_axis_rq_tlast,
  output reg                            s_axis_rq_tvalid,
  input                     [3:0]       s_axis_rq_tready,

  input        [C_DATA_WIDTH-1:0]     m_axis_rc_tdata,
  input [AXI4_RC_TUSER_WIDTH-1:0]     m_axis_rc_tuser,
  input          [KEEP_WIDTH-1:0]     m_axis_rc_tkeep,
  input                               m_axis_rc_tlast,
  input                               m_axis_rc_tvalid,
  output                              m_axis_rc_tready,

  output reg  [4:0] cfg_state,
  input       [5:0] cfg_ltssm_state,

  // for debugging
  output reg       recv_done,
  output reg [7:0] recv_tag,
  output reg [3:0] recv_err_code,
  output reg [2:0] recv_cpl_status,
  output reg       recv_req_completed,
  output reg       recv_skip,
  output reg [31:0] recv_data,
  output reg [7:0] tag,
  output reg [31:0] rom_data,
  output reg [ROM_ADDR_WIDTH-1:0] rom_addr
);

  `include "constants.h"

  localparam [4:0] ST_IDLE     = 5'd0;

  // Enable Memory Space, I/O Space, Enable Bus Master
  localparam [4:0] ST_RESET1_1 = 5'd6;      
  localparam [4:0] ST_RESET1_2 = 5'd7;
  localparam [4:0] ST_RESET1_3 = 5'd8;

  // CfgWr BAR0 (LO 32bit)
  localparam [4:0] ST_RESET2_1 = 5'd9;      
  localparam [4:0] ST_RESET2_2 = 5'd10;
  localparam [4:0] ST_RESET2_3 = 5'd11;

  // CfgWr BAR1 (HI 32bit)
  localparam [4:0] ST_RESET3_1 = 5'd12;      
  localparam [4:0] ST_RESET3_2 = 5'd13;
  localparam [4:0] ST_RESET3_3 = 5'd14;

  // MemWr 0x00 to CC.EN
  localparam [4:0] ST_RESET0_1 = 5'd1;      
  localparam [4:0] ST_RESET0_2 = 5'd2;

  // MemRd CSTS.RDY 
  localparam [4:0] ST_RESET0_3 = 5'd3;      
  localparam [4:0] ST_RESET0_4 = 5'd4;

  // MemWr 0x000f_000f to AQA (Admin Queue Attribute)
  localparam [4:0] ST_RESET4_1 = 5'd15;      
  localparam [4:0] ST_RESET4_2 = 5'd16;

  // MemWr 0xFFFF_F100 to ASQ (Admin Submission Queue Base Address)
  localparam [4:0] ST_RESET5_1 = 5'd18;      
  localparam [4:0] ST_RESET5_2 = 5'd19;

  // MemWr 0xFFFF_F200 to ACQ (Admin Completion Queue Base Address)
  localparam [4:0] ST_RESET6_1 = 5'd21;      
  localparam [4:0] ST_RESET6_2 = 5'd22;

  // MemWr 0x0000_0001 to CC.EN (Enable Controller Configuration)
  localparam [4:0] ST_RESET7_1 = 5'd24;      
  localparam [4:0] ST_RESET7_2 = 5'd25;

  // MemRd CSTS.RDY 
  localparam [4:0] ST_RESET8_1 = 5'd27;      
  localparam [4:0] ST_RESET8_2 = 5'd28;

  // Controller Level Reset is Done
  localparam [4:0] ST_RESET_DONE = 5'd30;   



  reg recv_fail;
  reg csts_ready;

  reg                   [C_DATA_WIDTH-1:0]     s_axis_rq_tdata_d;
  reg                     [KEEP_WIDTH-1:0]     s_axis_rq_tkeep_d;
  reg            [AXI4_RQ_TUSER_WIDTH-1:0]     s_axis_rq_tuser_d;
  reg                                          s_axis_rq_tlast_d;
  reg                                          s_axis_rq_tvalid_d;


  //-------------------------------------------------------
  // Configurator State Machine
  //-------------------------------------------------------

  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      cfg_state <= ST_IDLE;
      cfg_done <= 1'b0;
    end
    else begin
      case(cfg_state) 
        ST_IDLE: begin
          if(start_config) cfg_state <= ST_RESET1_1;
        end

        // Enable Memory Space
        ST_RESET1_1: cfg_state <= ST_RESET1_2;
        ST_RESET1_2: cfg_state <= ST_RESET1_3;
        ST_RESET1_3: if(recv_done && !recv_fail) cfg_state <= ST_RESET2_1;

        // CfgWr BAR0
        ST_RESET2_1: cfg_state <= ST_RESET2_2;
        ST_RESET2_2: cfg_state <= ST_RESET2_3;
        ST_RESET2_3: if(recv_done && !recv_fail) cfg_state <= ST_RESET3_1;

        // CfgWr BAR1
        ST_RESET3_1: cfg_state <= ST_RESET3_2;
        ST_RESET3_2: cfg_state <= ST_RESET3_3;
        ST_RESET3_3: if(recv_done && !recv_fail) cfg_state <= ST_RESET0_1;

        // MemWr 0x00 to CC.EN 
        ST_RESET0_1: cfg_state <= ST_RESET0_2;
        ST_RESET0_2: cfg_state <= ST_RESET0_3;

        // MemRd CSTS.RDY (Wait until not ready)
        ST_RESET0_3: cfg_state <= ST_RESET0_4;
        ST_RESET0_4: begin
          if(recv_done && !recv_fail) begin
            if(!csts_ready) cfg_state <= ST_RESET4_1;
            else cfg_state <= ST_RESET0_3;
          end
        end

        // MemWr 0x000f_000f to AQA (Admin Queue Attribute)
        ST_RESET4_1: cfg_state <= ST_RESET4_2;
        ST_RESET4_2: cfg_state <= ST_RESET5_1;

        // MemWr 0xFFFF_F100 to ASQ (Admin Submission Queue Base Address)
        ST_RESET5_1: cfg_state <= ST_RESET5_2;
        ST_RESET5_2: cfg_state <= ST_RESET6_1;

        // MemWr 0xFFFF_F200 to ACQ (Admin Completion Queue Base Address)
        ST_RESET6_1: cfg_state <= ST_RESET6_2;
        ST_RESET6_2: cfg_state <= ST_RESET7_1;

        // MemWr 0x0000_0001 to CC.EN (Enable Controller Configuration)
        ST_RESET7_1: cfg_state <= ST_RESET7_2;
        ST_RESET7_2: cfg_state <= ST_RESET8_1;

        // MemRd CSTS.RDY
        ST_RESET8_1: cfg_state <= ST_RESET8_2;
        ST_RESET8_2: begin
          if(recv_done && !recv_fail) begin
            if(csts_ready) cfg_state <= ST_RESET_DONE;
            else cfg_state <= ST_RESET8_1;
          end
        end

        ST_RESET_DONE: begin
          cfg_done <= 1'b1;
        end

      endcase
    end
  end


  //-------------------------------------------------------
  // Requester reQuest Encoder
  //-------------------------------------------------------

  // Pipelined
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      s_axis_rq_tdata <= 'd0;
      s_axis_rq_tkeep <= 'd0;
      s_axis_rq_tuser <= 'd0;
      s_axis_rq_tlast <= 'd0;
      s_axis_rq_tvalid <= 'd0;
    end
    else begin
      s_axis_rq_tdata <= s_axis_rq_tdata_d;
      s_axis_rq_tkeep <= s_axis_rq_tkeep_d;
      s_axis_rq_tuser <= s_axis_rq_tuser_d;
      s_axis_rq_tlast <= s_axis_rq_tlast_d;
      s_axis_rq_tvalid <= s_axis_rq_tvalid_d;
    end
  end


  always@(*) begin
    if(user_reset || !user_lnk_up) begin
      s_axis_rq_tdata_d = {C_DATA_WIDTH{1'b0}};
      s_axis_rq_tvalid_d = 1'b0;
      s_axis_rq_tkeep_d = 4'b0000;
      s_axis_rq_tlast_d = 1'b0;
      s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
    end
    else begin
      case(cfg_state)

        // Enable Memory Space
        ST_RESET1_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                CfgWr,  // Req Type
                                11'd1,  // Dword count
                                52'd0,  // Reserved
                                10'd1,  // Reg Number
                                2'd0    // Reserved
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b0;
        end
        
        ST_RESET1_2: begin
          s_axis_rq_tdata_d = {
                                96'h0,
                                32'b111
                              };
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b0001;
          s_axis_rq_tlast_d = 1'b1;
        end
        
        // CfgWr BAR0
        ST_RESET2_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                CfgWr,  // Req Type
                                11'd1,  // Dword count
                                52'd0,  // Reserved
                                10'd4,  // Reg Number
                                2'd0    // Reserved
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b0;
        end
        
        ST_RESET2_2: begin
          s_axis_rq_tdata_d = {
                                96'h0,
                                32'h0000_0000 // BAR 0 (LO)
                              };
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b0001;
          s_axis_rq_tlast_d = 1'b1;
        end

        // CfgWr BAR1
        ST_RESET3_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                CfgWr,  // Req Type
                                11'd1,  // Dword count
                                52'd0,  // Reserved
                                10'd5,  // Reg Number
                                2'd0    // Reserved
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b0;
        end
        
        ST_RESET3_2: begin
          s_axis_rq_tdata_d = {
                                96'h0,
                                32'h0000_0010 // BAR 1 (HI)
                              };
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b0001;
          s_axis_rq_tlast_d = 1'b1;
        end

        // MemWr 0x00 to CC.EN
        ST_RESET0_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                MemWr,  // Req Type
                                11'd1,  // Dword count
                                BAR0 + 64'h14       // Address
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b0;
        end
        
        ST_RESET0_2: begin
          s_axis_rq_tdata_d = {
                                96'h0,
                                32'h0000_0000
                              };
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b0001;
          s_axis_rq_tlast_d = 1'b1;
        end

        // MemRd CSTS.RDY
        ST_RESET0_3: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                MemRd,  // Req Type
                                11'd1,  // Dword count
                                BAR0 + 64'h1C       // Address
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b1;
        end

        // MemWr 0x000f_000f to AQA
        ST_RESET4_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                MemWr,  // Req Type
                                11'd1,  // Dword count
                                BAR0 + 64'h24       // Address
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b0;
        end
        
        ST_RESET4_2: begin
          s_axis_rq_tdata_d = {
                                96'h0,
                                32'h000f_000f
                              };
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b0001;
          s_axis_rq_tlast_d = 1'b1;
        end

        // MemWr 0xFFFF F100 to ASQ (offset : 0x28)
        ST_RESET5_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                MemWr,  // Req Type
                                11'd2,  // Dword count
                                BAR0 + 64'h28       // Address
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b1111,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b0;
        end
        
        ST_RESET5_2: begin
          s_axis_rq_tdata_d = {
                                64'h0,
                                64'h0000_0000_FFFF_F100
                              };
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b0011;
          s_axis_rq_tlast_d = 1'b1;
        end

        // MemWr 0xFFFF F200 to ACQ (offset : 0x30)
        ST_RESET6_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                MemWr,  // Req Type
                                11'd2,  // Dword count
                                BAR0 + 64'h30       // Address
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b1111,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b0;
        end
        
        ST_RESET6_2: begin
          s_axis_rq_tdata_d = {
                                64'h0,
                                64'h0000_0000_FFFF_F200
                              };
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b0011;
          s_axis_rq_tlast_d = 1'b1;
        end

        // MemWr 0x0000_0001 to CC.EN (Enable Controller Configuration)
        ST_RESET7_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                MemWr,  // Req Type
                                11'd1,  // Dword count
                                BAR0 + 64'h14       // Address
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b0;
        end
        
        ST_RESET7_2: begin
          s_axis_rq_tdata_d = {
                                64'h0,
                                32'h0,
                                32'h1
                              };
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b0001;
          s_axis_rq_tlast_d = 1'b1;
        end

        // MemRd CSTS.RDY
        ST_RESET8_1: begin
          s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'b1,   // Requester ID Enable
                                COMPLETER_ID,
                                tag,   
                                REQUESTER_ID,
                                1'd0,   // Poisoned Request
                                MemRd,  // Req Type
                                11'd1,  // Dword count
                                BAR0 + 64'h1C       // Address
                              };
          s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be
                              };
          s_axis_rq_tvalid_d = 1'b1;
          s_axis_rq_tkeep_d = 4'b1111;
          s_axis_rq_tlast_d = 1'b1;
        end
        
        default: begin
          s_axis_rq_tdata_d = {C_DATA_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b0;
          s_axis_rq_tkeep_d = 4'b0000;
          s_axis_rq_tlast_d = 1'b0;
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
        end

      endcase
    end
  end


  //-------------------------------------------------------
  // Requester Completion Decoder
  //-------------------------------------------------------
  assign m_axis_rc_tready = 1'b1;


  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      recv_done <= 1'b0;
      recv_fail <= 1'b0;
      csts_ready <= 1'b0;
    end 
    else begin
      
      if(m_axis_rc_tvalid && m_axis_rc_tlast) begin
        if(cfg_state == ST_RESET0_4 || cfg_state == ST_RESET8_2) csts_ready <= m_axis_rc_tdata[96];
        recv_done <= 1'b1;
        recv_fail <= ~m_axis_rc_tdata[30];
      end
      else begin
        recv_done <= 1'b0;
        recv_fail <= 1'b0;
      end
    end
  end


endmodule