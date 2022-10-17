
`timescale 1ns/1ns

// PCIe Receive Requester Completion
// AXIS Data width : 256-bit
// AXIS clk frequency : 125 MHz (user_clk)

module nvme_pcie_rc
  #(       
  parameter [4:0]    PL_LINK_CAP_MAX_LINK_WIDTH     = 4,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  parameter          PL_LINK_CAP_MAX_LINK_SPEED     = 4,  // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter          C_DATA_WIDTH                   = 256,         // RX/TX interface data width
  parameter          AXISTEN_IF_MC_RX_STRADDLE      = 1,
  parameter          KEEP_WIDTH                     = C_DATA_WIDTH / 32,
  parameter          AXI4_RC_TUSER_WIDTH            = 75,
  parameter          REQUESTER_ID = 16'h0000,   // bus[7:0],dev[4:0],func[2:0] 
  parameter          COMPLETER_ID = 16'h0100
  )
  ( 
    //-------------------------------------------------------
    // User Interface (125MHz)
    //-------------------------------------------------------

    input             user_clk,
    input             user_reset,
    input             user_lnk_up,
    
    //-------------------------------------------------------
    // Control Interface (Completions)
    //-------------------------------------------------------

    output reg          rc_ioq_valid,
    output reg [128:0]  rc_ioq_data,
    output reg  [7:0]   rc_ioq_be,
    output reg  [7:0]   rc_ioq_tag,
    output reg          rc_ioq_poison,
    output reg  [3:0]   rc_ioq_errcode,
    output reg  [2:0]   rc_ioq_status,
    input               ioq_rc_ack,
    input               icq_wfull,

    //-------------------------------------------------------
    //  Transaction (AXIS) Interface
    //   - Requester Completion  interface
    //-------------------------------------------------------    

    input              [C_DATA_WIDTH-1:0] m_axis_rc_tdata,
    input                [KEEP_WIDTH-1:0] m_axis_rc_tkeep,
    input                                 m_axis_rc_tlast,
    output                                m_axis_rc_tready,
    input       [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser,
    input                                 m_axis_rc_tvalid
);
   
  //-------------------------------------------------------    
  // Requester Completion Descriptor Format
  //-------------------------------------------------------    
  // 11:0     = Address
  // 15:12    = Error Code
  // 28:16    = Byte Count
  // 29       = Locked Read Completion
  // 30       = Request Completed
  // 31       = Reserved
  // 42:32    = Dword count
  // 45:43    = Completion Status
  // 46       = Poisoned Completion
  // 47       = Reserved
  // 63:48    = Requester ID (Bus, Device/Function)
  // 71:64    = Tag
  // 87:72    = Completer ID (Bus, Device/Function)
  // 88       = Reserved
  // 91:89    = TC
  // 94:92    = Attr
  // 95       = Reserved
  // 127:96   = X

  //-------------------------------------------------------    
  // m_axis_rc_tuser Sideband Signal Descriptions
  //-------------------------------------------------------
  // 31:0     = byte_en
  // 32       = is_sof_0
  // 33       = is_sof_1
  // 37:34    = is_eof_0
  // 41:38    = is_eof_1
  // 42       = discontinue
  // 74:43    = parity
    

  //-------------------------------------------------------    
  // FSM
  //-------------------------------------------------------  

  reg [3:0] state_q, state_d;

  localparam S_IDLE = 4'h1;
  localparam S_D1   = 4'h2;
  localparam S_ERR  = 4'h3;
  localparam S_CMP  = 4'h4;

  reg                valid_q, valid_d;
  reg        [255:0] data_q, data_d;
  reg          [7:0] be_q, be_d;
  reg          [7:0] tag_q, tag_d;
  reg                poison_q, poison_d;
  reg          [3:0] errcode_q, errcode_d;
  reg          [2:0] status_q, status_d;
  reg                int_error_q, int_error_d;


  always@(posedge user_clk or posedge user_reset) begin
    if(user_reset) begin
      state_q     <= S_IDLE;
    end
    else begin
      state_q     <= state_d;
    end
  end

  always@(*) begin
    state_d           = state_q;
    
    case(state_q)
      S_IDLE: begin
        if( m_axis_rc_tvalid & ~valid_q & user_lnk_up) begin
          // ignore completion if "request completed" isn't asserted
          if( m_axis_rc_tdata[30] ) begin
            // request completed             
            if( m_axis_rc_tlast ) begin
              state_d = S_IDLE;
            end
          end
          else begin
            if( ~m_axis_rc_tlast ) state_d = S_ERR;
          end
        end
      end // S_IDLE
      
      S_ERR: begin
        // wait for last indication for TLP with error
        if( m_axis_rc_tvalid & m_axis_rc_tlast ) begin
            state_d = S_IDLE;
        end
      end // S_ERR
    endcase
  end


  //-------------------------------------------------------    
  // M_AXIS_RC_*
  //-------------------------------------------------------  
   
  always @(posedge user_clk or posedge user_reset) begin
    if( user_reset ) begin
      valid_q     <= 1'b0;
      data_q      <= 256'h0;
      be_q        <= 8'h0;
      tag_q       <= 8'h0;
      poison_q    <= 1'b0;
      errcode_q   <= 4'h0;
      status_q    <= 4'h0;
      int_error_q <= 1'b0;
    end 
    else begin
      valid_q     <= valid_d;
      data_q      <= data_d;
      be_q        <= be_d;
      tag_q       <= tag_d;
      poison_q    <= poison_d;
      errcode_q   <= errcode_d;
      status_q    <= status_d;
      int_error_q <= int_error_d;
    end
  end

  assign m_axis_rc_tready = ~icq_wfull;

  always @(*) begin
    rc_ioq_valid      = valid_q;
    rc_ioq_data       = data_q;
    rc_ioq_be         = be_q;
    rc_ioq_tag        = tag_q;
    rc_ioq_poison     = poison_q;
    rc_ioq_errcode    = errcode_q;
    rc_ioq_status     = status_q;
    //m_axis_rc_tready  = ~valid_q;

    valid_d           = valid_q & ~ioq_rc_ack;
    data_d            = data_q;        
    be_d              = be_q;
    tag_d             = tag_q;
    poison_d          = poison_q;
    errcode_d         = errcode_q;
    status_d          = status_q;
    int_error_d       = int_error_q;

    case(state_q)
      S_IDLE: begin
        valid_d = 1'b0;

        if( m_axis_rc_tvalid & user_lnk_up) begin
          // ignore completion if "request completed" isn't asserted
          if( m_axis_rc_tdata[30] ) begin
            // request completed 
            
            if( m_axis_rc_tlast ) begin
              valid_d = 1'b1;
            end
            /* TODO
            else begin
              state_d = S_D1;
            end
            */

            // DESC 0
            // lower address          = m_axis_rc_tdata[11:0];
            errcode_d                 = m_axis_rc_tdata[15:12];
            // byte_count             = m_axis_rc_tdata[28:16];
            // locked read completion = m_axis_rc_tdata[29];                         
            // request_completed      = m_axis_rc_tdata[30];

            // DESC 1
            // dword_count            = m_axis_rc_tdata[42:32];  
            status_d                  = m_axis_rc_tdata[45:43];
            poison_d                  = m_axis_rc_tdata[46];
            // requester_id           = m_axis_rc_tdata[63:48];       
            
            // DESC 2        
            tag_d                     = m_axis_rc_tdata[71:64];
            // completer_id           = m_axis_rc_tdata[87:72];
            // transaction_class      = m_axis_rc_tdata[91:89];
            // attributes             = m_axis_rc_tdata[94:92];

            // DW 0~4
            data_d[159:0]             = m_axis_rc_tdata[255:96];

            // tuser
            be_d[3:0]                 = m_axis_rc_tuser[15:12];
            // parity[15:0]           = m_axis_rc_tuser[58:43];  
          end

        end
      end // case: S_IDLE
    endcase // case (state_q)
  end




endmodule

