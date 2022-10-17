
`timescale 1ns/1ns

// PCIe Receive Requester reQuest
// AXIS Data width : 256-bit
// AXIS clk frequency : 125 MHz (user_clk)


module nvme_pcie_rq #(
  parameter [4:0]    PL_LINK_CAP_MAX_LINK_WIDTH     = 4,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  parameter          PL_LINK_CAP_MAX_LINK_SPEED     = 4,  // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter          C_DATA_WIDTH                   = 256,  // RX/TX interface data width
  parameter          AXISTEN_IF_MC_RX_STRADDLE      = 1,
  parameter          KEEP_WIDTH                     = C_DATA_WIDTH / 32,
  parameter          AXI4_RQ_TUSER_WIDTH            = 62,
  parameter          REQUESTER_ID = 16'h0000,   // bus[7:0],dev[4:0],func[2:0] 
  parameter          COMPLETER_ID = 16'h0100
  )
  ( 
    //-------------------------------------------------------
    // User Interface (125MHz)
    //-------------------------------------------------------

    input              user_clk,
    input              user_reset,
    input              user_lnk_up,

    //-------------------------------------------------------
    // Control Interface (Requests)
    //-------------------------------------------------------

    input                 ioq_rq_valid,
    input          [3:0]  ioq_rq_reqType,  
    input         [63:0]  ioq_rq_addr,      // Addr + Addr Type
    input        [127:0]  ioq_rq_data,
    input          [7:0]  ioq_rq_byten,     // [3:0] first_be, [7:4] last_be
    input         [10:0]  ioq_rq_dword,
    input          [5:0]  ioq_rq_tag,   
    output reg            rq_ioq_ack,

    //-------------------------------------------------------
    //  Transaction (AXIS) Interface
    //   - Requester reQuest Interface
    //-------------------------------------------------------    
    
    output reg          [C_DATA_WIDTH-1:0]  s_axis_rq_tdata,
    output reg            [KEEP_WIDTH-1:0]  s_axis_rq_tkeep,
    output reg                              s_axis_rq_tlast,
    input                            [3:0]  s_axis_rq_tready,
    output reg   [AXI4_RQ_TUSER_WIDTH-1:0]  s_axis_rq_tuser,
    output reg                              s_axis_rq_tvalid
);
  `include "constants.h"

  //-------------------------------------------------------    
  // Requester reQuest Descriptor Format
  //-------------------------------------------------------    
  // 63:0    = Address[63:2], Address Type[1:0]    - Memory Request
  // 63:0    = Reserved[63:12], Ext Reg Num[3:0], Reg Number[7:0], Reserved[1:0]   - Configuration Ops
  // 74:64   = dword count
  // 78:75   = request type
  // 79      = poisoned request
  // 87:80   = requester function/device
  // 95:88   = requester bus
  // 103:96  = tag
  // 119:104 = completer id
  // 120     = requester id enable (1 for root port)
  // 123:121 = transaction class
  // 126:124 = attributes
  // 127     = force ECRC

  reg [63:2] addr;
  reg  [1:0] addrtype;
  reg [10:0] dword_count;
  reg  [3:0] req_type;
  reg        poison;
  reg [15:0] requester_id;
  reg  [7:0] tag;
  reg [15:0] completer_id;
  reg        requester_id_en;
  reg  [2:0] trans_class;
  reg  [2:0] attrib;
  reg        force_ecrc;


  //-------------------------------------------------------    
  // s_axis_rq_tuser Sideband Signal Descriptions
  //-------------------------------------------------------    
  // 3:0     = first_be[3:0]
  // 7:4     = last_be[3:0]
  // 10:8    = addr_offset[2:0] (address aligned mode ?)
  // 11      = discontinue
  // 12      = TPH present
  // 14:13   = TPH type
  // 15      = TPH indirect tag enable
  // 23:16   = TPH steering tag
  // 27:24   = seq_num for tracking progress in tx pipeline
  // 59:28   = parity of tdata (if enabled)

  reg  [3:0] first_be;
  reg  [3:0] last_be;
  reg  [2:0] addr_offset;
  reg        discontinue;
  reg [11:0] tph;
  reg  [3:0] seq_num;
  reg [31:0] parity;



  always @(*) begin
    addr            = ioq_rq_addr[63:2];
    addrtype        = ioq_rq_addr[1:0];
    req_type        = ioq_rq_reqType;
    dword_count     = ioq_rq_dword;     
    poison          = 1'b0;     
    requester_id    = REQUESTER_ID; 
    tag             = { 2'b00, ioq_rq_tag };
    completer_id    = COMPLETER_ID;
    requester_id_en = 1'b1;     // must be set for root complex
    first_be        = ioq_rq_byten[3:0];
    last_be         = ioq_rq_byten[7:4];
    trans_class     = 3'h0;   // Not Used
    attrib          = 3'h0;   // Not Used  
    force_ecrc      = 1'b0;   // Not Used
    addr_offset     = 3'h0;   // Not Used
    discontinue     = 1'b0;   // Not Used
    tph             = 12'h0;  // Not Used
    seq_num         = 4'h0;   // Not Used
    parity          = 32'h0;  // Not Used
  end


  //-------------------------------------------------------    
  // FSM
  //-------------------------------------------------------    

  reg [3:0]  state_q, state_d;
  localparam [3:0] S_IDLE = 4'h1;
  localparam [3:0] S_CFGWR0 = 4'h2; // TODO
  localparam [3:0] S_MEMWR0 = 4'h2; // TODO



  always@(posedge user_clk or posedge user_reset) begin
    if( user_reset ) begin
      state_q <= S_IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  always@(*) begin
    state_d = state_q;
    case(state_q)
      S_IDLE: begin
        if(ioq_rq_valid) begin
          if(ioq_rq_dword > 11'd4) begin
            if(ioq_rq_reqType == CfgWr0) state_d = S_CFGWR0;
            else if(ioq_rq_reqType == MemWr) state_d = S_MEMWR0;
          end
          else state_d = S_IDLE;
        end
      end
    endcase
  end

  //-------------------------------------------------------    
  // S_AXIS_RQ_*
  //-------------------------------------------------------  

  reg         [C_DATA_WIDTH-1:0] tdata_q, tdata_d;
  reg           [KEEP_WIDTH-1:0] tkeep_q, tkeep_d;
  reg                            tlast_q, tlast_d;  
  reg  [AXI4_RQ_TUSER_WIDTH-1:0] tuser_q, tuser_d;
  reg                            tvalid_q, tvalid_d;
  
  always @(posedge user_clk or posedge user_reset) begin
    if( user_reset ) begin
      tdata_q  <= {C_DATA_WIDTH{1'b0}};
      tkeep_q  <= {KEEP_WIDTH{1'b0}};
      tlast_q  <= 1'b0;
      tuser_q  <= {AXI4_RQ_TUSER_WIDTH{1'b0}};
      tvalid_q <= 1'b0;        
    end else begin
      tdata_q  <= tdata_d;
      tkeep_q  <= tkeep_d;
      tlast_q  <= tlast_d;
      tuser_q  <= tuser_d;
      tvalid_q <= tvalid_d;           
    end
  end

  always @(*) begin        
    s_axis_rq_tdata   = tdata_q;
    s_axis_rq_tkeep   = tkeep_q;
    s_axis_rq_tlast   = tlast_q;       
    s_axis_rq_tuser   = tuser_q;        
    s_axis_rq_tvalid  = tvalid_q;

    tkeep_d           = tkeep_q;
    tlast_d           = tlast_q;
    tvalid_d          = tvalid_q;
    rq_ioq_ack        = 1'b0;
    
    case(state_q)
      S_IDLE: begin
        tvalid_d = 1'b0;
        tlast_d = 1'b0;
        tdata_d = 256'h0;
        tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
        tkeep_d = {KEEP_WIDTH{1'b0}};

        if(ioq_rq_valid && s_axis_rq_tready) begin

          // DESC0
          tdata_d[31:0] = {
            ioq_rq_addr[31:0]
          };
          
          // DESC1
          tdata_d[63:32] = {
            ioq_rq_addr[63:32]
          };

          // DESC2
          tdata_d[95:64] = {
            requester_id,
            poison,
            req_type,
            dword_count
          };

          // DESC3
          tdata_d[127:96] = {
            force_ecrc,
            attrib,
            trans_class,
            requester_id_en,
            completer_id,
            tag
          };

          // DW0~3
          tdata_d[255:128] = ioq_rq_data; // TODO : dword count > 4
          
          // tuser
          tuser_d = {
            parity,
            seq_num,
            tph,
            discontinue,
            addr_offset,
            last_be,
            first_be
          };

          tvalid_d = 1'b1;
          tlast_d = 1'b1;

          if(( req_type == MemRd) || ( req_type == CfgRd0) ) tkeep_d = 8'h0f;
          else begin
            case(ioq_rq_dword)
              11'd0: tkeep_d = 8'h0f;
              11'd1: tkeep_d = 8'h1f;
              11'd2: tkeep_d = 8'h3f;
              11'd3: tkeep_d = 8'h7f;
              default: tkeep_d = 8'hff;
            endcase // ioq_rq_dword
          end
        end
      end
    endcase // state_q
  end // always@(*)


endmodule