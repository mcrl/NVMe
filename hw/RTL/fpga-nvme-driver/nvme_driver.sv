
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
  
  assign oculink_m_axi_rdata = is_sending_cmd ? oculink_m_axi_rdata_cmd : oculink_m_axi_rdata_wr;
  assign oculink_m_axi_rid = is_sending_cmd ? oculink_m_axi_rid_cmd : oculink_m_axi_rid_wr;
  assign oculink_m_axi_rlast = is_sending_cmd ? oculink_m_axi_rlast_cmd : oculink_m_axi_rlast_wr;   
  assign oculink_m_axi_rresp = is_sending_cmd ? oculink_m_axi_rresp_cmd : oculink_m_axi_rresp_wr;
  assign oculink_m_axi_rvalid = is_sending_cmd ? oculink_m_axi_rvalid_cmd : oculink_m_axi_rvalid_wr;   
  assign oculink_m_axi_bid = is_receving_cpl ? oculink_m_axi_bid_cpl : oculink_m_axi_bid_rd;
  assign oculink_m_axi_bresp = is_receving_cpl ? oculink_m_axi_bresp_cpl : oculink_m_axi_bresp_rd;
  assign oculink_m_axi_bvalid = is_receving_cpl ? oculink_m_axi_bvalid_cpl : oculink_m_axi_bvalid_rd;


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
  
  logic [7:0]   db_state;
  logic         db_done;
  logic [31:0]  iosqtdbl;
  logic [31:0]  asqtdbl;

  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      db_state                <= DB_IDLE;
      db_done                 <= 0;
      iosqtdbl                <= 1;
      asqtdbl                 <= 1;

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
          if (!iosq_empty) db_state <= DB_RING_IODBL;
          else if(!asq_empty) db_state <= DB_RING_ADBL;
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
            oculink_s_axi_wdata  <= {
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl,
                                        iosqtdbl
                                      };                    
            oculink_s_axi_wlast  <= 1;
            oculink_s_axi_wstrb  <= 32'hffff_ffff;
            oculink_s_axi_wvalid <= 1;
            iosqtdbl             <= iosqtdbl + 1;
            db_state             <= DB_WAIT_RESP;
          end
        end
        
        DB_SEND_ADATA: begin
          oculink_s_axi_awvalid  <= 0;

          if (oculink_s_axi_wready) begin
            oculink_s_axi_wdata  <= {
                                        asqtdbl,
                                        asqtdbl,
                                        asqtdbl,
                                        asqtdbl,
                                        asqtdbl,
                                        asqtdbl,
                                        asqtdbl,
                                        asqtdbl
                                      };                    
            oculink_s_axi_wlast  <= 1;
            oculink_s_axi_wstrb  <= 32'hffff_ffff;
            oculink_s_axi_wvalid <= 1;
            asqtdbl              <= asqtdbl + 1;
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
  logic         cmd_done;

  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      cmd_state     <= CMD_IDLE;
      cmd_opcode    <= 0;
      cmd_nvme_addr <= 0;
      cmd_fpga_addr <= 0;
      cmd_nlb       <= 0;
      cmd_done      <= 0;

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
            cmd_state     <= CMD_RECV_ADDR;
          end
        end

        CMD_POP_ASQ: begin
          asq_pop <= 0;

          if (asq_valid) begin
            cmd_opcode    <= asq_dout ? IOCQ_CREATE_OPCODE : IOSQ_CREATE_OPCODE;
            cmd_state     <= CMD_RECV_ADDR;
          end
        end

        CMD_RECV_ADDR: begin
          if ( oculink_m_axi_arvalid && 
              (oculink_m_axi_araddr >= IOSQ_BAR) &&
              (oculink_m_axi_araddr < IOSQ_BAR + IOSQ_SIZE)) begin
            
            cmd_state <= CMD_SEND_IOCMD1;
          end

          else if ( oculink_m_axi_arvalid && 
              (oculink_m_axi_araddr >= ASQ_BAR) &&
              (oculink_m_axi_araddr < ASQ_BAR + ASQ_SIZE)) begin
            
            cmd_state <= CMD_SEND_ACMD1;
          end
        end

        CMD_SEND_IOCMD1: begin
          if (oculink_m_axi_rready) begin
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

          if (oculink_m_axi_rready) begin
            oculink_m_axi_rdata_cmd <= {
                                        32'h0000_0000,  // DW15
                                        32'h0000_0000,  // DW14
                                        32'h0000_0000,  // DW13
                                        cmd_nlb,        // DW12 : NLB 
                                        32'h0000_0000,  // DW11 : SLBA [63:32]
                                        32'h0000_0000,  // DW10 : SLBA [31:00]
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
          if (oculink_m_axi_rready) begin
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

          if (oculink_m_axi_rready) begin
            oculink_m_axi_rdata_cmd <= {
                                        32'h0000_0000,  // DW15
                                        32'h0000_0000,  // DW14
                                        32'h0000_0000,  // DW13
                                        32'h0000_0000,  // DW12
                                        (cmd_opcode == IOCQ_CREATE_OPCODE) ? 32'h1 : 32'h0001_0001,  // DW11
                                        32'h0010_0001,  // DW10
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
          if (oculink_m_axi_bready && !is_receving_cpl) begin
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

  localparam WR_IDLE       = 8'd0;
  localparam WR_FIFO_POP   = 8'd1;
  localparam WR_SEND_DATA  = 8'd2;

  localparam WRADDR_IDLE      = 8'd0;
  localparam WRADDR_FIFO_POP  = 8'd1;
  localparam WRADDR_NEXT_WAIT = 8'd2;
  localparam WRADDR_FIFO_POP_NEXT  = 8'd3;


  logic [7:0]   wr_state;
  logic         wr_done;
  logic [7:0]   wr_len;
  logic         wraddr_fifo_rd_en;
  logic [7:0]   wraddr_fifo_dout;
  logic         wraddr_fifo_full;
  logic         wraddr_fifo_empty;
  logic         wraddr_fifo_valid;

  wraddr_fifo wraddr_fifo_i (
    .srst(!rstn),
    .clk(oculink_axi_clk),
    .din(oculink_m_axi_arlen),
    .wr_en(oculink_m_axi_arvalid && (oculink_m_axi_araddr >= IORW_BAR)),
    .dout(wraddr_fifo_dout),
    .rd_en(wraddr_fifo_rd_en),
    .full(wraddr_fifo_full),
    .empty(wraddr_fifo_empty),
    .valid(wraddr_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  logic [7:0] wraddr_state;
  logic [3:0] wraddr_recv_cnt;
  logic [7:0] wraddr_wrlen [0:15];

  // m_axi_ar : Write Address
  // Read/Write available address : 0xC000 ~
  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      wraddr_state <= WRADDR_IDLE;
      wraddr_recv_cnt <= 0;
      wraddr_wrlen[0] <= 0;
      wraddr_wrlen[1] <= 0;
    end
    else begin
      if (oculink_m_axi_arvalid && (oculink_m_axi_araddr >= IORW_BAR)) begin
        wraddr_recv_cnt <= wraddr_recv_cnt + 1;
        wraddr_wrlen[wraddr_recv_cnt] <= oculink_m_axi_arlen;
      end

    end
  end

  localparam WRDATA_IDLE       = 8'd0;
  localparam WRDATA_SEND_DATA  = 8'd1;
  localparam WRDATA_CHECK_NEXT = 8'd2;

  logic [7:0] wrdata_state;
  logic [3:0] wrdata_send_cnt;

  // m_axi_r : Write Data
  always_ff @(posedge oculink_axi_clk or negedge rstn) begin
    if (!rstn) begin
      wrdata_state <= WRDATA_IDLE;
      wrdata_send_cnt <= 0;
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

          if (wraddr_recv_cnt != wrdata_send_cnt) begin
            wrdata_state <= WRDATA_SEND_DATA;
            wr_len <= wraddr_wrlen[wrdata_send_cnt];
          end
        end

        WRDATA_SEND_DATA: begin

          if (oculink_m_axi_rready) begin
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
              wrdata_send_cnt <= wrdata_send_cnt + 1;
              wrdata_state <= WRDATA_CHECK_NEXT;
            end
          end

          else begin
            oculink_m_axi_rvalid_wr  <= 0;
          end
        end

        WRDATA_CHECK_NEXT: begin
          oculink_m_axi_rvalid_wr  <= 0;

          if (wraddr_recv_cnt != wrdata_send_cnt) begin
            wrdata_state <= WRDATA_SEND_DATA;
            wr_len <= wraddr_wrlen[wrdata_send_cnt];
          end
          else begin
            wrdata_state <= WRDATA_IDLE;
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
      is_receving_cpl           <= 0;

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
            cpl_data        <= oculink_m_axi_wdata;
            cpl_state       <= CPL_RESP;
          end
        end

        CPL_RECV_ACPL: begin
          if (oculink_m_axi_wvalid && (oculink_m_axi_wlast == 1)) begin
            is_receving_cpl <= 1;
            cpl_data        <= oculink_m_axi_wdata;
            cpl_state       <= CPL_RESP;
          end
        end

        CPL_RESP: begin
          if (oculink_m_axi_bready) begin
            oculink_m_axi_bid_cpl     <= 0;
            oculink_m_axi_bresp_cpl   <= 0;
            oculink_m_axi_bvalid_cpl  <= 1;
            cpl_state                 <= CPL_DONE;
          end
        end

        CPL_DONE: begin
          oculink_m_axi_bvalid_cpl  <= 0;
          cpl_done                  <= 1;
          if (iosq_valid || asq_valid) cpl_state <= CPL_IDLE;
        end
      endcase
    end
  end




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
    .probe20(iosqtdbl), // 32
    .probe21(asqtdbl),  // 32
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
    .probe32(wr_state), //8
    .probe33(wr_done),
    .probe34(wr_len), // 8
    .probe35(wraddr_fifo_rd_en),
    .probe36(wraddr_fifo_dout), // 8
    .probe37(wraddr_fifo_full),
    .probe38(wraddr_fifo_empty),
    .probe39(wraddr_fifo_valid),
    .probe40(wraddr_state), //8
    .probe41(wraddr_recv_cnt), // 4
    .probe42(wrdata_state), // 8
    .probe43(wrdata_send_cnt), // 4
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
