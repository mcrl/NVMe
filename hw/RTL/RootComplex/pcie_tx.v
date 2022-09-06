//PCIe TX module

`define SYNC_RQ_RDY 0
`define SYNC_CC_RDY 1


module pcie_tx #(
  parameter ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG = 0,
  parameter C_DATA_WIDTH  = 512,
  parameter KEEP_WIDTH    = C_DATA_WIDTH/32
) (
  // User Interface
  input   wire  user_clk,
  input   wire  user_reset,
  input   wire  user_lnk_up,

  // PCIe Requester reQuester
  // TX -> PCIe IP
  output reg                      s_axis_rq_tlast,
  output reg  [C_DATA_WIDTH-1:0]  s_axis_rq_tdata,
  output reg  [136:0]             s_axis_rq_tuser,
  output reg  [KEEP_WIDTH-1:0]    s_axis_rq_tkeep,
  input  wire                     s_axis_rq_tready,
  output reg                      s_axis_rq_tvalid,

  // Controller -> TX
  input   wire          ctr2tx_type0_cfg_read,
  input   wire  [7:0]   ctr2tx_type0_cfg_read_tag,
  input   wire  [11:0]  ctr2tx_type0_cfg_read_reg_addr,
  input   wire  [3:0]   ctr2tx_type0_cfg_read_first_dw_be,
  

  // TX -> Controller
  output  reg   tx2ctr_type0_cfg_read_done 
);

  localparam  STATE_IDLE                = 4'd0;
  localparam  STATE_TYPE0_CFG_READ0     = 4'd1;
  localparam  STATE_TYPE0_CFG_READ1     = 4'd2;
  localparam  STATE_TYPE0_CFG_READ2     = 4'd3;
  localparam  STATE_TYPE0_CFG_READ_DONE = 4'd4;

  reg [3:0] tx_state;


  localparam  STATE_TXSYNC_IDLE         = 4'd0;
  localparam  STATE_TXSYNC_START        = 4'd1;
  localparam  STATE_TXSYNC_RDDATA       = 4'd2;
  localparam  STATE_TXSYNC_PARSE_FRAME  = 4'd3;
  localparam  STATE_TXSYNC_DONE         = 4'd4;

  reg [3:0] txsync_state;


  // Regs
  reg [15:0]  EP_BUS_DEV_FNS;
  reg [15:0]  RP_BUS_DEV_FNS;


  // TX SYNC 
  reg tx_sync_start;
  reg tx_sync_first;
  reg tx_sync_active;
  reg tx_sync_last_call;
  reg tx_sync_tready_sw;

  reg tx_sync_done; // TODO
  reg set_malformed; // TODO
  reg [C_DATA_WIDTH-1:0]  pcie_tx_tlp_data;
  reg pcie_tx_tlp_rem; // TODO


  // TX TYPE0 CONFIG READ
  reg [7:0]   tx_type0_cfg_read_tag;
  reg [11:0]  tx_type0_cfg_read_reg_addr;
  reg [3:0]   tx_type0_cfg_read_first_dw_be;


  
  always@(posedge user_clk) begin
    if(user_reset) begin
      tx_state  <=  STATE_TYPE0_CFG_READ0;
      
      s_axis_rq_tlast   <=  1'd0;
      s_axis_rq_tdata   <=  'd0;
      s_axis_rq_tuser   <=  137'd0;
      s_axis_rq_tkeep   <=  'd0;
      s_axis_rq_tvalid  <=  1'b0;

      tx_type0_cfg_read_tag           <=  8'd0;
      tx_type0_cfg_read_reg_addr      <= 12'd0;
      tx_type0_cfg_read_first_dw_be   <= 4'd0;

      tx_sync_start       <= 1'b0;
      tx_sync_first       <= 1'b0;
      tx_sync_active      <= 1'b0;
      tx_sync_last_call   <= 1'b0;
      tx_sync_tready_sw   <= 1'b0;
    end else begin

      case(tx_state)
        STATE_IDLE: begin
          tx2ctr_type0_cfg_read_done  <= 1'b0;

          
          if(ctr2tx_type0_cfg_read) begin
            tx_state  <= STATE_TYPE0_CFG_READ0;

            tx_type0_cfg_read_tag         <= ctr2tx_type0_cfg_read_tag;
            tx_type0_cfg_read_reg_addr    <=  ctr2tx_type0_cfg_read_reg_addr;
            tx_type0_cfg_read_first_dw_be <=  ctr2tx_type0_cfg_read_first_dw_be;
          end
        end

        STATE_TYPE0_CFG_READ0: begin
          if(user_lnk_up) begin
            tx_sync_start       <= 1'b1; 
            tx_sync_first       <= 1'b0;
            tx_sync_active      <= 1'b0;
            tx_sync_last_call   <= 1'b0;
            tx_sync_tready_sw   <= `SYNC_RQ_RDY;

            if(tx_sync_done) begin
              tx_sync_start <= 1'b0;

              tx_state  <=  STATE_TYPE0_CFG_READ1;
            end
          end        
        end

        STATE_TYPE0_CFG_READ1: begin
          if(user_lnk_up) begin
            s_axis_rq_tvalid  <= 1'b1;
            s_axis_rq_tlast   <= 1'b1;
            s_axis_rq_tkeep   <= 8'h0f;
            s_axis_rq_tuser   <= {
                                  //(AXISTEN_IF_RQ_PARITY_CHECK ?  s_axis_rq_tparity : 64'b0), // Parity
                                  64'b0,                   // Parity Bit slot - 64bit
                                  6'b101010,               // Seq Number - 6bit
                                  6'b101010,               // Seq Number - 6bit
                                  16'h0000,                // TPH Steering Tag - 16 bit
                                  2'b00,                   // TPH indirect Tag Enable - 2bit
                                  4'b0000,                 // TPH Type - 4 bit
                                  2'b00,                   // TPH Present - 2 bit
                                  1'b0,                    // Discontinue                                   
                                  4'b0000,                 // is_eop1_ptr
                                  4'b0000,                 // is_eop0_ptr
                                  2'b01,                   // is_eop[1:0]
                                  2'b10,                   // is_sop1_ptr[1:0]
                                  2'b00,                   // is_sop0_ptr[1:0]
                                  2'b01,                   // is_sop[1:0]
                                  2'b00,2'b00,             // Byte Lane number in case of Address Aligned mode - 4 bit
                                  4'b0000,4'b0000,     // Last BE of the Write Data -  8 bit
                                  4'b0000,tx_type0_cfg_read_first_dw_be     // First BE of the Write Data - 8 bit
                                 };
            s_axis_rq_tdata   <= {
                                  256'b0,128'b0,          // 4DW unused             //256
                                  1'b0,            // Force ECRC             //128
                                  3'b000,          // Attributes {ID Based Ordering, Relaxed Ordering, No Snoop}
                                  3'b000,          // Traffic Class
                                  1'b1,            // RID Enable to use the Client supplied Bus/Device/Func No
                                  EP_BUS_DEV_FNS,  // Completer ID
                                  (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tx_type0_cfg_read_tag), // Tag
                                  RP_BUS_DEV_FNS,  // Requester ID  //96
                                  (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                  4'b1000,         // Req Type for TYPE0 CFG READ Req
                                  11'b00000000001, // DWORD Count
                                  32'b0,           // Address *unused*       // 64
                                  16'b0,           // Address *unused*       // 32
                                  4'b0,            // Address *unused*
                                  tx_type0_cfg_read_reg_addr[11:2], // Extended + Base Register Number
                                  2'b00
                                };          // AT -> 00 : Untranslated Address
            //-----------------------------------------------------------------------\\
            pcie_tx_tlp_data  <= {
                                  3'b000,          // Fmt for Type 0 Configuration Read Req 
                                  5'b00100,        // Type for Type 0 Configuration Read Req
                                  1'b0,            // *reserved*
                                  3'b000,          // Traffic Class
                                  1'b0,            // *reserved*
                                  1'b0,            // Attributes {ID Based Ordering}
                                  1'b0,            // *reserved*
                                  1'b0,            // TLP Processing Hints
                                  1'b0,            // TLP Digest Present
                                  (set_malformed ? 1'b1 : 1'b0), // Poisoned Req
                                  2'b00,           // Attributes {Relaxed Ordering, No Snoop}
                                  2'b00,           // Address Translation
                                  10'b0000000001,  // DWORD Count            //32
                                  RP_BUS_DEV_FNS,  // Requester ID
                                  (ATTR_AXISTEN_IF_ENABLE_CLIENT_TAG ? 8'hCC : tx_type0_cfg_read_tag), // Tag
                                  4'b0000,         // Last DW Byte Enable
                                  tx_type0_cfg_read_first_dw_be,    // First DW Byte Enable   //64
                                  EP_BUS_DEV_FNS,  // Completer ID
                                  4'b0000,         // *reserved*
                                  tx_type0_cfg_read_reg_addr[11:2], // Extended + Base Register Number
                                  2'b00,           // *reserved*             //96
                                  32'b0 ,          // *unused*               //128
                                  128'b0           // *unused*               //256
                                };
            pcie_tx_tlp_rem   <= 3'b101;
            set_malformed     <= 1'b0;

            tx_state  <=  STATE_TYPE0_CFG_READ2;
          end
        end

        STATE_TYPE0_CFG_READ2: begin
          if(user_lnk_up) begin
            tx_sync_start       <= 1'b1;
            tx_sync_first       <= 1'b1;
            tx_sync_active      <= 1'b1;
            tx_sync_last_call   <= 1'b1;
            tx_sync_tready_sw   <= `SYNC_RQ_RDY;

            if(tx_sync_done) begin
              tx_sync_start <= 1'b0;

              tx_state  <=  STATE_TYPE0_CFG_READ_DONE;
            end
          end
        end

        STATE_TYPE0_CFG_READ_DONE: begin
          if(user_lnk_up) begin
            tx2ctr_type0_cfg_read_done  <= 1'b1;
            
            tx_state  <= STATE_IDLE;
          end

        end

      endcase

    end
  end

  // TX SYNC
  always@(posedge user_clk) begin
    if(user_reset) begin
      tx_sync_done  <= 1'b0;

      txsync_state  <=  STATE_TXSYNC_IDLE;
    end else begin
      case(txsync_state) 
        STATE_TXSYNC_IDLE: begin
          if(user_lnk_up) begin
            tx_sync_done  <= 1'b0;

            if(tx_sync_start) begin
              txsync_state  <= STATE_TXSYNC_START;
            end
          end
        end

        STATE_TXSYNC_START: begin
          if(user_lnk_up) begin
            if(tx_sync_tready_sw && tx_sync_active) begin
              txsync_state  <= STATE_TXSYNC_RDDATA;
            end
            else if(tx_sync_tready_sw && tx_sync_last_call) begin
              txsync_state  <= STATE_TXSYNC_PARSE_FRAME;
            end
          end
        end

        STATE_TXSYNC_RDDATA: begin

        end

        STATE_TXSYNC_PARSE_FRAME: begin

        end

        STATE_TXSYNC_DONE: begin
          if(user_lnk_up) begin
            tx_sync_done  <= 1'b1;

            txsync_state  <= STATE_TXSYNC_IDLE;
          end
        end

      endcase
    end

  end

endmodule