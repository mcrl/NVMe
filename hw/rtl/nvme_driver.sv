
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
  // host data buffer port (host_bram_clk): wbuf region -> host writes write-payload,
  //                                         rbuf region -> host reads captured read-payload
  input  logic [16:0]   dbuf_addr,      // host byte offset within a 128 KB buffer (word=[16:5], lane=[4:2])
  input  logic [31:0]   dbuf_wdata,
  input  logic          dbuf_we,        // write strobe (host writing the wbuf region)
  output logic [31:0]   dbuf_rdata,     // rbuf read-back (host reading the rbuf region)
  output logic [31:0]   cpl_status,     // last completion CQE DW3 (status/phase/cid)
  output logic [31:0]   cpl_count,      // monotonic completion counter (multi-outstanding)
  output logic [31:0]   r_data_beats,   // count of write-payload R beats served (real data moved, x32 B)
  output logic [31:0]   w_data_beats,   // count of read-data W beats captured (real data moved, x32 B)
  output logic [31:0]   raw_w_beats,    // DIAG: EVERY accepted W beat (any class) -> SSD-sent vs FPGA-dropped
  output logic [31:0]   raw_w_bursts,   // DIAG: count of non-CQE (read-data) W bursts (wlast & ~cqe class)


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

  logic is_sending_cmd;   // kept for ILA only (no longer a mux select)

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
  logic [255:0]  oculink_m_axi_rdata_lg;   // PRP-list generator (declared early; driven in the listgen FSM)
  logic          oculink_m_axi_rvalid_lg;
  logic          oculink_m_axi_rlast_lg;

  // ---------------- m_axi in-order demux tag FIFOs ----------------
  // Root cause of the QD>1 hang: the R/B muxes selected on a PRODUCER-STATE flag (is_sending_cmd /
  // is_receving_cpl), not on "which transaction the SSD is waiting on". Since oculink_m_axi_{ar,aw}ready
  // are tied 1 and rid/bid are single-ID 0, AR-accept order IS the mandatory R-return order and AW-accept
  // order IS the B order. So record the class of each accepted AR/AW in an in-order FWFT tag FIFO and serve
  // the head (= oldest outstanding transaction). is_sending_cmd / is_receving_cpl are kept driven for the
  // ILA probes but no longer select the mux.

  // PRP layout -- data pages are CONTIGUOUS from IORW_BAR (0xC000) so the host fills ONE flat buffer:
  //   PRP1 = 0xC000 (page 1). For 2-page xfers PRP2 = 0xD000 (page 2, direct).
  //   For >2-page xfers PRP2 = PRP_LIST_BASE (a PRP-list page held HIGH, above the 128 KB data window so it
  //   consumes no data-offset slot); its entries are pages 2..N = 0xD000,0xE000,0xF000,... (dense).
  localparam [31:0] PRP_PAGE2     = IORW_BAR + 32'h1000;    // 0xD000  page 2 = first list entry (dense)
  localparam [31:0] PRP_LIST_BASE = IORW_BAR + 32'h40000;   // 0x4C000 PRP-list page, above the data window

  // R-tag: {class[1:0], arlen[7:0]} per accepted AR; head selects the R source; pop on the burst's rlast.
  //   class 0 = write-command payload (wrdata), 1 = SQE serve (cmd), 2 = PRP-list (listgen).
  localparam RTAG_W = 10;
  wire ar_is_sqe   = ((oculink_m_axi_araddr >= IOSQ_BAR) && (oculink_m_axi_araddr < IOSQ_BAR + IOSQ_SIZE)) ||
                     ((oculink_m_axi_araddr >= ASQ_BAR)  && (oculink_m_axi_araddr < ASQ_BAR  + ASQ_SIZE));
  wire ar_is_admin = (oculink_m_axi_araddr >= ASQ_BAR)  && (oculink_m_axi_araddr < ASQ_BAR + ASQ_SIZE);
  wire ar_is_list  = (oculink_m_axi_araddr >= PRP_LIST_BASE) && (oculink_m_axi_araddr < PRP_LIST_BASE + 32'h1000);
  wire [1:0] ar_class = ar_is_sqe ? 2'd1 : ar_is_list ? 2'd2 : 2'd0;
  logic [RTAG_W-1:0] rtag_head, rtag_head2;
  logic [8:0]        rtag_cnt;
  logic              rtag_empty, rtag_full;
  wire               rtag_pop = oculink_m_axi_rvalid & oculink_m_axi_rready & oculink_m_axi_rlast;
  tagfifo #(.WIDTH(RTAG_W), .DEPTH(256)) rtag_i (
    .clk(oculink_axi_clk), .srst(!rstn),
    .push(oculink_m_axi_arvalid), .din({ar_class, oculink_m_axi_arlen}),
    .pop(rtag_pop), .head(rtag_head), .head2(rtag_head2), .cnt(rtag_cnt),
    .empty(rtag_empty), .full(rtag_full)
  );
  wire [1:0]  rtag_head_cls    = rtag_head[9:8];
  wire [7:0]  rtag_head_arlen  = rtag_head[7:0];
  // 2-deep lookahead so the write-data server can chain to the next data burst with no inter-burst bubble
  wire        rtag_next_is_data = (rtag_cnt >= 9'd2) && (rtag_head2[9:8] == 2'd0);
  wire [7:0]  rtag_head2_arlen  = rtag_head2[7:0];
  wire        rtag_head_is_sqe = (rtag_head_cls == 2'd1);             // (kept name for ILA/tb)
  wire        rtag_sel_cmd     = (!rtag_empty) & (rtag_head_cls == 2'd1);  // SQE  -> cmd
  wire        rtag_sel_list    = (!rtag_empty) & (rtag_head_cls == 2'd2);  // list -> listgen
  wire        rtag_sel_data    = (!rtag_empty) & (rtag_head_cls == 2'd0);  // data -> wrdata

  // SQE-AR buffer: records each accepted SQE-class AR so the cmd FSM never misses an unbuffered arvalid.
  logic sqear_head;
  logic sqear_empty, sqear_full, sqear_pop;
  tagfifo #(.WIDTH(1), .DEPTH(16)) sqear_i (
    .clk(oculink_axi_clk), .srst(!rstn),
    .push(oculink_m_axi_arvalid & ar_is_sqe), .din(ar_is_admin),
    .pop(sqear_pop), .head(sqear_head), .empty(sqear_empty), .full(sqear_full)
  );

  // W-channel acceptor (MO-5): in-order, W-STREAM-DRIVEN capture instead of an FSM that only catches awvalid
  // while idle (which dropped back-to-back CQEs at high QD). wtag holds {is_cqe, is_iocq} per accepted AW;
  // three pointers walk it: w_awp (AW push, since awready=1), w_capp (advances per completed W burst ->
  // capture+count, NEVER blocked by B), w_bp (B response, one OKAY per captured burst in AW order).
  localparam WTAG_DEPTH = 256;
  localparam WTAG_AW    = $clog2(WTAG_DEPTH);
  wire aw_is_cqe  = (oculink_m_axi_awaddr >= ACQ_BAR)  && (oculink_m_axi_awaddr < IOSQ_BAR); // ACQ|IOCQ
  wire aw_is_iocq = (oculink_m_axi_awaddr >= IOCQ_BAR) && (oculink_m_axi_awaddr < IOSQ_BAR); // IOCQ (vs ACQ)
  logic [1:0]       wtagmem [0:WTAG_DEPTH-1];
  logic [WTAG_AW:0] w_awp, w_capp, w_bp;
  wire        wcap_avail = (w_capp != w_awp);
  wire        wb_avail   = (w_bp   != w_capp);            // a captured burst awaits its B
  // class of the W burst now completing; same-cycle AW+W(wlast) (empty wtag) reads the live AW class
  wire        w_same     = oculink_m_axi_awvalid && (w_capp == w_awp);
  wire [1:0]  wcap_cls   = wcap_avail ? wtagmem[w_capp[WTAG_AW-1:0]] : {aw_is_cqe, aw_is_iocq};
  wire        wburst_end = oculink_m_axi_wvalid && oculink_m_axi_wlast && (wcap_avail || w_same);

  assign oculink_m_axi_rdata  = rtag_sel_cmd  ? oculink_m_axi_rdata_cmd  :
                                rtag_sel_list ? oculink_m_axi_rdata_lg   : oculink_m_axi_rdata_wr;
  assign oculink_m_axi_rid    = 4'd0;
  assign oculink_m_axi_rlast  = rtag_sel_cmd  ? oculink_m_axi_rlast_cmd  :
                                rtag_sel_list ? oculink_m_axi_rlast_lg   : oculink_m_axi_rlast_wr;
  assign oculink_m_axi_rresp  = 2'd0;
  assign oculink_m_axi_rvalid = rtag_sel_cmd  ? oculink_m_axi_rvalid_cmd :
                                rtag_sel_list ? oculink_m_axi_rvalid_lg  : oculink_m_axi_rvalid_wr;
  assign oculink_m_axi_bid    = 4'd0;
  assign oculink_m_axi_bresp  = 2'd0;        // every B is OKAY/id-0 (CQE and read-data alike)
  assign oculink_m_axi_bvalid = wb_avail;    // one B per captured W burst, in AW-accept order


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
          // MO-9: no cmd_done rendezvous -> the doorbell engine frees itself the cycle after B and is ready to
          // ring the next (coalesced) SQ-tail immediately. The mutual cmd<->db wait that pinned effective QD~1
          // is gone; each FSM now waits only on SSD-driven signals (cmd on sqear/rtag, db on its own s_axi B).
          db_done   <= 0;
          db_state  <= DB_IDLE;
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

  // PRP2 (SQE DW8) for the IO command: 0 for <=1 page, page-2 address for exactly 2 pages (direct),
  // PRP-list address for >2 pages. 1 page = 8 x 512 B blocks -> n_pages = ceil((nlb+1)/8) = (nlb+8)>>3.
  wire [31:0] cmd_npages = (cmd_nlb + 32'd8) >> 3;
  wire [31:0] cmd_prp2   = (cmd_npages <= 32'd1) ? 32'h0 :
                           (cmd_npages == 32'd2) ? PRP_PAGE2 : PRP_LIST_BASE;

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
                                        32'h0000_0000,  // DW9 : PRP2 [63:32]
                                        cmd_prp2        // DW8 : PRP2 [31:00] (0 / page2 / PRP-list per n_pages)
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
          // MO-9: decouple SQE submission from the doorbell-B round-trip. Return to IDLE immediately and pop
          // the next SQE while the prior SQ-tail doorbell (and its B) are still in flight -> multiple commands
          // in flight (effective QD>1). io_serve_cnt is the free-running tail; the db FSM coalesces its ring to
          // the latest value (DB_IDLE @ :324, io_sq_rung<=io_serve_cnt @ :362), which is valid NVMe. The R-demux
          // (rtag head) still orders SQE serving, so single-ID in-order R is preserved.
          cmd_done                  <= 0;   // 1-cycle pulse only (kept for ILA); db no longer rendezvous on it
          cmd_state                 <= CMD_IDLE;
        end
        
      endcase
    end
  end


  /* Read-command payload AND completions are captured by the unified W-channel acceptor (below,
     under "Completion"). The old rd / rdrsp / cpl FSMs are replaced by it. */
  logic [255:0] rd_data;

  /* ---- REAL host data path (replaces the 32 B wrdata replay) --------------------------------------------
     wbuf : host writes the write-payload (host_bram_clk), the SSD reads it during a write command.
     rbuf : the SSD writes the read-payload (oculink_axi_clk), the host reads it after a read completes.
     256 b x 128 = 4 KB each (one NVMe page). Each is single-writer/one-clock + combinational cross-domain
     read, so it is CDC-safe under the host's write-then-trigger-then-poll discipline (same as wrdata[]).
     The per-burst page offset (256-b word index) rides in a small FIFO captured at AR/AW accept.          */
  localparam int DBUF_AW  = 12;                 // 4096 x 256 b = 128 KB per buffer
  localparam int RBUF_LAT = 1;                  // rbuf host read latency (matches axi_bram_ctrl)
  localparam int WBUF_LAT = 1;                  // wbuf SSD-side read latency

  // host write into wbuf: one 32-b lane per access via byte write-enables (no read-modify-write)
  wire [DBUF_AW-1:0] dbuf_word = dbuf_addr[16:5];
  wire [2:0]         dbuf_lane = dbuf_addr[4:2];
  wire [31:0]        wbuf_wea  = dbuf_we ? (32'hF << {dbuf_lane,2'd0}) : 32'd0;
  wire [DBUF_AW-1:0] wbuf_rdaddr;                // driven by the latency-tolerant reader (below)
  wire               wbuf_rden;
  logic [255:0]      wbuf_rdata;
  dpram_be #(.DW(256), .AW(DBUF_AW), .RDLAT(WBUF_LAT), .PRIM("block")) u_wbuf (
    .clka (host_bram_clk),  .ena (1'b1), .wea (wbuf_wea), .addra (dbuf_word), .dina ({8{dbuf_wdata}}),
    .clkb (oculink_axi_clk),.enb (wbuf_rden), .addrb (wbuf_rdaddr), .doutb (wbuf_rdata)
  );

  // rbuf: SSD writes whole 256-b beats (full-word we), host reads a 32-b lane (latency RBUF_LAT)
  wire [DBUF_AW-1:0] rbuf_wraddr;                // driven by the read-payload counter (below)
  wire               rbuf_we;
  logic [255:0]      rbuf_rdata256;
  dpram_be #(.DW(256), .AW(DBUF_AW), .RDLAT(RBUF_LAT), .PRIM("block")) u_rbuf (
    .clka (oculink_axi_clk),.ena (1'b1), .wea ({32{rbuf_we}}), .addra (rbuf_wraddr), .dina (oculink_m_axi_wdata),
    .clkb (host_bram_clk),  .enb (1'b1), .addrb (dbuf_word), .doutb (rbuf_rdata256)
  );
  logic [2:0] dbuf_lane_q;                       // lane aligned to rbuf doutb (RBUF_LAT=1)
  always_ff @(posedge host_bram_clk) dbuf_lane_q <= dbuf_lane;
  assign dbuf_rdata = rbuf_rdata256[{dbuf_lane_q,5'd0} +: 32];

  // per-data-burst word offsets (addr-IORW_BAR)>>5, captured in order at AR/AW accept (oculink domain)
  wire [11:0]  ar_off = (oculink_m_axi_araddr - IORW_BAR) >> 5;   // write-payload read offset
  wire [11:0]  aw_off = (oculink_m_axi_awaddr - IORW_BAR) >> 5;   // read-payload  write offset
  logic [11:0] araddr_head, awaddr_head;
  logic        araddr_empty, awaddr_empty;
  wire         araddr_pop;     // popped when a write-payload (data) burst's rlast pops the rtag
  wire         awaddr_pop;     // popped when a read-payload burst's wlast completes
  logic [11:0] rbuf_off;       // rbuf write offset within the current read-payload burst
  logic        rd_run;         // inside a read-payload burst (so the first beat reloads the offset)
  assign araddr_pop = rtag_pop & rtag_sel_data;
  assign awaddr_pop = oculink_m_axi_wvalid & oculink_m_axi_wready & oculink_m_axi_wlast & (wcap_avail | w_same) & ~wcap_cls[1];
  tagfifo #(.WIDTH(12), .DEPTH(256)) araddr_i (
    .clk(oculink_axi_clk), .srst(!rstn),
    .push(oculink_m_axi_arvalid & (ar_class==2'd0)), .din(ar_off),
    .pop(araddr_pop), .head(araddr_head), .head2(), .cnt(), .empty(araddr_empty), .full()
  );
  tagfifo #(.WIDTH(12), .DEPTH(256)) awaddr_i (
    .clk(oculink_axi_clk), .srst(!rstn),
    .push(oculink_m_axi_awvalid & ~aw_is_cqe), .din(aw_off),
    .pop(awaddr_pop), .head(awaddr_head), .head2(), .cnt(), .empty(awaddr_empty), .full()
  );
  // read-payload write into rbuf (driven from the counter block's rd_run/rbuf_off bookkeeping)
  wire rdpl_beat     = oculink_m_axi_wvalid & oculink_m_axi_wready & (wcap_avail | w_same) & ~wcap_cls[1];
  assign rbuf_we     = rdpl_beat;
  assign rbuf_wraddr = rd_run ? rbuf_off : awaddr_head;

  // PRP-list start beat-offset, captured at each list AR so the list generator serves the CORRECT entries
  // regardless of how the SSD chunks its list reads (a per-burst counter re-served entry 0 each chunk -> only
  // the first ~chunk of pages got real addresses; the rest aliased/zeroed). offset = (araddr-LIST_BASE)>>5.
  wire [7:0] lg_off = (oculink_m_axi_araddr - PRP_LIST_BASE) >> 5;
  wire [7:0] lg_start;
  wire       lgoff_pop = rtag_pop & rtag_sel_list;
  tagfifo #(.WIDTH(8), .DEPTH(16)) lgoff_i (
    .clk(oculink_axi_clk), .srst(!rstn),
    .push(oculink_m_axi_arvalid & (ar_class==2'd2)), .din(lg_off),
    .pop(lgoff_pop), .head(lg_start), .head2(), .cnt(), .empty(), .full()
  );


  /* Write data -- latency-tolerant wbuf reader.
     wbuf is block RAM (read latency WBUF_LAT), so we PREFETCH instead of a 0-latency combinational read:
     for the head data burst (start word = araddr_head, length = rtag_head_arlen+1) we issue sequential wbuf
     reads, throttled by credit so every issued read has a reserved slot in a small output FIFO. Reads land
     WBUF_LAT cycles later and push into the FIFO; the AXI R channel drains it. One burst at a time in head
     order -- the SSD paces these MRds, so the inter-burst refill bubble costs no HW bandwidth. This is the
     same shape the DRAM stage needs (swap the wbuf read for an AXI read master). */
  localparam int OFIFO_AW = 3;                  // output FIFO depth = 8
  localparam int OFIFO_N  = (1<<OFIFO_AW);

  logic [11:0] req_addr;        // next wbuf word to read
  logic [7:0]  req_rem;         // beats still to issue after the current one
  logic        req_active;      // issuing the head burst
  logic        req_last;        // the read being issued is the burst's last beat
  logic        head_done;       // head burst fully issued (await its drain before the next)

  logic [255:0]      ofifo_data [0:OFIFO_N-1];
  logic              ofifo_last [0:OFIFO_N-1];
  logic [OFIFO_AW:0] ofifo_wp, ofifo_rp;
  wire               ofifo_empty = (ofifo_wp == ofifo_rp);
  logic [OFIFO_AW:0] outstanding;               // issued reads not yet drained (credit)

  wire req_start = rtag_sel_data & ~head_done & ~req_active;
  wire can_issue = req_active & (outstanding < OFIFO_N[OFIFO_AW:0]);
  assign wbuf_rden   = can_issue;
  assign wbuf_rdaddr = req_addr;

  logic pvalid_d, plast_d;      // 1-cycle pipeline (WBUF_LAT=1): issue -> wbuf doutb valid
  wire  ofifo_push = pvalid_d;
  wire  ofifo_pop  = oculink_m_axi_rvalid_wr & oculink_m_axi_rready & rtag_sel_data;

  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      req_addr<=0; req_rem<=0; req_active<=0; req_last<=0; head_done<=0;
      ofifo_wp<=0; ofifo_rp<=0; outstanding<=0; pvalid_d<=0; plast_d<=0;
    end else begin
      if (req_start) begin
        req_addr   <= araddr_head;
        req_rem    <= rtag_head_arlen;
        req_active <= 1'b1;
        req_last   <= (rtag_head_arlen == 8'd0);
      end
      if (can_issue) begin
        req_addr <= req_addr + 12'd1;
        if (req_rem == 8'd0) begin req_active <= 1'b0; head_done <= 1'b1; end
        else begin req_rem <= req_rem - 8'd1; req_last <= (req_rem == 8'd1); end
      end
      if (araddr_pop) head_done <= 1'b0;          // burst drained -> next head may start

      pvalid_d <= can_issue;                       // wbuf doutb valid 1 cycle after a read is issued
      plast_d  <= can_issue & req_last;
      if (ofifo_push) begin
        ofifo_data[ofifo_wp[OFIFO_AW-1:0]] <= wbuf_rdata;
        ofifo_last[ofifo_wp[OFIFO_AW-1:0]] <= plast_d;
        ofifo_wp <= ofifo_wp + 1'b1;
      end
      if (ofifo_pop) ofifo_rp <= ofifo_rp + 1'b1;
      outstanding <= outstanding + (can_issue ? 1'b1 : 1'b0) - (ofifo_pop ? 1'b1 : 1'b0);
    end
  end

  assign oculink_m_axi_rdata_wr  = ofifo_data[ofifo_rp[OFIFO_AW-1:0]];
  assign oculink_m_axi_rid_wr    = 4'd0;
  assign oculink_m_axi_rresp_wr  = 2'd0;
  assign oculink_m_axi_rlast_wr  = ofifo_last[ofifo_rp[OFIFO_AW-1:0]];
  assign oculink_m_axi_rvalid_wr = ~ofifo_empty;


  /* PRP-list generator: serves data-page addresses (pages 2..N) when the SSD reads PRP2 of a >2-page
     transfer (class LIST). entry(k)=PRP_PAGE2 + k*4096, four 64-bit little-endian entries per 256-bit beat.
     (rdata_lg/rvalid_lg/rlast_lg are declared up with the other R-source signals.) */
  logic [7:0]   lg_len, lg_beat;
  localparam LG_IDLE = 8'd0, LG_SEND = 8'd1;
  logic [7:0]   lg_state;
  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      lg_state <= LG_IDLE; lg_len <= 0; lg_beat <= 0;
      oculink_m_axi_rdata_lg <= 0; oculink_m_axi_rvalid_lg <= 0; oculink_m_axi_rlast_lg <= 0;
    end
    else begin
      case (lg_state)
        LG_IDLE: begin
          oculink_m_axi_rvalid_lg <= 0;
          oculink_m_axi_rlast_lg  <= 0;
          if (rtag_sel_list && !rtag_pop) begin   // a PRP-list read is the oldest outstanding AR
            lg_len  <= rtag_head_arlen;
            lg_beat <= lg_start;                   // start at THIS list read's beat offset (not 0)
            lg_state <= LG_SEND;
          end
        end
        LG_SEND: begin
          if (oculink_m_axi_rready && rtag_sel_list) begin
            oculink_m_axi_rdata_lg <= {
              {32'h0, (PRP_PAGE2 + (((({24'h0,lg_beat})<<2) + 32'd3)<<12))},
              {32'h0, (PRP_PAGE2 + (((({24'h0,lg_beat})<<2) + 32'd2)<<12))},
              {32'h0, (PRP_PAGE2 + (((({24'h0,lg_beat})<<2) + 32'd1)<<12))},
              {32'h0, (PRP_PAGE2 + (((({24'h0,lg_beat})<<2) + 32'd0)<<12))}
            };
            oculink_m_axi_rvalid_lg <= 1;
            oculink_m_axi_rlast_lg  <= 0;
            lg_beat <= lg_beat + 1;
            lg_len  <= lg_len - 1;
            if (lg_len == 0) begin
              oculink_m_axi_rlast_lg <= 1;
              lg_state <= LG_IDLE;          // rlast pops the rtag; re-check the new head from IDLE
            end
          end
          else begin
            oculink_m_axi_rvalid_lg <= 0;
          end
        end
      endcase
    end
  end


  /* Completion */

  /* ---- Unified W-channel acceptor (MO-5) ----
     Replaces the old rd / rdrsp / cpl FSMs. The completion count is driven by the W STREAM (one count
     per CQE wlast, using the tag class at w_capp), not by an FSM that only catches awvalid while idle —
     so back-to-back CQEs at high QD are never dropped. Read-command payload lands in rd_data on its
     burst's wlast. B (w_bp) is one OKAY per captured burst, in AW-accept order. */
  logic [255:0] cpl_data;
  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      w_awp     <= 0;  w_capp <= 0;  w_bp <= 0;
      cpl_data  <= 0;  rd_data <= 0;
      cpl_count <= 0;  cpl_done <= 0;  cpl_is_io <= 0;
      iocqhdbl  <= 0;  acqhdbl  <= 0;
    end
    else begin
      cpl_done <= 1'b0;
      // 1) record every accepted AW (awready tied 1) -> its class {is_cqe, is_iocq}
      if (oculink_m_axi_awvalid) begin
        wtagmem[w_awp[WTAG_AW-1:0]] <= {aw_is_cqe, aw_is_iocq};
        w_awp <= w_awp + 1'b1;
      end
      // 2) capture+count each completing W burst (on wlast), routed by the capture-head class
      if (wburst_end) begin
        if (wcap_cls[1]) begin                 // CQE -> count + advance the consumed CQ head
          cpl_data  <= oculink_m_axi_wdata;
          cpl_count <= cpl_count + 1;
          cpl_done  <= 1'b1;
          cpl_is_io <= wcap_cls[0];
          if (wcap_cls[0]) iocqhdbl <= (iocqhdbl == IOCQ_QDEPTH-1) ? 32'd0 : iocqhdbl + 1;
          else             acqhdbl  <= (acqhdbl  == ACQ_QDEPTH-1)  ? 32'd0 : acqhdbl  + 1;
        end
        else begin                             // read-command payload (capture last beat)
          rd_data <= oculink_m_axi_wdata;
        end
        w_capp <= w_capp + 1'b1;
      end
      // 3) one B per captured burst, in AW-accept order
      if (wb_avail && oculink_m_axi_bready) w_bp <= w_bp + 1'b1;
    end
  end

  // ---- real data-beat counters (each beat = 32 B) for honest bandwidth measurement ----
  // r_data_beats: write-command payload the SSD reads from us (R, class DATA).
  // w_data_beats: read-command payload the SSD writes to us (W, non-CQE burst).
  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      r_data_beats <= 0;
      w_data_beats <= 0;
      raw_w_beats  <= 0;
      raw_w_bursts <= 0;
      rbuf_off     <= 0;
      rd_run       <= 0;
    end else begin
      if (oculink_m_axi_rvalid & oculink_m_axi_rready & rtag_sel_data)
        r_data_beats <= r_data_beats + 1'b1;
      // read-payload beat: count it; the rbuf write itself is driven combinationally (rbuf_we/rbuf_wraddr)
      // off this same bookkeeping (rd_run/rbuf_off) -- here we only advance the burst's page offset.
      if (rdpl_beat) begin
        w_data_beats <= w_data_beats + 1'b1;
        if (!rd_run) begin rbuf_off <= awaddr_head + 12'd1; rd_run <= 1'b1; end
        else         begin rbuf_off <= rbuf_off  + 12'd1;               end
        if (oculink_m_axi_wlast) rd_run <= 1'b0;   // burst end -> next read-payload beat reloads the offset
      end
      // DIAG: raw_w_beats counts EVERY accepted W beat regardless of class/capture-state -> if at QD>1 this
      // equals the full SSD-sent count while w_data_beats is half, the FPGA is dropping/mis-counting; if raw is
      // itself half, the SSD genuinely sent half the read payload.
      if (oculink_m_axi_wvalid & oculink_m_axi_wready)
        raw_w_beats <= raw_w_beats + 1'b1;
      if (oculink_m_axi_wvalid & oculink_m_axi_wready & oculink_m_axi_wlast & (wcap_avail | w_same) & ~wcap_cls[1])
        raw_w_bursts <= raw_w_bursts + 1'b1;
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
    .probe28({w_awp[3:0], w_capp[3:0]}), // 8 (W-acceptor AW/capture ptrs)
    .probe29(rd_data), // 256
    .probe30(wburst_end),
    .probe31({w_bp[3:0], 2'b0, wb_avail, wcap_avail}), //8
    .probe32({rtag_full, rtag_empty, sqear_full, sqear_empty, wcap_avail, wb_avail, rtag_sel_cmd, wburst_end}), //8 demux flags
    .probe33(rtag_head_is_sqe),
    .probe34(wr_len), // 8
    .probe35(rtag_pop),
    .probe36(rtag_head_arlen), // 8
    .probe37(rtag_full),
    .probe38(rtag_empty),
    .probe39(rtag_sel_cmd),
    .probe40({6'd0, wcap_cls}), //8 (current W-burst class {is_cqe,is_iocq})
    .probe41({sqear_empty, wcap_avail, rtag_empty, wb_avail}), // 4
    .probe42(wrdata_state), // 8
    .probe43(4'd0), // 4 (retired)
    .probe44({7'd0, cpl_is_io}), // 8
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
