
module nvme_driver #(
  parameter AXI_SLAVE_BAR     = 32'h8000_0000,
  parameter NVME_CTRL_OFFSET  = 32'h0000_4000,
  parameter NVME_BAR          = AXI_SLAVE_BAR + NVME_CTRL_OFFSET,
  parameter ADB_OFFSET        = 32'h1000 + NVME_BAR,
  parameter IODB_OFFSET       = 32'h1008 + NVME_BAR,
  parameter ASQ_BAR           = 32'h8000,
  parameter ASQ_SIZE          = 32'h1000,
  parameter ACQ_BAR           = 32'h9000,
  parameter ACQ_SIZE          = 32'h1000,
  parameter IOSQ_BAR          = 32'hB000,
  parameter IOSQ_SIZE         = 32'h1000,
  parameter IOCQ_BAR          = 32'hA000,
  parameter IOCQ_SIZE         = 32'h1000,
  parameter IORW_BAR          = IOSQ_BAR + IOSQ_SIZE
)(
  input logic           rstn,
  input logic           host_bram_clk,
  input logic           oculink_axi_clk,

  // CSR Admin, IO cmd signals
  input logic           send_iocq_create_cmd,
  input logic           send_iosq_create_cmd,
  input logic           send_read_cmd,
  input logic           send_write_cmd,
  input logic [31:0]    nvme_addr,
  input logic [31:0]    fpga_addr,
  input logic [31:0]    nlb,
  output logic          cpl_done,
  input logic [31:0]    wrdata [7:0],
  output logic [31:0]   rddata [7:0],   // read-back data to host (last 32B of read payload)
  output logic [31:0]   cpl_status,     // last completion CQE DW3 (status/phase/cid)
  output logic [31:0]   cpl_count,      // monotonic completion counter (multi-outstanding)


  // AXI Slave : aw, w, b 
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
  output logic          oculink_s_axi_bready,
  input logic [3:0]     oculink_s_axi_bid,
  input logic [1:0]     oculink_s_axi_bresp,
  input logic           oculink_s_axi_bvalid,

  // AXI Master 
  output logic          oculink_m_axi_arready,
  input logic [31:0]    oculink_m_axi_araddr,
  input logic [1:0]     oculink_m_axi_arburst,
  input logic [3:0]     oculink_m_axi_arcache,
  input logic [3:0]     oculink_m_axi_arid,
  input logic [7:0]     oculink_m_axi_arlen,
  input logic           oculink_m_axi_arlock,
  input logic [2:0]     oculink_m_axi_arprot,
  input logic [2:0]     oculink_m_axi_arsize,
  input logic           oculink_m_axi_arvalid,
  output logic          oculink_m_axi_awready,
  input logic [31:0]    oculink_m_axi_awaddr,
  input logic [1:0]     oculink_m_axi_awburst,
  input logic [3:0]     oculink_m_axi_awcache,
  input logic [3:0]     oculink_m_axi_awid,
  input logic [7:0]     oculink_m_axi_awlen,
  input logic           oculink_m_axi_awlock,
  input logic [2:0]     oculink_m_axi_awprot,
  input logic [2:0]     oculink_m_axi_awsize,
  input logic           oculink_m_axi_awvalid,
  output logic          oculink_m_axi_wready,
  input logic [255:0]   oculink_m_axi_wdata,
  input logic           oculink_m_axi_wlast,
  input logic [31:0]    oculink_m_axi_wstrb,
  input logic           oculink_m_axi_wvalid,
  input logic           oculink_m_axi_rready,
  output logic [255:0]  oculink_m_axi_rdata,
  output logic [3:0]    oculink_m_axi_rid,
  output logic          oculink_m_axi_rlast,
  output logic [1:0]    oculink_m_axi_rresp,
  output logic          oculink_m_axi_rvalid,
  input logic           oculink_m_axi_bready,
  output logic [3:0]    oculink_m_axi_bid,
  output logic [1:0]    oculink_m_axi_bresp,
  output logic          oculink_m_axi_bvalid
  );

  /* ready signals */
  assign oculink_s_axi_bready   = 1;
  assign oculink_m_axi_arready  = 1;
  assign oculink_m_axi_awready  = 1;
  assign oculink_m_axi_wready   = 1;

  logic is_sending_cmd;
  logic is_receving_cpl;

  logic [255:0]  oculink_m_axi_rdata_cmd;
  logic [3:0]    oculink_m_axi_rid_cmd;
  logic          oculink_m_axi_rlast_cmd;
  logic [1:0]    oculink_m_axi_rresp_cmd;
  logic          oculink_m_axi_rvalid_cmd;
  logic [255:0]  oculink_m_axi_rdata_wr;
  logic [3:0]    oculink_m_axi_rid_wr;
  logic          oculink_m_axi_rlast_wr;
  logic [1:0]    oculink_m_axi_rresp_wr;
  logic          oculink_m_axi_rvalid_wr;
  logic [3:0]    oculink_m_axi_bid_cpl;
  logic [1:0]    oculink_m_axi_bresp_cpl;
  logic          oculink_m_axi_bvalid_cpl;
  logic [3:0]    oculink_m_axi_bid_rd;
  logic [1:0]    oculink_m_axi_bresp_rd;
  logic          oculink_m_axi_bvalid_rd;

  // ---------------- m_axi in-order demux tag FIFOs ----------------
  // Root cause of the QD>1 hang: the R/B muxes selected on a PRODUCER-STATE flag (is_sending_cmd /
  // is_receving_cpl), not on "which transaction the SSD is waiting on". Since oculink_m_axi_{ar,aw}ready
  // are tied 1 and rid/bid are single-ID 0, AR-accept order IS the mandatory R-return order and AW-accept
  // order IS the B order. So record the class of each accepted AR/AW in an in-order FWFT tag FIFO and serve
  // the head (= oldest outstanding transaction). is_sending_cmd / is_receving_cpl are kept driven for the
  // ILA probes but no longer select the mux.

  // R-tag: {is_sqe, arlen[7:0]} per accepted AR; head selects the R source; pop on the served burst's rlast.
  localparam RTAG_W = 9;
  wire ar_is_sqe   = ((oculink_m_axi_araddr >= IOSQ_BAR) && (oculink_m_axi_araddr < IOSQ_BAR + IOSQ_SIZE)) ||
                     ((oculink_m_axi_araddr >= ASQ_BAR)  && (oculink_m_axi_araddr < ASQ_BAR  + ASQ_SIZE));
  wire ar_is_admin = (oculink_m_axi_araddr >= ASQ_BAR)  && (oculink_m_axi_araddr < ASQ_BAR + ASQ_SIZE);
  logic [RTAG_W-1:0] rtag_head;
  logic              rtag_empty, rtag_full;
  wire               rtag_pop = oculink_m_axi_rvalid & oculink_m_axi_rready & oculink_m_axi_rlast;
  tagfifo #(.WIDTH(RTAG_W), .DEPTH(256)) rtag_i (
    .clk(oculink_axi_clk), .srst(!rstn),
    .push(oculink_m_axi_arvalid), .din({ar_is_sqe, oculink_m_axi_arlen}),
    .pop(rtag_pop), .head(rtag_head), .empty(rtag_empty), .full(rtag_full)
  );
  wire        rtag_head_is_sqe = rtag_head[8];
  wire [7:0]  rtag_head_arlen  = rtag_head[7:0];
  wire        rtag_sel_cmd     = (!rtag_empty) & rtag_head_is_sqe;  // R mux: 1=SQE(cmd), 0=write-data(wrdata)

  // SQE-AR buffer: records each accepted SQE-class AR so the cmd FSM never misses an unbuffered arvalid.
  logic sqear_head;
  logic sqear_empty, sqear_full, sqear_pop;
  tagfifo #(.WIDTH(1), .DEPTH(16)) sqear_i (
    .clk(oculink_axi_clk), .srst(!rstn),
    .push(oculink_m_axi_arvalid & ar_is_sqe), .din(ar_is_admin),
    .pop(sqear_pop), .head(sqear_head), .empty(sqear_empty), .full(sqear_full)
  );

  // W-tag: is_cqe per accepted AW; head selects the B source; pop on the burst's B handshake.
  wire aw_is_cqe = (oculink_m_axi_awaddr >= ACQ_BAR) && (oculink_m_axi_awaddr < IOSQ_BAR); // ACQ|IOCQ ranges
  logic wtag_head;
  logic wtag_empty, wtag_full;
  wire  wtag_pop = oculink_m_axi_bvalid & oculink_m_axi_bready;
  tagfifo #(.WIDTH(1), .DEPTH(256)) wtag_i (
    .clk(oculink_axi_clk), .srst(!rstn),
    .push(oculink_m_axi_awvalid), .din(aw_is_cqe),
    .pop(wtag_pop), .head(wtag_head), .empty(wtag_empty), .full(wtag_full)
  );
  wire wtag_sel_cpl = (!wtag_empty) & wtag_head;   // B mux: 1=CQE(cpl), 0=read-data(rd)

  assign oculink_m_axi_rdata  = rtag_sel_cmd ? oculink_m_axi_rdata_cmd  : oculink_m_axi_rdata_wr;
  assign oculink_m_axi_rid    = rtag_sel_cmd ? oculink_m_axi_rid_cmd    : oculink_m_axi_rid_wr;
  assign oculink_m_axi_rlast  = rtag_sel_cmd ? oculink_m_axi_rlast_cmd  : oculink_m_axi_rlast_wr;
  assign oculink_m_axi_rresp  = rtag_sel_cmd ? oculink_m_axi_rresp_cmd  : oculink_m_axi_rresp_wr;
  assign oculink_m_axi_rvalid = rtag_sel_cmd ? oculink_m_axi_rvalid_cmd : oculink_m_axi_rvalid_wr;
  assign oculink_m_axi_bid    = wtag_sel_cpl ? oculink_m_axi_bid_cpl    : oculink_m_axi_bid_rd;
  assign oculink_m_axi_bresp  = wtag_sel_cpl ? oculink_m_axi_bresp_cpl  : oculink_m_axi_bresp_rd;
  assign oculink_m_axi_bvalid = wtag_sel_cpl ? oculink_m_axi_bvalid_cpl : oculink_m_axi_bvalid_rd;


  /* IO Submission Queue */
  logic [96:0]  iosq_din;
  logic [96:0]  iosq_dout;
  logic         iosq_push;
  logic         iosq_pop;
  logic         iosq_full;
  logic         iosq_empty;
  logic         iosq_valid;  

  localparam IOSQ_READ  = 1'b1;
  localparam IOSQ_WRITE = 1'b0;
  assign iosq_din = {(send_read_cmd) ? IOSQ_READ : IOSQ_WRITE, nvme_addr, fpga_addr, nlb};

  iosq iosq_i(
    .srst   (!rstn),
    .wr_clk (host_bram_clk),
    .rd_clk (oculink_axi_clk),
    .din    (iosq_din),
    .wr_en  (send_read_cmd || send_write_cmd),
    .dout   (iosq_dout),
    .rd_en  (iosq_pop),
    .full   (iosq_full),
    .empty  (iosq_empty),
    .valid  (iosq_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );

  /* Admin Submission Queue */
  logic asq_din;
  logic asq_dout;
  logic asq_push;
  logic asq_pop;
  logic asq_full;
  logic asq_empty;
  logic asq_valid;  

  localparam ASQ_CREATE_IOCQ = 1'b1;
  localparam ASQ_CREATE_IOSQ = 1'b0;
  assign asq_din = {(send_iocq_create_cmd) ? ASQ_CREATE_IOCQ : ASQ_CREATE_IOSQ}; // 1-bit

  asq asq_i(
    .srst   (!rstn),
    .wr_clk (host_bram_clk),
    .rd_clk (oculink_axi_clk),
    .din    (asq_din),
    .wr_en  (send_iocq_create_cmd || send_iosq_create_cmd),
    .dout   (asq_dout),
    .rd_en  (asq_pop),
    .full   (asq_full),
    .empty  (asq_empty),
    .valid  (asq_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );
            

  /* Doorbell */
  localparam DB_IDLE        = 8'd0;
  localparam DB_RING_IODBL  = 8'd1;
  localparam DB_RING_ADBL   = 8'd2;
  localparam DB_SEND_IODATA = 8'd3;
  localparam DB_SEND_ADATA  = 8'd4;
  localparam DB_WAIT_RESP   = 8'd5;
  localparam DB_DONE        = 8'd6;
  localparam DB_RING_IOCQH  = 8'd7;   // ring IO CQ head doorbell
  localparam DB_RING_ACQH   = 8'd8;   // ring admin CQ head doorbell
  localparam DB_SEND_IOCQH  = 8'd9;
  localparam DB_SEND_ACQH   = 8'd10;
  localparam DB_CQH_WAIT    = 8'd11;  // wait B for a CQ-head ring (no cmd_done handshake)

  logic [7:0]   db_state;
  logic         db_done;
  logic         cmd_done;   // declared early: used by db_state below, driven by cmd_state FSM
  // SQ tail doorbells are now counter-driven (no FIFO-emptiness race with cmd FSM):
  //   cmd FSM advances io_serve_cnt/a_serve_cnt when it pops/serves an SQE;
  //   db FSM rings the SQ tail doorbell to that value (coalescing), like the CQ-head ring.
  logic [31:0]  io_serve_cnt;   // IO  SQ tail value  (driven by cmd FSM)
  logic [31:0]  a_serve_cnt;    // admin SQ tail value (driven by cmd FSM)
  logic [31:0]  io_sq_rung;     // last IO  SQ tail rung (driven by db FSM)
  logic [31:0]  a_sq_rung;      // last admin SQ tail rung (driven by db FSM)

  // Queue depths (entries). Must match the QSIZE programmed in the IO queue-create commands.
  localparam IOSQ_QDEPTH = 32'd64;   // IO SQ depth (IOSQ_SIZE 0x1000 / 64B = 64 max)
  localparam ASQ_QDEPTH  = 32'd64;   // admin SQ depth (matches host AQA)
  localparam IOCQ_QDEPTH = 32'd64;   // IO CQ depth
  localparam ACQ_QDEPTH  = 32'd64;   // admin CQ depth
  localparam ICQDB_OFFSET = 32'h100C + NVME_BAR;  // IO CQ head doorbell (queue 1)
  localparam ACQDB_OFFSET = 32'h1004 + NVME_BAR;  // admin CQ head doorbell (queue 0)

  // CQ head doorbell tracking. iocqhdbl/acqhdbl advanced by cpl FSM per completion;
  // db FSM rings the CQ head doorbell to catch up (coalescing) so the CQ never fills.
  logic [31:0]  iocqhdbl;     // IO CQ head pointer    (driven by cpl FSM)
  logic [31:0]  acqhdbl;      // admin CQ head pointer (driven by cpl FSM)
  logic [31:0]  io_cqh_rung;  // last IO CQ head value rung    (driven by db FSM)
  logic [31:0]  a_cqh_rung;   // last admin CQ head value rung (driven by db FSM)
  logic         cpl_is_io;    // last captured completion was IO (vs admin)

  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      db_state                <= DB_IDLE;
      db_done                 <= 0;
      io_sq_rung              <= 0;
      a_sq_rung               <= 0;
      io_cqh_rung             <= 0;
      a_cqh_rung              <= 0;

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
      case(db_state)

        DB_IDLE: begin
          if      (iocqhdbl != io_cqh_rung)     db_state <= DB_RING_IOCQH;  // free IO CQ slots first
          else if (acqhdbl  != a_cqh_rung)      db_state <= DB_RING_ACQH;
          else if (io_serve_cnt != io_sq_rung)  db_state <= DB_RING_IODBL;  // counter-driven (no FIFO race)
          else if (a_serve_cnt  != a_sq_rung)   db_state <= DB_RING_ADBL;
        end

        DB_RING_IODBL: begin
          if (oculink_s_axi_awready) begin
            oculink_s_axi_awaddr    <= IODB_OFFSET;
            oculink_s_axi_awburst   <= 2'd1;
            oculink_s_axi_awid      <= 4'd0;
            oculink_s_axi_awlen     <= 8'd0;
            oculink_s_axi_awregion  <= 4'd0;
            oculink_s_axi_awsize    <= 3'd2;
            oculink_s_axi_awvalid   <= 1;
            db_state                <= DB_SEND_IODATA;
          end          
        end
        
        DB_RING_ADBL: begin
          if (oculink_s_axi_awready) begin
            oculink_s_axi_awaddr    <= ADB_OFFSET;
            oculink_s_axi_awburst   <= 2'd1;
            oculink_s_axi_awid      <= 4'd0;
            oculink_s_axi_awlen     <= 8'd0;
            oculink_s_axi_awregion  <= 4'd0;
            oculink_s_axi_awsize    <= 3'd2;
            oculink_s_axi_awvalid   <= 1;
            db_state                <= DB_SEND_ADATA;
          end          
        end

        DB_SEND_IODATA: begin
          oculink_s_axi_awvalid  <= 0;

          if (oculink_s_axi_wready) begin
            oculink_s_axi_wdata  <= {8{io_serve_cnt}};
            oculink_s_axi_wlast  <= 1;
            oculink_s_axi_wstrb  <= 32'hffff_ffff;
            oculink_s_axi_wvalid <= 1;
            io_sq_rung           <= io_serve_cnt;   // record rung (catches up to cmd's serve count)
            db_state             <= DB_WAIT_RESP;
          end
        end

        DB_SEND_ADATA: begin
          oculink_s_axi_awvalid  <= 0;

          if (oculink_s_axi_wready) begin
            oculink_s_axi_wdata  <= {8{a_serve_cnt}};
            oculink_s_axi_wlast  <= 1;
            oculink_s_axi_wstrb  <= 32'hffff_ffff;
            oculink_s_axi_wvalid <= 1;
            a_sq_rung            <= a_serve_cnt;
            db_state             <= DB_WAIT_RESP;
          end
        end

        DB_WAIT_RESP: begin
          oculink_s_axi_wvalid <= 0;

          if (oculink_s_axi_bvalid && (oculink_s_axi_bresp == 2'd0)) begin
            db_state  <= DB_DONE;
            db_done   <= 1;
          end
        end
        
        DB_DONE: begin
          if (cmd_done) begin
            db_done   <= 0;
            db_state  <= DB_IDLE;
          end
        end

        // ---- CQ head doorbell rings (no SQE serve, so no cmd_done handshake) ----
        DB_RING_IOCQH: begin
          if (oculink_s_axi_awready) begin
            oculink_s_axi_awaddr    <= ICQDB_OFFSET;
            oculink_s_axi_awburst   <= 2'd1;
            oculink_s_axi_awid      <= 4'd0;
            oculink_s_axi_awlen     <= 8'd0;
            oculink_s_axi_awregion  <= 4'd0;
            oculink_s_axi_awsize    <= 3'd2;
            oculink_s_axi_awvalid   <= 1;
            db_state                <= DB_SEND_IOCQH;
          end
        end

        DB_RING_ACQH: begin
          if (oculink_s_axi_awready) begin
            oculink_s_axi_awaddr    <= ACQDB_OFFSET;
            oculink_s_axi_awburst   <= 2'd1;
            oculink_s_axi_awid      <= 4'd0;
            oculink_s_axi_awlen     <= 8'd0;
            oculink_s_axi_awregion  <= 4'd0;
            oculink_s_axi_awsize    <= 3'd2;
            oculink_s_axi_awvalid   <= 1;
            db_state                <= DB_SEND_ACQH;
          end
        end

        DB_SEND_IOCQH: begin
          oculink_s_axi_awvalid <= 0;
          if (oculink_s_axi_wready) begin
            oculink_s_axi_wdata  <= {8{iocqhdbl}};
            oculink_s_axi_wlast  <= 1;
            oculink_s_axi_wstrb  <= 32'hffff_ffff;
            oculink_s_axi_wvalid <= 1;
            io_cqh_rung          <= iocqhdbl;   // record what we rung (coalesces with later completions)
            db_state             <= DB_CQH_WAIT;
          end
        end

        DB_SEND_ACQH: begin
          oculink_s_axi_awvalid <= 0;
          if (oculink_s_axi_wready) begin
            oculink_s_axi_wdata  <= {8{acqhdbl}};
            oculink_s_axi_wlast  <= 1;
            oculink_s_axi_wstrb  <= 32'hffff_ffff;
            oculink_s_axi_wvalid <= 1;
            a_cqh_rung           <= acqhdbl;
            db_state             <= DB_CQH_WAIT;
          end
        end

        DB_CQH_WAIT: begin
          oculink_s_axi_wvalid <= 0;
          if (oculink_s_axi_bvalid && (oculink_s_axi_bresp == 2'd0)) begin
            db_state <= DB_IDLE;   // straight back to IDLE (no cmd_done wait)
          end
        end

      endcase
    end
  end



  /* Command */
  
  localparam READ_OPCODE        = 32'h0000_0002;  // IO Command
  localparam WRITE_OPCODE       = 32'h0000_0001;  // IO Command
  localparam IOCQ_CREATE_OPCODE = 32'h0000_0005;  // Admin Command
  localparam IOSQ_CREATE_OPCODE = 32'h0000_0001;  // Admin Command

  localparam CMD_IDLE         = 8'd0;
  localparam CMD_POP_IOSQ     = 8'd1;
  localparam CMD_POP_ASQ      = 8'd2;
  localparam CMD_RECV_ADDR    = 8'd3;
  localparam CMD_SEND_IOCMD1  = 8'd4;
  localparam CMD_SEND_IOCMD2  = 8'd5;
  localparam CMD_SEND_ACMD1   = 8'd6;
  localparam CMD_SEND_ACMD2   = 8'd7;
  localparam CMD_DONE         = 8'd8;

  logic [7:0]   cmd_state;
  logic [31:0]  cmd_opcode;
  logic [31:0]  cmd_nvme_addr;
  logic [31:0]  cmd_fpga_addr;
  logic [31:0]  cmd_nlb;
  logic         cmd_is_admin;  // 0 = serving an IO SQE, 1 = serving an admin SQE (set when descriptor popped)
  // cmd_done declared earlier (near db_state)
  // sqear is popped while the cmd FSM waits in CMD_RECV_ADDR for a buffered SQE-AR.
  assign sqear_pop = (cmd_state == CMD_RECV_ADDR) && !sqear_empty;

  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      cmd_state     <= CMD_IDLE;
      cmd_opcode    <= 0;
      cmd_nvme_addr <= 0;
      cmd_fpga_addr <= 0;
      cmd_nlb       <= 0;
      cmd_done      <= 0;
      cmd_is_admin  <= 0;
      io_serve_cnt  <= 0;
      a_serve_cnt   <= 0;

      oculink_m_axi_rdata_cmd  <= 0;
      oculink_m_axi_rid_cmd    <= 0; 
      oculink_m_axi_rlast_cmd  <= 0;
      oculink_m_axi_rresp_cmd  <= 0;
      oculink_m_axi_rvalid_cmd <= 0;
    end
    else begin
      case(cmd_state)

        CMD_IDLE: begin
          oculink_m_axi_rvalid_cmd  <= 0;
          is_sending_cmd            <= 0;

          if (!iosq_empty) begin
          //if (!iosq_empty && !is_sending_wrdata) begin
            is_sending_cmd  <= 1;
            iosq_pop        <= 1;
            cmd_state       <= CMD_POP_IOSQ;
          end
          else if (!asq_empty) begin
          //else if (!asq_empty && !is_sending_wrdata) begin
            is_sending_cmd  <= 1;
            asq_pop         <= 1;
            cmd_state       <= CMD_POP_ASQ;
          end
        end

        CMD_POP_IOSQ: begin
          iosq_pop <= 0;

          if (iosq_valid) begin
            cmd_opcode    <= iosq_dout[96] ? READ_OPCODE : WRITE_OPCODE;
            cmd_nvme_addr <= iosq_dout[95:64];
            cmd_fpga_addr <= iosq_dout[63:32];
            cmd_nlb       <= iosq_dout[31:0];
            cmd_is_admin  <= 1'b0;
            io_serve_cnt  <= (io_serve_cnt == IOSQ_QDEPTH-1) ? 32'd0 : io_serve_cnt + 1; // advance IO SQ tail
            cmd_state     <= CMD_RECV_ADDR;
          end
        end

        CMD_POP_ASQ: begin
          asq_pop <= 0;

          if (asq_valid) begin
            cmd_opcode    <= asq_dout ? IOCQ_CREATE_OPCODE : IOSQ_CREATE_OPCODE;
            cmd_is_admin  <= 1'b1;
            a_serve_cnt   <= (a_serve_cnt == ASQ_QDEPTH-1) ? 32'd0 : a_serve_cnt + 1; // advance admin SQ tail
            cmd_state     <= CMD_RECV_ADDR;
          end
        end

        CMD_RECV_ADDR: begin
          // Wait for a buffered SQE-AR (the sqear FIFO catches every accepted SQE-class AR so a back-to-back
          // SQE-AR can never be dropped by an unbuffered arvalid). Branch by the descriptor type we popped.
          // (sqear_head carries the AR's is_admin and must equal cmd_is_admin under the no-admin/IO-interleave
          //  usage; checked by a sim assertion below.)
          if (!sqear_empty) begin
            cmd_state <= cmd_is_admin ? CMD_SEND_ACMD1 : CMD_SEND_IOCMD1;
          end
        end

        CMD_SEND_IOCMD1: begin
          if (oculink_m_axi_rready && rtag_sel_cmd) begin   // serve only when our SQE tag is the R head
            oculink_m_axi_rdata_cmd <= { 
                                        32'h0000_0000,  // DW7
                                        cmd_nvme_addr,  // DW6 : DPTR0 : NVMe Address
                                        32'h0000_0000,  // DW5
                                        32'h0000_0000,  // DW4
                                        32'h0000_0000,  // DW3
                                        32'h0000_0000,  // DW2
                                        32'h0000_0001,  // DW1 : Namespace
                                        cmd_opcode      // DW0 : Opcode
                                      };
            oculink_m_axi_rid_cmd    <= 0; 
            oculink_m_axi_rlast_cmd  <= 0;
            oculink_m_axi_rresp_cmd  <= 0;
            oculink_m_axi_rvalid_cmd <= 1;
            cmd_state                <= CMD_SEND_IOCMD2;
          end
        end

        CMD_SEND_IOCMD2: begin
          oculink_m_axi_rvalid_cmd <= 0;

          if (oculink_m_axi_rready && rtag_sel_cmd) begin
            oculink_m_axi_rdata_cmd <= {
                                        32'h0000_0000,  // DW15
                                        32'h0000_0000,  // DW14
                                        32'h0000_0000,  // DW13
                                        cmd_nlb,        // DW12 : NLB
                                        32'h0000_0000,  // DW11 : SLBA [63:32]
                                        cmd_fpga_addr,  // DW10 : SLBA [31:00] (CSR 0x54 'fpga_addr' repurposed as start LBA)
                                        32'h0000_0000,  // DW9
                                        32'h0000_0000   // DW8 : DPTR1 
                                      };                                   
            oculink_m_axi_rid_cmd    <= 0; 
            oculink_m_axi_rlast_cmd  <= 1;
            oculink_m_axi_rresp_cmd  <= 0;
            oculink_m_axi_rvalid_cmd <= 1;
            cmd_state                <= CMD_DONE;
            cmd_done                 <= 1;
          end
        end

        CMD_SEND_ACMD1: begin
          if (oculink_m_axi_rready && rtag_sel_cmd) begin   // serve only when our SQE tag is the R head
            oculink_m_axi_rdata_cmd <= { 
                                        32'h0000_0000,  // DW7
                                        (cmd_opcode == IOCQ_CREATE_OPCODE) ? IOCQ_BAR : IOSQ_BAR,  // DW6
                                        32'h0000_0000,  // DW5
                                        32'h0000_0000,  // DW4
                                        32'h0000_0000,  // DW3
                                        32'h0000_0000,  // DW2
                                        32'h0000_0000,  // DW1
                                        cmd_opcode      // DW0 : Opcode
                                      };
            oculink_m_axi_rid_cmd    <= 0; 
            oculink_m_axi_rlast_cmd  <= 0;
            oculink_m_axi_rresp_cmd  <= 0;
            oculink_m_axi_rvalid_cmd <= 1;
            cmd_state                <= CMD_SEND_ACMD2;
          end
        end

        CMD_SEND_ACMD2: begin
          oculink_m_axi_rvalid_cmd <= 0;

          if (oculink_m_axi_rready && rtag_sel_cmd) begin
            oculink_m_axi_rdata_cmd <= {
                                        32'h0000_0000,  // DW15
                                        32'h0000_0000,  // DW14
                                        32'h0000_0000,  // DW13
                                        32'h0000_0000,  // DW12
                                        (cmd_opcode == IOCQ_CREATE_OPCODE) ? 32'h1 : 32'h0001_0001,  // DW11
                                        32'h003F_0001,  // DW10 : QSIZE=63 (queue depth 64), QID=1
                                        32'h0000_0000,  // DW9
                                        32'h0000_0000   // DW8
                                      };
            oculink_m_axi_rid_cmd    <= 0; 
            oculink_m_axi_rlast_cmd  <= 1;
            oculink_m_axi_rresp_cmd  <= 0;
            oculink_m_axi_rvalid_cmd <= 1;
            cmd_state                <= CMD_DONE;
            cmd_done                 <= 1;
          end
        end

        CMD_DONE: begin
          oculink_m_axi_rlast_cmd   <= 0;
          oculink_m_axi_rvalid_cmd  <= 0;
          is_sending_cmd            <= 0;

          if (db_done) begin
            cmd_done  <= 0;
            cmd_state <= CMD_IDLE;
          end
        end
        
      endcase
    end
  end


  /* Read data */

  localparam RD_IDLE       = 8'd0;
  localparam RD_RECV_DATA  = 8'd1;

  logic [7:0]   rd_state;
  logic [255:0] rd_data;
  logic         rd_done;

  // Read/Write available address : 0xC000 ~
  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      rd_state <= RD_IDLE;
      rd_data  <= 0;
      rd_done  <= 0;
    end
    else begin
      case(rd_state)
        RD_IDLE: begin
          rd_done  <= 0;

          if (oculink_m_axi_awvalid && (oculink_m_axi_awaddr >= IORW_BAR)) begin
            rd_state  <= RD_RECV_DATA;
          end
        end

        RD_RECV_DATA: begin
          if (oculink_m_axi_wvalid) begin
            rd_data <= oculink_m_axi_wdata;
            
            if(oculink_m_axi_wlast == 1) begin
              rd_done <= 1;
              rd_state <= RD_IDLE;
            end
          end
        end

      endcase
    end
  end


  /* Read Response */

  localparam RDRSP_IDLE       = 8'd0;
  localparam RDRSP_SEND_RESP  = 8'd1;

  logic [7:0] rdrsp_state;

  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if(!rstn) begin
      rdrsp_state                 <= RDRSP_IDLE;
      oculink_m_axi_bid_rd     <= 0;
      oculink_m_axi_bresp_rd   <= 0;
      oculink_m_axi_bvalid_rd  <= 0;
    end
    else begin
      case(rdrsp_state) 
        RDRSP_IDLE: begin
          oculink_m_axi_bvalid_rd <= 0;

          if (rd_done) begin
            rdrsp_state <= RDRSP_SEND_RESP;
          end
        end

        RDRSP_SEND_RESP: begin
          if (oculink_m_axi_bready && !wtag_sel_cpl) begin   // send B only when a read-data tag is the B head
            oculink_m_axi_bid_rd     <= 0;
            oculink_m_axi_bresp_rd   <= 0;
            oculink_m_axi_bvalid_rd  <= 1;
            rdrsp_state                 <= RDRSP_IDLE;
          end
        end

      endcase
    end
  end


  /* Write data */

  // The legacy 16-entry write-address length ring (wraddr_fifo IP + wraddr_wrlen[]/recv_cnt/send_cnt) is gone:
  // each write-data read's burst length now rides in its rtag entry (rtag_head_arlen), so the demux paces
  // wrdata directly and outstanding write-data reads are no longer capped at 16.
  logic [7:0]   wr_len;

  localparam WRDATA_IDLE       = 8'd0;
  localparam WRDATA_SEND_DATA  = 8'd1;

  logic [7:0] wrdata_state;

  // m_axi_r : Write Data
  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      wrdata_state <= WRDATA_IDLE;
      wr_len <= 0;
      oculink_m_axi_rdata_wr   <= 0;
      oculink_m_axi_rid_wr     <= 0;
      oculink_m_axi_rlast_wr   <= 0;
      oculink_m_axi_rresp_wr   <= 0;
      oculink_m_axi_rvalid_wr  <= 0;
    end
    else begin
      case(wrdata_state)
        WRDATA_IDLE: begin
          oculink_m_axi_rvalid_wr  <= 0;
          oculink_m_axi_rlast_wr   <= 0;

          // Start a burst only for a data-class head that is NOT being popped this cycle. The rtag pop is
          // registered (1 cycle after rlast), so without the !rtag_pop guard this IDLE would re-trigger on the
          // SAME tag during its own rlast beat and serve a spurious second burst.
          if (!rtag_empty && !rtag_head_is_sqe && !rtag_pop) begin   // data read is the oldest outstanding AR
            wrdata_state <= WRDATA_SEND_DATA;
            wr_len <= rtag_head_arlen;                  // burst length comes from the tag (no 16-entry ring)
          end
        end

        WRDATA_SEND_DATA: begin

          if (oculink_m_axi_rready && !rtag_sel_cmd) begin  // serve only when a write-data tag is the R head
            oculink_m_axi_rdata_wr <= {
                                        wrdata[7],
                                        wrdata[6],
                                        wrdata[5],
                                        wrdata[4],
                                        wrdata[3],
                                        wrdata[2],
                                        wrdata[1],
                                        wrdata[0]  
                                      };
            oculink_m_axi_rid_wr     <= 0;
            oculink_m_axi_rresp_wr   <= 0;
            oculink_m_axi_rvalid_wr  <= 1;
            oculink_m_axi_rlast_wr   <= 0;
            wr_len                      <= wr_len - 1;

            if (wr_len == 0) begin
              oculink_m_axi_rlast_wr <= 1;
              wrdata_state <= WRDATA_IDLE;   // rlast pops the rtag; re-check the new head from IDLE
            end
          end

          else begin
            oculink_m_axi_rvalid_wr  <= 0;
          end
        end

      endcase
    end
  end


  /* Completion */

  localparam CPL_IDLE       = 8'd0;
  localparam CPL_RECV_IOCPL = 8'd1;
  localparam CPL_RECV_ACPL  = 8'd2;
  localparam CPL_RESP       = 8'd3;
  localparam CPL_DONE       = 8'd4;

  logic [7:0]   cpl_state;
  logic [255:0] cpl_data;

  // 9000~9FFF : ACQ address
  // A000~AFFF : IOCQ address
  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if(!rstn) begin
      cpl_state                 <= CPL_IDLE;
      cpl_data                  <= 0;
      cpl_done                  <= 0;
      cpl_count                 <= 0;
      is_receving_cpl           <= 0;
      iocqhdbl                  <= 0;
      acqhdbl                   <= 0;
      cpl_is_io                 <= 0;

      oculink_m_axi_bid_cpl     <= 0;
      oculink_m_axi_bresp_cpl   <= 0;
      oculink_m_axi_bvalid_cpl  <= 0;
    end
    else begin
      case(cpl_state)
        CPL_IDLE: begin
          oculink_m_axi_bvalid_cpl  <= 0;
          is_receving_cpl           <= 0;
          cpl_done                  <= 0;

          if (oculink_m_axi_awvalid && (oculink_m_axi_awaddr >= IOCQ_BAR) && (oculink_m_axi_awaddr < IOSQ_BAR)) begin
            cpl_state <= CPL_RECV_IOCPL;
          end
          else if (oculink_m_axi_awvalid && (oculink_m_axi_awaddr >= ACQ_BAR) && (oculink_m_axi_awaddr < IOCQ_BAR)) begin
            cpl_state <= CPL_RECV_ACPL;
          end
        end

        CPL_RECV_IOCPL: begin
          if (oculink_m_axi_wvalid && (oculink_m_axi_wlast == 1)) begin
            is_receving_cpl <= 1;
            cpl_is_io       <= 1;
            cpl_data        <= oculink_m_axi_wdata;
            cpl_state       <= CPL_RESP;
          end
        end

        CPL_RECV_ACPL: begin
          if (oculink_m_axi_wvalid && (oculink_m_axi_wlast == 1)) begin
            is_receving_cpl <= 1;
            cpl_is_io       <= 0;
            cpl_data        <= oculink_m_axi_wdata;
            cpl_state       <= CPL_RESP;
          end
        end

        CPL_RESP: begin
          if (oculink_m_axi_bready && wtag_sel_cpl) begin   // send B only when our CQE tag is the B head
            oculink_m_axi_bid_cpl     <= 0;
            oculink_m_axi_bresp_cpl   <= 0;
            oculink_m_axi_bvalid_cpl  <= 1;
            cpl_state                 <= CPL_DONE;
          end
        end

        CPL_DONE: begin
          oculink_m_axi_bvalid_cpl  <= 0;
          cpl_done                  <= 1;
          cpl_count                 <= cpl_count + 1;  // per-completion counter (host polls this for multi-outstanding)
          // advance the consumed CQ head so the db FSM rings the CQ head doorbell (frees CQ slots)
          if (cpl_is_io) iocqhdbl <= (iocqhdbl == IOCQ_QDEPTH-1) ? 32'd0 : iocqhdbl + 1;
          else           acqhdbl  <= (acqhdbl  == ACQ_QDEPTH-1)  ? 32'd0 : acqhdbl  + 1;
          cpl_state                 <= CPL_IDLE;       // always re-arm to capture every completion
        end
      endcase
    end
  end




  /* Read-back data + completion status exposed to host CSR (read after cpl_done) */
  assign rddata[0] = rd_data[31:0];
  assign rddata[1] = rd_data[63:32];
  assign rddata[2] = rd_data[95:64];
  assign rddata[3] = rd_data[127:96];
  assign rddata[4] = rd_data[159:128];
  assign rddata[5] = rd_data[191:160];
  assign rddata[6] = rd_data[223:192];
  assign rddata[7] = rd_data[255:224];
  assign cpl_status = cpl_data[127:96];  // CQE DW3 : status[31:17], phase[16], cid[15:0]


  ila_0 ila_0_i(
    .clk(oculink_axi_clk),
    .probe0(asq_valid),
    .probe1(asq_valid),
    .probe2(cpl_done),
    .probe3(iosq_valid),
    .probe4(iosq_din),  // 96
    .probe5(iosq_dout), // 96
    .probe6(iosq_push),
    .probe7(iosq_pop),
    .probe8(iosq_full),
    .probe9(iosq_empty),
    .probe10(iosq_valid),
    .probe11(asq_din),
    .probe12(asq_dout),
    .probe13(asq_push),
    .probe14(asq_pop),
    .probe15(asq_full),
    .probe16(asq_empty),
    .probe17(asq_valid),
    .probe18(db_state), // 8
    .probe19(db_done),
    .probe20(io_serve_cnt), // 32 (IO SQ tail)
    .probe21(a_serve_cnt),  // 32 (admin SQ tail)
    .probe22(cmd_state),  // 8
    .probe23(cmd_opcode), // 32
    .probe24(cmd_nvme_addr),  // 32
    .probe25(cmd_fpga_addr), //32
    .probe26(cmd_nlb), //32
    .probe27(cmd_done), //1
    .probe28(rd_state), // 8
    .probe29(rd_data), // 256
    .probe30(rd_done), 
    .probe31(rdrsp_state), //8
    .probe32({rtag_full, rtag_empty, sqear_full, sqear_empty, wtag_full, wtag_empty, rtag_sel_cmd, wtag_sel_cpl}), //8 demux flags
    .probe33(rtag_head_is_sqe),
    .probe34(wr_len), // 8
    .probe35(rtag_pop),
    .probe36(rtag_head_arlen), // 8
    .probe37(rtag_full),
    .probe38(rtag_empty),
    .probe39(rtag_sel_cmd),
    .probe40({6'd0, wtag_head, wtag_sel_cpl}), //8
    .probe41({sqear_empty, wtag_empty, rtag_empty, wtag_pop}), // 4
    .probe42(wrdata_state), // 8
    .probe43(4'd0), // 4 (retired wrdata_send_cnt)
    .probe44(cpl_state), // 8
    .probe45(cpl_data)  // 256
  );



  // localparam PERF_IDLE = 4'd0;
  // localparam PERF_START = 4'd1;
  // localparam PERF_END = 4'd2;


  // always_ff @(posedge oculink_axi_clk or negedge rstn) begin
  //   if (!rstn) begin
  //     perf_cnt <= 0;
  //     perf_state <= PERF_IDLE;
  //   end
  //   else begin
  //     case(perf_state)
  //       PERF_IDLE: begin
  //         if(cmd_state == CMD_DONE) perf_state <= PERF_START;
  //       end

  //       PERF_START: begin
  //         if ((cpl_state == CPL_RESP) && (oculink_m_axi_bready == 1)) begin
  //           perf_state <= PERF_END;
  //         end
  //         else begin
  //           perf_cnt <= perf_cnt + 64'd1;
  //         end
  //       end

  //       PERF_END: begin

  //       end
  //     endcase
  //   end
  // end



  // /* Debudding ILA cores */

  // ila_rw_new ila_rw_new_i (
  //   .clk(oculink_axi_clk),
  //   .probe0(db_state),
  //   .probe1(iosqtdbl),
  //   .probe2(db_done),
  //   .probe3(cmd_state),
  //   .probe4(cmd_opcode),
  //   .probe5(cmd_nvme_addr),
  //   .probe6(cmd_fpga_addr),
  //   .probe7(cmd_nlb),
  //   .probe8(cmd_done),
  //   .probe9(send_read_cmd),
  //   .probe10(rd_state),
  //   .probe11(rd_data),
  //   .probe12(is_sending_cmd),
  //   .probe13(rdrsp_state),
  //   .probe14(cpl_state),
  //   .probe15(cpl_data),
  //   .probe16(is_receving_cpl),
  //   .probe17(wr_state),
  //   .probe18(is_sending_wrdata),
  //   .probe19(wr_len),
  //   .probe20(wraddr_fifo_rd_en),
  //   .probe21(wraddr_fifo_dout),
  //   .probe22(wraddr_fifo_full),
  //   .probe23(wraddr_fifo_empty),
  //   .probe24(wraddr_fifo_valid)
  // );

endmodule
