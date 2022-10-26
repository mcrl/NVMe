
(* DowngradeIPIdentifiedWarnings = "yes" *)
module user_tlp_encoder #(
    parameter         AXI4_RQ_TUSER_WIDTH = 62,
    parameter         AXI4_RC_TUSER_WIDTH = 75,
    parameter [15:0]  REQUESTER_ID        = 16'h10EE,
    parameter         C_DATA_WIDTH        = 64,
    parameter         KEEP_WIDTH          = C_DATA_WIDTH / 32
  ) (
    input wire                user_clk,
    input wire                reset,

    // Tx - AXI-S Requester Request Interface
    input                         s_axis_rq_tready,
    output reg [C_DATA_WIDTH-1:0] s_axis_rq_tdata,
    output reg [KEEP_WIDTH-1:0]   s_axis_rq_tkeep,
    output reg [AXI4_RQ_TUSER_WIDTH-1:0]             s_axis_rq_tuser,
    output reg                    s_axis_rq_tlast,
    output reg                    s_axis_rq_tvalid,

    // Controller interface
    input wire [2:0]          tx_type,  
    input wire [7:0]          tx_tag,
    input wire [63:0]         tx_addr,
    input wire [127:0]        tx_data,
    input wire [10:0]         tx_length,
    input wire                tx_start,
    output reg                tx_done
  );

  // TLP type encoding for tx_type
  localparam [2:0] TYPE_MEMRD32 = 3'b000;
  localparam [2:0] TYPE_MEMWR32 = 3'b001;
  localparam [2:0] TYPE_MEMRD64 = 3'b010;
  localparam [2:0] TYPE_MEMWR64 = 3'b011;

  // State encoding
  localparam [1:0] ST_IDLE   = 2'd0;
  localparam [1:0] ST_CYC1   = 2'd1;
  localparam [1:0] ST_CYC2   = 2'd2;
  localparam [1:0] ST_CYC3   = 2'd3;

  // State variable
  reg [1:0]   pkt_state;

  // Registers to store format and type bits of the TLP header
  reg [2:0]   pkt_attr;
  reg [3:0]   pkt_type;

  reg [10:0]  tx_count;
  always@(posedge user_clk) begin
    if(reset) begin
      tx_count <= 11'd0;
    end
    else begin
      if(pkt_state == ST_CYC2) begin
        tx_count <= tx_count + 11'd1;
      end
    end
  end
  

  always @(posedge user_clk) begin
    if (reset) begin
      pkt_state     <= ST_IDLE;
      tx_done       <= 1'b0;
    end else begin
      case (pkt_state)
        ST_IDLE: begin
          // Waiting for input from Controller module
          tx_done        <= 1'b0;
          if (tx_start) begin
            pkt_state    <= ST_CYC1;
          end
        end // ST_IDLE

        ST_CYC1: begin : beat_1
          // First Double-Quad-word - wait for data to be accepted by core
          if (s_axis_rq_tready) begin
            if ((tx_type == TYPE_MEMWR64) || (tx_type == TYPE_MEMWR32)) begin
              pkt_state    <= ST_CYC2;
            end else begin
              pkt_state  <= ST_IDLE;
              tx_done    <= 1'b1;
            end
          end
        end // ST_CYC1

        ST_CYC2: begin : beat_2
          // Second Quad-word - wait for data to be accepted by core
          if (s_axis_rq_tready) begin
            pkt_state <= (tx_count == {2'b00, tx_length[10:2]}-11'd1 ) ? ST_IDLE : ST_CYC2;
            tx_done    <= (tx_count == {2'b00, tx_length[10:2]}-11'd1 ) ? 1'b1 : 1'b0;
          end
        end // ST_CYC2

        default: begin
          pkt_state      <= ST_IDLE;
        end // default case
      endcase
    end
  end

  // Compute Format and Type fields from type of TLP requested
  always @(posedge user_clk) begin
    if (reset) begin
      pkt_attr     <= 3'b000;
      pkt_type     <= 4'b0000;
    end else begin
      case (tx_type)
        TYPE_MEMRD32: begin
          pkt_attr <= 3'b000;
          pkt_type <= 4'b0000;
        end
        TYPE_MEMWR32: begin
          pkt_attr <= 3'b010;
          pkt_type <= 4'b0001;
        end
        TYPE_MEMRD64: begin
          pkt_attr <= 3'b000;
          pkt_type <= 4'b0000;
        end
        TYPE_MEMWR64: begin
          pkt_attr <= 3'b010;
          pkt_type <= 4'b0001;
        end
        default: begin
          pkt_attr <= 3'b000;
          pkt_type <= 4'b0000;
        end
      endcase
    end
  end


  //-------------------------------------------------------    
  // Requester reQuest Descriptor Format
  //-------------------------------------------------------    
  // 127     = force ECRC
  // 126:124 = attributes
  // 123:121 = transaction class
  // 120     = requester id enable (1 for root port)
  // 119:104 = completer id
  // 103:96  = tag
  // 95:88   = requester bus
  // 87:80   = requester function/device
  // 79      = poisoned request
  // 78:75   = request type
  // 74:64   = dword count
  // 63:0    = Address[63:2], Address Type[1:0]    

  //-------------------------------------------------------    
  // s_axis_rq_tuser Sideband Signal Descriptions
  //-------------------------------------------------------    
  // 59:28   = parity of tdata (if enabled)
  // 27:24   = seq_num for tracking progress in tx pipeline
  // 23:16   = TPH steering tag
  // 15      = TPH indirect tag enable
  // 14:13   = TPH type
  // 12      = TPH present
  // 11      = discontinue
  // 10:8    = addr_offset[2:0]
  // 7:4     = last_be[3:0]
  // 3:0     = first_be[3:0]


  // Packet generation output
  always @* begin
    case (pkt_state)
      ST_IDLE: begin
        s_axis_rq_tlast  = 1'b0;
        s_axis_rq_tuser  = {AXI4_RQ_TUSER_WIDTH{1'b0}};
        s_axis_rq_tdata  = {C_DATA_WIDTH{1'b0}};
        s_axis_rq_tkeep  = {KEEP_WIDTH{1'b0}};
        s_axis_rq_tvalid = 1'b0;
      end // ST_IDLE

      ST_CYC1: begin
        s_axis_rq_tlast  = ((tx_type == TYPE_MEMWR64) ||(tx_type == TYPE_MEMWR32)) ? 1'b0 : 1'b1;
        s_axis_rq_tuser  = {
                            32'b0,    // Parity of tdata
                            4'b1010,  // Seq Number
                            8'h00,    // TPH Steering Tag
                            1'b0,     // TPH indirect Tag Enable
                            2'b0,     // TPH Type
                            1'b0,     // TPH Present
                            1'b0,     // Discontinue
                            3'b000,   // Byte Lane number in case of Address Aligned mode
                            //4'b0000,  // Last BE
                            (tx_length == 11'd1)? 4'b0000 : 4'b1111, // Last BE
                            4'b1111   // First BE
                          }; 
        s_axis_rq_tdata  = {
                            // DESC 3
                            1'b0,                           // Force ECRC
                            pkt_attr,                       // Attr
                            3'b0,                           // TC
                            1'b0,                           // Requester ID Enable
                            REQUESTER_ID,                   // Completer ID
                            tx_tag,                         // Tag

                            // DESC 2
                            16'h00AF,                       // Requester ID
                            1'b0,                           // Poisoned Req
                            pkt_type,                       // Type
                            //11'd1,                          // DWord count
                            //11'b111_1111_1111,                      // DWord count
                            tx_length,

                            // DESC 1
                            32'h0,                          // Address[63:32]

                            // DESC 0
                            {tx_addr[31:2], 2'b00}          // Address[31:0]
                          };
        s_axis_rq_tkeep  = {KEEP_WIDTH{1'b1}};
        s_axis_rq_tvalid = 1'b1;
      end // ST_CYC1

      // state for MemWr
      ST_CYC2: begin
        s_axis_rq_tdata = tx_data;
        s_axis_rq_tuser  = {AXI4_RQ_TUSER_WIDTH{1'b0}};
        s_axis_rq_tkeep  =  (tx_length == 11'd1)? 4'b0001 : 
                            ((tx_length == 11'd2)? 4'b0011 :
                            ((tx_length == 11'd3)? 4'b0111 : 4'b1111));
        s_axis_rq_tvalid = 1'b1;
        s_axis_rq_tlast  = (tx_count == {2'b00, tx_length[10:2]}-11'd1 ) ? 1'b1 : 1'b0;
      end // ST_CYC2

      default: begin
        s_axis_rq_tlast  = 1'b0;
        s_axis_rq_tuser  = {AXI4_RQ_TUSER_WIDTH{1'b0}};
        s_axis_rq_tdata  = {C_DATA_WIDTH{1'b0}};
        s_axis_rq_tkeep  = {KEEP_WIDTH{1'b0}};
        s_axis_rq_tvalid = 1'b0;
      end // default case
    endcase
  end

endmodule 