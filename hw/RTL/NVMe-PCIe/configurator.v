// NVMe Configurator

module configurator #(
  // Configurator Parameters
  parameter ROM_FILE                    = "pcie_cfg_rom.data",   // Location of configuration rom data file
  parameter ROM_SIZE                    = 24,                    // Number of entries in configuration rom
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

  output reg [3:0] cfg_state,


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

  localparam [3:0] CfgRd = 4'b1000;
  localparam [3:0] CfgWr = 4'b1010;

  localparam [3:0] ST_IDLE     = 4'd0;
  localparam [3:0] ST_SEND_REQ = 4'd1;
  localparam [3:0] ST_SEND_REQ2= 4'd2;
  localparam [3:0] ST_WAIT_CPL = 4'd3;
  localparam [3:0] ST_READ_NEXT= 4'd4;
  localparam [2:0] ST_DONE     = 4'd5;
  //reg [3:0] cfg_state;

/*
  reg       recv_done;
  reg [7:0] recv_tag;
  reg [3:0] recv_err_code;
  reg [2:0] recv_cpl_status;
  reg       recv_req_completed;
  reg       recv_skip;
  reg [31:0] recv_data;
*/
  //reg [31:0]                rom_data;
  //reg [ROM_ADDR_WIDTH-1:0]  rom_addr;
  reg [31:0]                rom [0:ROM_SIZE-1];

  //reg [7:0] tag;

  reg                   [C_DATA_WIDTH-1:0]     s_axis_rq_tdata_d;
  reg                     [KEEP_WIDTH-1:0]     s_axis_rq_tkeep_d;
  reg            [AXI4_RQ_TUSER_WIDTH-1:0]     s_axis_rq_tuser_d;
  reg                                          s_axis_rq_tlast_d;
  reg                                          s_axis_rq_tvalid_d;


  //-------------------------------------------------------
  // ROM Data and Address
  //-------------------------------------------------------

  // ROM data
  always @(posedge user_clk) begin  // No reset for a ROM
    rom_data <= rom[rom_addr];
  end
  initial begin
    $readmemb(ROM_FILE, rom, 0, ROM_SIZE-1);
  end

  // ROM address
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      rom_addr <= {ROM_ADDR_WIDTH{1'b0}};
    end
    else begin
      case(cfg_state) 
        ST_IDLE: begin
          if(start_config) rom_addr <= rom_addr + 1'b1;
        end
        ST_SEND_REQ: begin
          rom_addr <= rom_addr + 1'b1;
        end
        ST_READ_NEXT: begin
          rom_addr <= rom_addr + 1'b1;
        end
      endcase
    end
  end

  reg cfg_done_d;
  // End configuration and send cfg_done to controller
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      cfg_done_d <= 1'b0;
    end
    else begin
      if(rom_addr >= ROM_SIZE) cfg_done_d <= 1'b1;
    end
  end


  //-------------------------------------------------------
  // Configurator State Machine
  //-------------------------------------------------------

  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      cfg_state <= ST_IDLE;
    end
    else begin
      case(cfg_state) 
        ST_IDLE: begin
          if(start_config) cfg_state <= ST_SEND_REQ;
        end

        ST_SEND_REQ: begin
          if(cfg_done_d) cfg_state <= ST_DONE;

          // CfgWr or MsgD
          else if(rom_data[17:16] == 2'b01 || rom_data[17:16] == 2'b11) begin
            cfg_state <= ST_SEND_REQ2;
          end
          else begin
            cfg_state <= ST_WAIT_CPL;
          end
        end

        ST_SEND_REQ2: begin
          cfg_state <= ST_WAIT_CPL;
        end

        ST_WAIT_CPL: begin
          if(recv_done || recv_skip) cfg_state <= ST_READ_NEXT;
        end

        ST_READ_NEXT: begin
          cfg_state <= ST_SEND_REQ;
        end

        ST_DONE: begin
          cfg_done <= 1'b1;
        end

      endcase
    end
  end

  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin  
      recv_skip <= 1'b0;
    end
    else begin
      if(cfg_state == ST_SEND_REQ) begin
        // Msg
        if(rom_data[17] == 1'b1) recv_skip <= 1'b1;
        else recv_skip <= 1'b0;
      end
    end
  end


  //-------------------------------------------------------
  // tag
  //-------------------------------------------------------

  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      tag <= 8'd0;
    end
    else begin
      if(cfg_state == ST_SEND_REQ) tag <= tag + 8'd1;
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
        ST_SEND_REQ: begin
          if(s_axis_rq_tready) begin
            // CfgRd or CfgWr
            if(rom_data[17] == 1'b0) begin
              s_axis_rq_tdata_d = {
                                  1'b0,   // Force ECRC
                                  3'd0,   // Attr
                                  3'd0,   // TC
                                  1'd0,   // Requester ID Enable
                                  16'd0,  // Completer ID
                                  tag,   // Tag
                                  16'd0,  // Requester ID
                                  1'd0,   // Poisoned Request
                                  (rom_data[17:16] == 2'b00) ? CfgRd : CfgWr, // Req Type
                                  11'd4,  // Dword count
                                  52'd0,  // Reserved
                                  rom_data[13:4],  // (Ext + ) Reg Number
                                  2'd0    // Reserved
                                };
              s_axis_rq_tvalid_d = 1'b1;
              s_axis_rq_tkeep_d = 4'b1111;
              s_axis_rq_tlast_d = (rom_data[17:16] == 2'b00) ? 1'b1 : 1'b0; // CfgRd : CfgWr
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
                                  rom_data[3:0] // first be
                                };
            end

            // Msg or MsgD
            else begin
              s_axis_rq_tdata_d = {
                                  1'b0,   // Force ECRC
                                  3'd0,   // Attr
                                  3'd0,   // TC
                                  1'd0,   // Requester ID Enable
                                  5'd0,   // Reserved
                                  rom_data[10:8], // Message Routing
                                  rom_data[7:0],  // Msg Code
                                  tag,   // Tag
                                  16'd0,  // Requester ID
                                  1'b0,   // Poisoned Request
                                  4'b1100,   // Req Type : Msg
                                  (rom_data[17:16] == 2'b10) ? 11'd0 : 11'd1, // Dword Count Msg or MsgD
                                  64'd0   // Reserved
                                };
              s_axis_rq_tvalid_d = 1'b1;
              s_axis_rq_tkeep_d = 4'b1111;
              s_axis_rq_tlast_d = (rom_data[17:16] == 2'b10) ? 1'b1 : 1'b0; // Msg or MsgD
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
            end
          end
        end
        ST_SEND_REQ2: begin
          if(s_axis_rq_tready) begin
            // CfgWr or MsgD
            s_axis_rq_tdata_d = {96'd0, rom_data[31:0]};
            s_axis_rq_tvalid_d = 1'b1;
            s_axis_rq_tkeep_d = 4'b0001;
            s_axis_rq_tlast_d = 1'b1;
            s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          end
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
      recv_tag <= 8'd0;
      recv_done <= 1'b0;
      recv_err_code <= 4'd0;
      recv_cpl_status <= 3'd0;
      recv_req_completed <= 1'b0;
      recv_data <= 32'd0;
    end 
    else begin
      if(m_axis_rc_tvalid && m_axis_rc_tlast) begin
        recv_tag <= m_axis_rc_tdata[71:64];
        recv_err_code <= m_axis_rc_tdata[15:12];
        recv_req_completed <= m_axis_rc_tdata[30];
        recv_cpl_status <= m_axis_rc_tdata[45:43];
        recv_done <= 1'b1;
        recv_data <= m_axis_rc_tdata[127:96];
      end
      else begin
        recv_tag <= 8'd0;
        recv_done <= 1'b0;
        recv_err_code <= 4'd0;
        recv_cpl_status <= 3'd0;
        recv_req_completed <= 1'b0;
        recv_data <= 32'd0;
      end
    end
  end


endmodule