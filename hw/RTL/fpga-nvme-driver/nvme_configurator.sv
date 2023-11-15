
module nvme_configurator (
  input logic           host_bram_clk,
  input logic           oculink_axi_clk,
  input logic           rstn,
  input logic           oculink_lnk_up,

  input logic           cfg_write,
  input logic           cfg_read,
  input logic [31:0]    cfg_wraddr,
  input logic [31:0]    cfg_wrdata,
  input logic [31:0]    cfg_rdaddr,
  output logic [31:0]   cfg_rddata,
  output logic          cfg_wr_done,
  output logic          cfg_rd_done,

  // AXI Slave Interface
  input logic           oculink_s_axi_arready,
  output logic [31:0]   oculink_s_axi_araddr,
  output logic [1:0]    oculink_s_axi_arburst,
  output logic [3:0]    oculink_s_axi_arid,
  output logic [7:0]    oculink_s_axi_arlen,
  output logic [3:0]    oculink_s_axi_arregion,
  output logic [2:0]    oculink_s_axi_arsize,
  output logic          oculink_s_axi_arvalid,
  
  input logic           oculink_s_axi_awready,
  output logic [31:0]   oculink_s_axi_awaddr,
  output logic [1:0]    oculink_s_axi_awburst,
  output logic [3:0]    oculink_s_axi_awid,
  output logic [7:0]    oculink_s_axi_awlen,
  output logic [3:0]    oculink_s_axi_awregion,
  output logic [2:0]    oculink_s_axi_awsize,
  output logic          oculink_s_axi_awvalid,
  
  input logic           oculink_s_axi_wready,
  output logic [255:0]  oculink_s_axi_wdata,
  output logic          oculink_s_axi_wlast,
  output logic [31:0]   oculink_s_axi_wstrb,
  output logic          oculink_s_axi_wvalid,

  output logic          oculink_s_axi_rready,
  input logic [255:0]   oculink_s_axi_rdata,
  input logic [3:0]     oculink_s_axi_rid,
  input logic           oculink_s_axi_rlast,
  input logic [1:0]     oculink_s_axi_rresp,
  input logic           oculink_s_axi_rvalid,

  output logic          oculink_s_axi_bready,
  input logic [3:0]     oculink_s_axi_bid,
  input logic [1:0]     oculink_s_axi_bresp,
  input logic           oculink_s_axi_bvalid
  );

  assign oculink_s_axi_rready = 1;
  assign oculink_s_axi_bready = 1;

  /* CSR to CFG */
  logic cfg_start_write;
  logic cfg_start_read;

  csr2cfg csr2cfg_w_i(
    .srst   (!rstn),
    .wr_clk (host_bram_clk),
    .rd_clk (oculink_axi_clk),
    .din    (cfg_write),
    .wr_en  (cfg_write),
    .dout   (),
    .rd_en  (1),
    .full   (),
    .empty  (),
    .valid  (cfg_start_write),
    .wr_rst_busy(),
    .rd_rst_busy()
  );

  csr2cfg csr2cfg_r_i(
    .srst   (!rstn),
    .wr_clk (host_bram_clk),
    .rd_clk (oculink_axi_clk),
    .din    (cfg_read),
    .wr_en  (cfg_read),
    .dout   (),
    .rd_en  (1),
    .valid  (cfg_start_read),
    .full   (),
    .empty  (),
    .wr_rst_busy(),
    .rd_rst_busy()
  );

  /* Write cfg */

  localparam WR_IDLE      = 8'd0;
  localparam WR_SEND_ADDR = 8'd1;
  localparam WR_SEND_DATA = 8'd2;
  localparam WR_WAIT_RESP = 8'd3;
  localparam WR_DONE      = 8'd4;

  logic [7:0]   wr_state;
  logic [31:0]  wr_addr;
  logic [31:0]  wr_data;
  //logic         wr_done;
  logic [3:0]   awid;

  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      wr_state    <= WR_IDLE;
      wr_addr     <= 0;
      wr_data     <= 0;
      cfg_wr_done <= 0;
      awid        <= 0;

      oculink_s_axi_awaddr    <= 0;
      oculink_s_axi_awburst   <= 0;
      oculink_s_axi_awid      <= 0;
      oculink_s_axi_awlen     <= 0;
      oculink_s_axi_awregion  <= 0;
      oculink_s_axi_awsize    <= 0;
      oculink_s_axi_awvalid   <= 0;
      oculink_s_axi_wdata     <= 0;
      oculink_s_axi_wlast     <= 0;
      oculink_s_axi_wstrb     <= 0;
      oculink_s_axi_wvalid    <= 0;
    end
    else begin
      case(wr_state)
        WR_IDLE: begin
          if (cfg_start_write) begin
            wr_addr     <= cfg_wraddr;
            wr_data     <= cfg_wrdata;
            cfg_wr_done <= 0;
            wr_state    <= WR_SEND_ADDR;
          end
        end

        WR_SEND_ADDR: begin
          if (oculink_s_axi_awready) begin
            oculink_s_axi_awaddr    <= wr_addr;
            oculink_s_axi_awburst   <= 2'd1;  // Incremental burst
            oculink_s_axi_awid      <= awid;
            oculink_s_axi_awlen     <= 0;
            oculink_s_axi_awregion  <= 0;
            oculink_s_axi_awsize    <= 3'd2;  // 4 Bytes
            oculink_s_axi_awvalid   <= 1;

            awid                    <= awid + 1;
            wr_state                <= WR_SEND_DATA;
          end
        end

        WR_SEND_DATA: begin
          oculink_s_axi_awvalid <= 0;

          if (oculink_s_axi_wready) begin
            oculink_s_axi_wdata     <= {
                                        wr_data,
                                        wr_data,
                                        wr_data,
                                        wr_data,
                                        wr_data,
                                        wr_data,
                                        wr_data,
                                        wr_data
                                      };
            oculink_s_axi_wlast     <= 1;
            oculink_s_axi_wstrb     <= 32'hffff_ffff;
            oculink_s_axi_wvalid    <= 1;

            wr_state                <= WR_WAIT_RESP;
          end
        end

        WR_WAIT_RESP: begin
          oculink_s_axi_wlast     <= 0;
          oculink_s_axi_wvalid    <= 0;
          
          if (oculink_s_axi_bvalid && (oculink_s_axi_bresp == 0)) begin
            wr_state <= WR_DONE;
          end
        end

        WR_DONE: begin
          cfg_wr_done             <= 1;
          wr_state                <= WR_IDLE;
        end
      endcase
    end
  end


  /* Read CFG */

  localparam RD_IDLE      = 8'd0;
  localparam RD_SEND_ADDR = 8'd1;
  localparam RD_RECV_DATA = 8'd2;
  localparam RD_DONE      = 8'd3;

  logic [7:0]   rd_state;
  logic [31:0]  rd_addr;
  logic [31:0]  rd_data;
  //logic         rd_done;
  logic [3:0]   arid;

  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      rd_state    <= RD_IDLE;
      rd_addr     <= 0;
      rd_data     <= 0;
      arid        <= 0;
      cfg_rddata  <= 0;
      cfg_rd_done <= 0;
      oculink_s_axi_araddr    <= 0;
      oculink_s_axi_arburst   <= 0;
      oculink_s_axi_arid      <= 0;
      oculink_s_axi_arlen     <= 0;
      oculink_s_axi_arregion  <= 0;
      oculink_s_axi_arsize    <= 0;
      oculink_s_axi_arvalid   <= 0;
    end
    else begin
      case(rd_state)
        RD_IDLE: begin
          if (cfg_start_read) begin
            cfg_rd_done   <= 0;
            rd_addr       <= cfg_rdaddr;
            rd_state      <= RD_SEND_ADDR;
          end
        end

        RD_SEND_ADDR: begin
          if (oculink_s_axi_arready) begin
            oculink_s_axi_araddr    <= rd_addr;
            oculink_s_axi_arburst   <= 2'd1;  // Incremental burst
            oculink_s_axi_arid      <= arid;
            oculink_s_axi_arlen     <= 0;
            oculink_s_axi_arregion  <= 0;
            oculink_s_axi_arsize    <= 3'd2;  // 4 Bytes
            oculink_s_axi_arvalid   <= 1;

            arid                    <= arid + 1;
            rd_state                <= RD_RECV_DATA;
          end
        end

        RD_RECV_DATA: begin
          oculink_s_axi_arvalid <= 0;

          if (oculink_s_axi_rvalid) begin
            rd_data <= oculink_s_axi_rdata[32 * 0 +: 32];
            if (oculink_s_axi_rlast) rd_state <= RD_DONE;
          end
        end

        RD_DONE: begin
          cfg_rd_done <= 1;
          cfg_rddata  <= rd_data;
          rd_state    <= RD_IDLE;
        end
      endcase
    end
  end

endmodule