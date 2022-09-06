module pcie_rx #(
  parameter C_DATA_WIDTH  = 512,
  parameter KEEP_WIDTH    = C_DATA_WIDTH/32
) (
  // User Interface
  input   wire  user_clk,
  input   wire  user_reset,
  input   wire  user_lnk_up,

  // PCIe 
  // PCIe IP -> rx
  input   wire  [C_DATA_WIDTH-1:0]  m_axis_rc_tdata,
  input   wire  [KEEP_WIDTH-1:0]    m_axis_rc_tkeep,
  input   wire                      m_axis_rc_tlast,
  output  reg                       m_axis_rc_tready,
  input   wire  [160:0]             m_axis_rc_tuser,
  input   wire                      m_axis_rc_tvalid
);


  localparam  STATE_IDLE            = 4'd0;
  localparam  STATE_RX_ACTIVE       = 4'd1;

  reg [3:0] rx_state;


  always@(posedge user_clk) begin
    if(user_reset) begin
      rx_state  <= STATE_IDLE;

    end else begin
      case(rx_state) 
        STATE_IDLE: begin
          if(user_lnk_up && m_axis_rc_tvalid && m_axis_rc_tready) begin
            if(m_axis_rc_tlast) begin
              rx_state  <= STATE_IDLE;
            end 
            else begin
              rx_state  <= STATE_RX_ACTIVE;
            end
          end
        end // STATE_IDLE

        STATE_RX_ACTIVE: begin
          if(user_lnk_up && m_axis_rc_tvalid && m_axis_rc_tready) begin
            if(m_axis_rc_tlast) begin
              rx_state  <= STATE_IDLE;
            end
          end
        end


      endcase

    end

  end


endmodule