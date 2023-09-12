
module nvme_rw #(
  parameter AXI_SLAVE_BAR = 32'h8000_0000,
  parameter NVME_CTRL_OFFSET = 32'h0000_4000,
  parameter NVME_BAR = AXI_SLAVE_BAR + NVME_CTRL_OFFSET
)(
  input clk,
  input rstn,
  input oculink_0a_lnk_up,
  
  input do_write,
  input do_read,

  // ---------------------------------
  // AXI Slave : FPGA -> Oculink NVMe
  // ---------------------------------

  // ar
  input logic oculink_0a_s_axi_arready,
  output logic [31:0]oculink_0a_s_axi_araddr,
  output logic [1:0]oculink_0a_s_axi_arburst,
  output logic [3:0]oculink_0a_s_axi_arid,
  output logic [7:0]oculink_0a_s_axi_arlen,
  output logic [3:0]oculink_0a_s_axi_arregion,
  output logic [2:0]oculink_0a_s_axi_arsize,
  output logic oculink_0a_s_axi_arvalid,

  // aw
  input logic oculink_0a_s_axi_awready,
  output logic [31:0]oculink_0a_s_axi_awaddr,
  output logic [1:0]oculink_0a_s_axi_awburst,
  output logic [3:0]oculink_0a_s_axi_awid,
  output logic [7:0]oculink_0a_s_axi_awlen,
  output logic [3:0]oculink_0a_s_axi_awregion,
  output logic [2:0]oculink_0a_s_axi_awsize,
  output logic oculink_0a_s_axi_awvalid,

  // w
  input logic oculink_0a_s_axi_wready,
  output logic [255:0]oculink_0a_s_axi_wdata,
  output logic oculink_0a_s_axi_wlast,
  output logic [31:0]oculink_0a_s_axi_wstrb,
  output logic oculink_0a_s_axi_wvalid,

  // r
  output logic oculink_0a_s_axi_rready,
  input logic [255:0]oculink_0a_s_axi_rdata,
  input logic [3:0]oculink_0a_s_axi_rid,
  input logic oculink_0a_s_axi_rlast,
  input logic [1:0]oculink_0a_s_axi_rresp,
  input logic oculink_0a_s_axi_rvalid,

  // b
  output logic oculink_0a_s_axi_bready,
  input logic [3:0]oculink_0a_s_axi_bid,
  input logic [1:0]oculink_0a_s_axi_bresp,
  input logic oculink_0a_s_axi_bvalid,

  // ---------------------------------
  // AXI Master : OCulink NVMe -> FPGA 
  // ---------------------------------
  
  // ar
  output logic oculink_0a_m_axi_arready,
  input logic [31:0]oculink_0a_m_axi_araddr,
  input logic [1:0]oculink_0a_m_axi_arburst,
  input logic [3:0]oculink_0a_m_axi_arcache,
  input logic [3:0]oculink_0a_m_axi_arid,
  input logic [7:0]oculink_0a_m_axi_arlen,
  input logic oculink_0a_m_axi_arlock,
  input logic [2:0]oculink_0a_m_axi_arprot,
  input logic [2:0]oculink_0a_m_axi_arsize,
  input logic oculink_0a_m_axi_arvalid,

  // aw
  output logic oculink_0a_m_axi_awready,
  input logic [31:0]oculink_0a_m_axi_awaddr,
  input logic [1:0]oculink_0a_m_axi_awburst,
  input logic [3:0]oculink_0a_m_axi_awcache,
  input logic [3:0]oculink_0a_m_axi_awid,
  input logic [7:0]oculink_0a_m_axi_awlen,
  input logic oculink_0a_m_axi_awlock,
  input logic [2:0]oculink_0a_m_axi_awprot,
  input logic [2:0]oculink_0a_m_axi_awsize,
  input logic oculink_0a_m_axi_awvalid,

  // w
  output logic oculink_0a_m_axi_wready,
  input logic [255:0]oculink_0a_m_axi_wdata,
  input logic oculink_0a_m_axi_wlast,
  input logic [31:0]oculink_0a_m_axi_wstrb,
  input logic oculink_0a_m_axi_wvalid,

  // r
  input logic oculink_0a_m_axi_rready,
  output logic [255:0]oculink_0a_m_axi_rdata,
  output logic [3:0]oculink_0a_m_axi_rid,
  output logic oculink_0a_m_axi_rlast,
  output logic [1:0]oculink_0a_m_axi_rresp,
  output logic oculink_0a_m_axi_rvalid,

  // b
  input logic oculink_0a_m_axi_bready,
  output logic [3:0]oculink_0a_m_axi_bid,
  output logic [1:0]oculink_0a_m_axi_bresp,
  output logic oculink_0a_m_axi_bvalid
  );

  localparam ST_IDLE              = 8'd0;
  localparam ST_IOSQDBL_SEND_ADDR = 8'd1;
  localparam ST_IOSQDBL_SEND_DATA = 8'd2;
  localparam ST_IOSQDBL_SEND_RESP = 8'd3;
  localparam ST_WRCMD_RECV_ADDR   = 8'd4;
  localparam ST_WRCMD_SEND_CMD0   = 8'd5;
  localparam ST_WRCMD_SEND_CMD1   = 8'd6;
  localparam ST_WRDATA_RECV_ADDR0 = 8'd7;
  localparam ST_WRDATA_RECV_ADDR1 = 8'd8;
  localparam ST_WRDATA_SEND_DATA  = 8'd9;
  localparam ST_CPL_RECV_DATA     = 8'd10;
  localparam ST_CPL_SEND_RESP     = 8'd11;
  localparam ST_TIMEOUT           = 8'd12;
  
  localparam ST_RDCMD_SEND_CMD0   = 8'd13;
  localparam ST_RDCMD_SEND_CMD1   = 8'd14;
  localparam ST_RDDATA_RECV_ADDR0 = 8'd15;
  localparam ST_RDDATA_RECV_ADDR1 = 8'd16;
  localparam ST_RDDATA_RECV_DATA  = 8'd17;
  localparam ST_RDDATA_RECV_RESP  = 8'd18;
  localparam ST_RDDATA_RECV_CPL   = 8'd19;



  logic [7:0]   rw_state;
  logic [31:0]  iosqtdbl;
  logic [3:0]   s_axi_awid;
  logic [3:0]   m_axi_rid;
  logic [3:0]   m_axi_awid;
  logic [7:0]   data_length;
  logic [255:0] cpl;
  logic is_waiting;
  logic [31:0] waiting_count;
  logic [31:0] error_count;
  logic is_rw; // 0 : read / 1 : write
  logic [255:0] wrdata;

  localparam READ = 0;
  localparam WRITE = 1;

  // m axi ar fifo signals
  // ar : 32 + 2 + 4  + 8 + 3 = 49
  logic [48:0] m_axi_ar_fifo_din;
  logic [48:0] m_axi_ar_fifo_dout;
  logic m_axi_ar_fifo_empty;
  logic m_axi_ar_fifo_full;
  logic m_axi_ar_fifo_pop;
  logic m_axi_ar_fifo_valid;

  assign oculink_0a_m_axi_arready = !m_axi_ar_fifo_full;
  assign m_axi_ar_fifo_din = {
                              oculink_0a_m_axi_araddr,  // 32  
                              oculink_0a_m_axi_arburst, // 2  
                              oculink_0a_m_axi_arid,    // 4
                              oculink_0a_m_axi_arlen,   // 8
                              oculink_0a_m_axi_arsize   // 3  
                            };

  m_axi_ar_fifo m_axi_ar_fifo_i (
    .srst(!rstn),
    .wr_clk(clk),
    .rd_clk(clk),
    .din(m_axi_ar_fifo_din),
    .wr_en(oculink_0a_m_axi_arvalid && is_waiting),
    .rd_en(m_axi_ar_fifo_pop && !m_axi_ar_fifo_empty), 
    .dout(m_axi_ar_fifo_dout),
    .full(m_axi_ar_fifo_full),
    .empty(m_axi_ar_fifo_empty),
    .valid(m_axi_ar_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );

  // m axi aw fifo signals
  // aw : 32 + 2 + 4  + 8 + 3 = 49
  logic [48:0] m_axi_aw_fifo_din;
  logic [48:0] m_axi_aw_fifo_dout;
  logic m_axi_aw_fifo_empty;
  logic m_axi_aw_fifo_full;
  logic m_axi_aw_fifo_pop;
  logic m_axi_aw_fifo_valid;

  assign oculink_0a_m_axi_awready = !m_axi_aw_fifo_full;
  assign m_axi_aw_fifo_din = {
                              oculink_0a_m_axi_awaddr,  // 32  
                              oculink_0a_m_axi_awburst, // 2  
                              oculink_0a_m_axi_awid,    // 4
                              oculink_0a_m_axi_awlen,   // 8
                              oculink_0a_m_axi_awsize   // 3  
                            };

  m_axi_ar_fifo m_axi_aw_fifo_i (
    .srst(!rstn),
    .wr_clk(clk),
    .rd_clk(clk),
    .din(m_axi_aw_fifo_din),
    .wr_en(oculink_0a_m_axi_awvalid && is_waiting),
    .rd_en(m_axi_aw_fifo_pop && !m_axi_aw_fifo_empty), 
    .dout(m_axi_aw_fifo_dout),
    .full(m_axi_aw_fifo_full),
    .empty(m_axi_aw_fifo_empty),
    .valid(m_axi_aw_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );

  // m axi w fifo signals
  // w : 256 + 1 + 32  = 289
  logic [288:0] m_axi_w_fifo_din;
  logic [288:0] m_axi_w_fifo_dout;
  logic m_axi_w_fifo_empty;
  logic m_axi_w_fifo_full;
  logic m_axi_w_fifo_pop;
  logic m_axi_w_fifo_valid;

  assign oculink_0a_m_axi_wready = !m_axi_w_fifo_full;
  assign m_axi_w_fifo_din = {
                              oculink_0a_m_axi_wdata,  // 256
                              oculink_0a_m_axi_wlast,  // 1  
                              oculink_0a_m_axi_wstrb  // 32
                            };

  m_axi_w_fifo m_axi_w_fifo_i (
    .srst(!rstn),
    .wr_clk(clk),
    .rd_clk(clk),
    .din(m_axi_w_fifo_din),
    .wr_en(oculink_0a_m_axi_wvalid && is_waiting),
    .rd_en(m_axi_w_fifo_pop && !m_axi_w_fifo_empty), 
    .dout(m_axi_w_fifo_dout),
    .full(m_axi_w_fifo_full),
    .empty(m_axi_w_fifo_empty),
    .valid(m_axi_w_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  ila_rw ila_rw_i(
    .clk(clk),
    .probe0(do_write),  // 1
    .probe1(rw_state),  // 4->8
    .probe2(iosqtdbl),  // 32
    .probe3(s_axi_awid),  // 4
    .probe4(m_axi_rid), // 4
    .probe5(m_axi_awid),  // 4
    .probe6(data_length), // 8
    .probe7(cpl), //256
    .probe8(is_waiting),  // 1
    .probe9(waiting_count), // 16->32
    .probe10(m_axi_ar_fifo_din), // 49
    .probe11(m_axi_ar_fifo_dout),  // 49
    .probe12(m_axi_ar_fifo_empty), // 1
    .probe13(m_axi_ar_fifo_full),  // 1
    .probe14(m_axi_ar_fifo_pop), // 1
    .probe15(m_axi_ar_fifo_valid),  // 1
    .probe16(do_read) // 1
  );



  always_ff @(posedge clk or negedge rstn) begin
    if(!rstn) begin
      rw_state            <= ST_IDLE;
      iosqtdbl            <= 1;
      s_axi_awid          <= 0;
      m_axi_rid           <= 0;
      m_axi_awid          <= 0;
      data_length         <= 0;
      cpl                 <= 0;
      is_waiting <= 0;
      waiting_count <= 0;
      error_count <= 0;
      is_rw <= 0;
      wrdata <= 0;

      oculink_0a_s_axi_awaddr   <= 0;
      oculink_0a_s_axi_awburst  <= 0;
      oculink_0a_s_axi_awid     <= 0;
      oculink_0a_s_axi_awlen    <= 0;
      oculink_0a_s_axi_awregion <= 0;
      oculink_0a_s_axi_awsize   <= 0;
      oculink_0a_s_axi_awvalid  <= 0;
      
      oculink_0a_s_axi_wdata  <= 0;
      oculink_0a_s_axi_wlast  <= 0;
      oculink_0a_s_axi_wstrb  <= 0;
      oculink_0a_s_axi_wvalid <= 0;

      oculink_0a_s_axi_bready <= 0;
    end
    else begin
      case(rw_state)
        ST_IDLE : begin
          oculink_0a_s_axi_bready <= 1;

          oculink_0a_s_axi_awvalid <= 0;
          oculink_0a_s_axi_wvalid <= 0;
          oculink_0a_m_axi_rvalid <= 0;
          oculink_0a_m_axi_bvalid <= 0;

          if (do_write) begin
            rw_state <= ST_IOSQDBL_SEND_ADDR;
            is_rw <= WRITE;
          end

          if (do_read) begin
            rw_state <= ST_IOSQDBL_SEND_ADDR;
            is_rw <= READ;
          end
        end

        // s_axi_aw
        ST_IOSQDBL_SEND_ADDR : begin
          oculink_0a_s_axi_awvalid <= 0;

          if (oculink_0a_s_axi_awready) begin
            oculink_0a_s_axi_awaddr   <= NVME_BAR + 32'h1008;
            oculink_0a_s_axi_awburst  <= 2'd1;
            oculink_0a_s_axi_awid     <= s_axi_awid;
            oculink_0a_s_axi_awlen    <= 8'd0;
            oculink_0a_s_axi_awregion <= 4'd0;
            oculink_0a_s_axi_awsize   <= 3'd2;
            oculink_0a_s_axi_awvalid  <= 1;

            s_axi_awid <= s_axi_awid + 1;

            rw_state <= ST_IOSQDBL_SEND_DATA;
          end
        end

        // s_axi_w
        ST_IOSQDBL_SEND_DATA : begin 
          oculink_0a_s_axi_awvalid <= 0;
          oculink_0a_s_axi_wvalid <= 0;

          if (oculink_0a_s_axi_wready) begin
            oculink_0a_s_axi_wdata <= {
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl
                                      };
            oculink_0a_s_axi_wlast <= 1;
            oculink_0a_s_axi_wstrb <= 32'hffff_ffff;
            oculink_0a_s_axi_wvalid <= 1;

            iosqtdbl <= iosqtdbl + 1;

            rw_state <= ST_IOSQDBL_SEND_RESP;
          end
        end
  
        // s_axi_b
        ST_IOSQDBL_SEND_RESP : begin
          oculink_0a_s_axi_wvalid <= 0;

          if (oculink_0a_s_axi_bvalid && (oculink_0a_s_axi_bresp == 2'd0) ) begin
            rw_state <= ST_WRCMD_RECV_ADDR;
          end
        end

        // m_axi_ar
        ST_WRCMD_RECV_ADDR : begin
          if ( oculink_0a_m_axi_arvalid &&
              (oculink_0a_m_axi_araddr >= 32'hB000) &&
              (oculink_0a_m_axi_araddr < 32'hC000) ) begin
              if (is_rw == WRITE) rw_state <= ST_WRCMD_SEND_CMD0;
              else if (is_rw == READ) rw_state <= ST_RDCMD_SEND_CMD0;
          end
        end

        // m_axi_r
        ST_WRCMD_SEND_CMD0 : begin
          oculink_0a_m_axi_rvalid <= 0;

          if (oculink_0a_m_axi_rready) begin
            oculink_0a_m_axi_rdata <= { 
                                        32'h0000_0000,  // DW7
                                        32'h0000_C000,  // DW6
                                        32'h0000_D000,  // DW5
                                        32'h0000_0000,  // DW4
                                        32'h0000_0000,  // DW3
                                        32'h0000_0000,  // DW2
                                        32'h0000_0001,  // DW1
                                        32'h0000_0001   // DW0
                                      };
            oculink_0a_m_axi_rid <= 0; 
            oculink_0a_m_axi_rlast <= 0;
            oculink_0a_m_axi_rresp <= 0;
            oculink_0a_m_axi_rvalid <= 1;

            rw_state <= ST_WRCMD_SEND_CMD1;
          end
        end
        
        // m_axi_r
        ST_WRCMD_SEND_CMD1 : begin
          oculink_0a_m_axi_rvalid <= 0;

          if (oculink_0a_m_axi_rready) begin
            oculink_0a_m_axi_rdata <= {
                                        32'h0000_0000,  // DW15
                                        32'h0000_C000,  // DW14
                                        32'h0000_D000,  // DW13
                                        32'h0000_0000,  // DW12
                                        32'h0000_0000,  // DW11
                                        32'h0000_1000,  // DW10
                                        32'h0000_0000,  // DW9
                                        32'h0000_0000   // DW8
                                      };
            oculink_0a_m_axi_rid <= m_axi_rid; 
            oculink_0a_m_axi_rlast <= 1;
            oculink_0a_m_axi_rresp <= 0;
            oculink_0a_m_axi_rvalid <= 1;

            m_axi_rid <= m_axi_rid + 1;

            rw_state <= ST_WRDATA_RECV_ADDR0;
          end
        end

        // m_axi_r
        ST_RDCMD_SEND_CMD0 : begin
          oculink_0a_m_axi_rvalid <= 0;

          if (oculink_0a_m_axi_rready) begin
            oculink_0a_m_axi_rdata <= { 
                                        32'h0000_0000,  // DW7
                                        32'h0000_C000,  // DW6
                                        32'h0000_0000,  // DW5
                                        32'h0000_0000,  // DW4
                                        32'h0000_0000,  // DW3
                                        32'h0000_0000,  // DW2
                                        32'h0000_0001,  // DW1
                                        32'h0000_0002   // DW0
                                      };
            oculink_0a_m_axi_rid <= 0; 
            oculink_0a_m_axi_rlast <= 0;
            oculink_0a_m_axi_rresp <= 0;
            oculink_0a_m_axi_rvalid <= 1;

            rw_state <= ST_RDCMD_SEND_CMD1;
          end
        end
        
        // m_axi_r
        ST_RDCMD_SEND_CMD1 : begin
          oculink_0a_m_axi_rvalid <= 0;

          if (oculink_0a_m_axi_rready) begin
            oculink_0a_m_axi_rdata <= {
                                        32'h0000_0000,  // DW15
                                        32'h0000_0000,  // DW14
                                        32'h0000_0000,  // DW13
                                        32'h0000_0000,  // DW12
                                        32'h0000_0000,  // DW11
                                        32'h0000_1000,  // DW10
                                        32'h0000_0000,  // DW9
                                        32'h0000_0000   // DW8
                                      };
            oculink_0a_m_axi_rid <= m_axi_rid; 
            oculink_0a_m_axi_rlast <= 1;
            oculink_0a_m_axi_rresp <= 0;
            oculink_0a_m_axi_rvalid <= 1;

            m_axi_rid <= m_axi_rid + 1;

            rw_state <= ST_RDDATA_RECV_ADDR0;
          end
        end
  
        // m_axi_ar
        ST_WRDATA_RECV_ADDR0 : begin
          oculink_0a_m_axi_rvalid <= 0;
          is_waiting <= 1;

          // 1. NVMe requset write data
          if (!m_axi_ar_fifo_empty) begin
            m_axi_ar_fifo_pop <= 1;
            rw_state <= ST_WRDATA_RECV_ADDR1;
          end

          // 2. All write data is sent, wait for completion
          else if (oculink_0a_m_axi_awvalid &&
              oculink_0a_m_axi_awaddr >= 32'hA000 &&
              oculink_0a_m_axi_awaddr < 32'hB000) begin

            m_axi_awid <= oculink_0a_m_axi_awid;
            is_waiting <= 0;  // turn off write data request from NVMe

            rw_state <= ST_CPL_RECV_DATA;
          end

          // 3. Timeout
          else if (waiting_count == 32'hffff_ffff) begin
            rw_state <= ST_TIMEOUT;
            waiting_count <= 0;
          end

          else begin
            waiting_count <= waiting_count + 1;
          end
        end

        // m_axi_ar
        ST_WRDATA_RECV_ADDR1 : begin
          m_axi_ar_fifo_pop <= 0;

          if (m_axi_ar_fifo_valid) begin
            data_length <= m_axi_ar_fifo_dout[10:3];

            rw_state <= ST_WRDATA_SEND_DATA;
          end
        end

        // m_axi_r
        ST_WRDATA_SEND_DATA : begin
          oculink_0a_m_axi_rvalid <= 0;

          if (oculink_0a_m_axi_rready) begin
            oculink_0a_m_axi_rdata <= {
                                        32'h1234_1234,
                                        32'h5678_5678,
                                        32'h90ab_90ab,
                                        32'hcdef_cdef,
                                        32'h1234_1234,
                                        32'h5678_5678,
                                        32'h90ab_90ab,
                                        32'hcdef_cdef
                                      };
            oculink_0a_m_axi_rid <= m_axi_rid; 
            oculink_0a_m_axi_rlast <= (data_length == 0) ? 1 : 0;
            oculink_0a_m_axi_rresp <= 0;
            oculink_0a_m_axi_rvalid <= 1;

            m_axi_rid <= m_axi_rid + 1;
            data_length <= data_length - 1;

            rw_state <= (data_length == 0) ? ST_WRDATA_RECV_ADDR0 : ST_WRDATA_SEND_DATA;
          end
        end


        // m_axi_aw
        ST_RDDATA_RECV_ADDR0 : begin
          oculink_0a_m_axi_rvalid <= 0;
          oculink_0a_m_axi_bvalid <= 0;
          
          is_waiting <= 1;

          // 1. NVMe send read data
          if (!m_axi_aw_fifo_empty) begin
            m_axi_aw_fifo_pop <= 1;
            rw_state <= ST_RDDATA_RECV_ADDR1;
          end

          // 2. Timeout
          else if (waiting_count == 32'hffff_ffff) begin
            rw_state <= ST_TIMEOUT;
            waiting_count <= 0;
          end

          else begin
            waiting_count <= waiting_count + 1;
          end
        end

        // m_axi_aw
        ST_RDDATA_RECV_ADDR1 : begin
          m_axi_aw_fifo_pop <= 0;

          if (m_axi_aw_fifo_valid) begin

            // received completion
            if ((m_axi_aw_fifo_dout[48:17] >= 32'hA000) && 
                (m_axi_aw_fifo_dout[48:17] < 32'hB000)) begin
              is_waiting <= 0;
              m_axi_w_fifo_pop <= 1;
              rw_state <= ST_RDDATA_RECV_CPL;
            end

            // received read data
            else begin
              data_length <= m_axi_aw_fifo_dout[10:3];
              m_axi_awid <= m_axi_aw_fifo_dout[14:11];
              m_axi_w_fifo_pop <= 1;
              rw_state <= ST_RDDATA_RECV_DATA;
            end
          end
        end

        // m_axi_w
        ST_RDDATA_RECV_DATA : begin
          m_axi_w_fifo_pop <= 0;

          if (m_axi_w_fifo_valid) begin
            m_axi_w_fifo_pop <= ((data_length == 0) && m_axi_w_fifo_dout[32]) ? 0 : 1;

            wrdata <= m_axi_w_fifo_dout[288:33];
            data_length <= data_length - 1;
            rw_state <= ((data_length == 0) && m_axi_w_fifo_dout[32]) ? ST_RDDATA_RECV_RESP : ST_RDDATA_RECV_DATA;
          end
        end

        ST_RDDATA_RECV_RESP : begin
          oculink_0a_m_axi_bvalid <= 0;
          
          if (oculink_0a_m_axi_bready) begin
            oculink_0a_m_axi_bid <= m_axi_awid;
            oculink_0a_m_axi_bresp <= 0;
            oculink_0a_m_axi_bvalid <= 1;

            rw_state <= ST_RDDATA_RECV_ADDR0;
          end
        end

        ST_RDDATA_RECV_CPL : begin
          m_axi_w_fifo_pop <= 0;

          if (m_axi_w_fifo_valid) begin
            cpl <= m_axi_w_fifo_dout[288:33];

            rw_state <= ST_CPL_SEND_RESP;
          end
        end

        // m_axi_w
        ST_CPL_RECV_DATA : begin
          if (oculink_0a_m_axi_wvalid) begin
            cpl <= oculink_0a_m_axi_wdata;

            rw_state <= ST_CPL_SEND_RESP;
          end
        end

        // m_axi_b
        ST_CPL_SEND_RESP : begin
          oculink_0a_m_axi_bvalid <= 0;

          if (oculink_0a_m_axi_bready) begin
            oculink_0a_m_axi_bid <= m_axi_awid;
            oculink_0a_m_axi_bresp <= 0;
            oculink_0a_m_axi_bvalid <= 1;

            rw_state <= ST_IDLE;
          end
        end

      endcase
    end
  end



endmodule