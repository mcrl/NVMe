
`timescale 1ns/1ns

// NVMe PCIe IOQ

module nvme_pcie_ioq 
  #(
  parameter [4:0]    PL_LINK_CAP_MAX_LINK_WIDTH     = 4,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  parameter          PL_LINK_CAP_MAX_LINK_SPEED     = 4,  // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter          AXISTEN_IF_MC_RX_STRADDLE      = 1,
  parameter          REQUESTER_ID = 16'h0000,   // bus[7:0],dev[4:0],func[2:0] 
  parameter          COMPLETER_ID = 16'h0100,
  parameter          CSR_DATA_WIDTH = 256,
  parameter          isq_entry_width = 256,
  parameter          icq_entry_width = 256
  )
  (
    //-------------------------------------------------------
    // User Interface (125MHz, from PCIe IP)
    //-------------------------------------------------------

    input             user_clk,
    input             user_reset,
    input             user_lnk_up,
    
    //-------------------------------------------------------
    // CSR Interface (Requests, Completions)
    //-------------------------------------------------------
    input       [CSR_DATA_WIDTH-1:0] csr_ioq_data,
    input                            csr_ioq_valid,
    output reg  [CSR_DATA_WIDTH-1:0] ioq_csr_data,
    output reg                       ioq_csr_valid,

    //-------------------------------------------------------
    // Control Interface (Requests)
    //-------------------------------------------------------

    output reg                ioq_rq_valid,
    output reg         [3:0]  ioq_rq_reqType,  
    output reg        [63:0]  ioq_rq_addr,      // Addr + Addr Type
    output reg       [127:0]  ioq_rq_data,
    output reg         [7:0]  ioq_rq_byten,     // [3:0] first_be, [7:4] last_be
    output reg        [10:0]  ioq_rq_dword,
    output reg         [5:0]  ioq_rq_tag,   
    input                     rq_ioq_ack,
    output                    isq_wfull,

    //-------------------------------------------------------
    // Control Interface (Completions)
    //-------------------------------------------------------

    input          rc_ioq_valid,
    input [128:0]  rc_ioq_data,
    input  [7:0]   rc_ioq_be,
    input  [7:0]   rc_ioq_tag,
    input          rc_ioq_poison,
    input  [3:0]   rc_ioq_errcode,
    input  [2:0]   rc_ioq_status,
    output reg     ioq_rc_ack ,
    output         icq_wfull
);

  //-------------------------------------------------------
  //  Write Requests from CSR to ISQ
  //-------------------------------------------------------
  // When command valid is set, transfer command/address/data to isq


  // FSM
  reg [3:0] isq_wstate_q, isq_wstate_d;

  localparam WSTATE_IDLE = 4'h0;
  localparam WSTATE_WRITE = 4'h1;

  always@(posedge user_clk or posedge user_reset) begin
    if( user_reset ) begin
      isq_wstate_q <= WSTATE_IDLE;
    end
    else begin
      isq_wstate_q <= isq_wstate_d;
    end
  end
  
  always@(*) begin
    isq_wstate_d = isq_wstate_q;

    case(isq_wstate_q)
      WSTATE_IDLE: begin
        if(!isq_wfull && user_lnk_up && !user_reset && csr_ioq_valid) begin
          isq_wstate_d = WSTATE_WRITE;
        end
      end

      WSTATE_WRITE: begin
        if(~isq_wfull) begin
          isq_wstate_d = WSTATE_IDLE;
        end
      end

    endcase
  end


  //-------------------------------------------------------    
  // ISQ Entry size : 256-bit
  // ISQ Entry Format :
  //   3:0    = Request Type (4-bit)
  //  67:4    = Request Address (64-bit)
  // 195:68   = Request Data (128-bit)
  // 203:196  = Request Byte Enable (8-bit)
  // 214:204  = Request Dword Count (11-bit)
  // 220:215  = Request Tag (6-bit)
  // 255:221  = Not Used
  //-------------------------------------------------------    


  reg [3:0]   isq_wrtype_q, isq_wrtype_d;
  reg [63:0]  isq_wraddr_q, isq_wraddr_d;
  reg [127:0] isq_wrdata_q, isq_wrdata_d;
  reg [7:0]   isq_wrbyten_q, isq_wrbyten_d;
  reg [10:0]  isq_wrdword_q, isq_wrdword_d;
  reg [5:0]   isq_wrtag_q, isq_wrtag_d;
  reg         isq_write_q, isq_write_d;

  always @(posedge user_clk or posedge user_reset) begin
      if( user_reset ) begin
          isq_wrtype_q  <= 4'h0;
          isq_wraddr_q  <= 64'h0;
          isq_wrdata_q  <= 256'h0;
          isq_wrbyten_q <= 8'h0;
          isq_wrdword_q <= 11'h0;
          isq_wrtag_q   <= 6'h0;
          isq_write_q   <= 1'b0;
      end 
      else begin
          isq_wrtype_q  <= isq_wrtype_d;
          isq_wraddr_q  <= isq_wraddr_d;
          isq_wrdata_q  <= isq_wrdata_d;
          isq_wrbyten_q <= isq_wrbyten_d;  
          isq_wrdword_q <= isq_wrdword_d;
          isq_wrtag_q   <= isq_wrtag_d;
          isq_write_q   <= isq_write_d;
      end
  end


  reg isq_write;
  reg [isq_entry_width-1:0] isq_wrdata;


  always @(*) begin
    isq_wrtype_d  = isq_wrtype_q;
    isq_wrtag_d   = isq_wrtag_q;
    isq_wraddr_d  = isq_wraddr_q;
    isq_wrdata_d  = isq_wrdata_q;
    isq_wrbyten_d = isq_wrbyten_q;
    isq_wrdword_d = isq_wrdword_q;
    isq_write_d   = isq_write_q;

    case(isq_wstate_q)
      WSTATE_IDLE: begin
        isq_write = 1'b0;
        if(!isq_wfull && user_lnk_up && !user_reset && csr_ioq_valid) begin
          isq_wrtype_d  = csr_ioq_data[3:0];
          isq_wraddr_d  = csr_ioq_data[67:4];
          isq_wrdata_d  = csr_ioq_data[195:68];
          isq_wrbyten_d = csr_ioq_data[203:196];
          isq_wrdword_d = csr_ioq_data[214:204];
          isq_wrtag_d   = csr_ioq_data[220:215];
          isq_write_d   = 1'b1;
        end
      end

      WSTATE_WRITE: begin
        isq_wrdata[3:0]     = isq_wrtype_q;   // Request Type
        isq_wrdata[67:4]    = isq_wraddr_q;   // Request Address
        isq_wrdata[195:68]  = isq_wrdata_q;   // Request Data
        isq_wrdata[203:196] = isq_wrbyten_q;  // Request Byte Enable
        isq_wrdata[214:204] = isq_wrdword_q;  // Request Dword Count
        isq_wrdata[220:215] = isq_wrtag_q;    // Request Tag
        isq_wrdata[255:221] = 35'h0;

        if(~isq_wfull) begin
          isq_write = isq_write_q;
        end
      end
    endcase

  end


  //-------------------------------------------------------
  //  I/O Submission Queue
  //-------------------------------------------------------

  reg                         isq_rack;
  wire [isq_entry_width-1:0]  isq_rdata;
  wire                        isq_rval;
  wire                        isq_rerr;

  nvme_async_fifo #( 
      .width(isq_entry_width),
      .awidth(10)  // 1024 entries (need at least 5)
  ) isq (
      // write (CSR -> ISQ)
      .wclk                           (user_clk),
      .wreset                         (user_reset),
      .write                          (isq_write),
      .wdata                          (isq_wrdata),
      .wfull                          (isq_wfull),
      .wafull                         (),

      // read (ISQ -> NVMe PCIe RQ)
      .rclk                           (user_clk),
      .rreset                         (user_reset),
      .rack                           (isq_rack),
      .rdata                          (isq_rdata),
      .rval                           (isq_rval),
      .rerr                           (isq_rerr)              
  );


  //-------------------------------------------------------
  //  Read Requests from ISQ to PCIe RQ
  //-------------------------------------------------------
  // When command valid is set, transfer command/address/data to pcie rq
  
  reg        isq_rvalid_q, isq_rvalid_d;
  reg  [3:0] isq_rtype_q, isq_rtype_d;
  reg  [5:0] isq_rtag_q, isq_rtag_d;
  reg [63:0] isq_raddr_q, isq_raddr_d;
  reg [63:0] isq_rdata_q, isq_rdata_d;
  reg  [7:0] isq_rbe_q, isq_rbe_d; 
  reg [10:0] isq_rdword_q, isq_rdword_d;

        
  reg [3:0] isq_rstate_q, isq_rstate_d;
  localparam RSTATE_IDLE = 4'h1;

  always @(posedge user_clk or posedge user_reset) begin
      if( user_reset ) begin
          isq_rstate_q <= RSTATE_IDLE;   
          isq_rvalid_q <= 1'b0;
          isq_rtype_q  = 4'h0;
          isq_rtag_q   <= 4'h0;
          isq_raddr_q  <= 64'h0;
          isq_rdata_q  <= 64'h0;
          isq_rbe_q    <= 8'h0;
          isq_rdword_q <= 11'h0;
      end 
      else begin
          isq_rstate_q <= isq_rstate_d;           
          isq_rvalid_q <= isq_rvalid_d;
          isq_rtype_q  <= isq_rtype_d;
          isq_rtag_q   <= isq_rtag_d;
          isq_raddr_q  <= isq_raddr_d;
          isq_rdata_q  <= isq_rdata_d;
          isq_rbe_q    <= isq_rbe_d;  
          isq_rdword_q <= isq_rdword_d;
      end
  end


  always @(*) begin
    if( user_reset ) begin
      isq_rvalid_d = 1'b0;
      isq_rstate_d = RSTATE_IDLE;
    end
    isq_rstate_d = isq_rstate_q;
    isq_rvalid_d = isq_rvalid_q;
    isq_rtype_d  = isq_rtype_q;
    isq_rtag_d   = isq_rtag_q;
    isq_raddr_d  = isq_raddr_q;
    isq_rdata_d  = isq_rdata_q;
    isq_rbe_d    = isq_rbe_q;
    isq_rdword_d = isq_rdword_q;

    isq_rack = 1'b0;
    isq_rvalid_d = 1'b0;

    case (isq_rstate_q)
      RSTATE_IDLE: begin
        if( isq_rval && ~isq_rvalid_q ) begin
          isq_rack      = 1'b1;
          isq_rvalid_d   = 1'b1;

          isq_rstate_d   = RSTATE_IDLE;
          isq_rtype_d    = isq_rdata[3:0];
          isq_raddr_d    = isq_rdata[67:4];
          isq_rdata_d    = isq_rdata[195:68];
          isq_rbe_d      = isq_rdata[203:196];
          isq_rdword_d   = isq_rdata[214:204];
          isq_rtag_d     = isq_rdata[220:215];
        end
      end
    endcase // case (isq_rstate_q)
    
    ioq_rq_valid    = isq_rvalid_q;
    ioq_rq_reqType  = isq_rtype_q;
    ioq_rq_tag      = isq_rtag_q;
    ioq_rq_addr     = isq_raddr_q;
    ioq_rq_data     = isq_rdata_q;
    ioq_rq_byten    = isq_rbe_q;
    ioq_rq_dword    = isq_rdword_q;  
  end





  //-------------------------------------------------------
  //  Write Completions from PCIE RC to ICQ
  //-------------------------------------------------------


  // FSM
  reg [3:0] icq_wstate_q, icq_wstate_d;

  //localparam WSTATE_IDLE = 4'h0;
  //localparam WSTATE_WRITE = 4'h1;

  always@(posedge user_clk or posedge user_reset) begin
    if( user_reset ) begin
      icq_wstate_q <= WSTATE_IDLE;
    end
    else begin
      icq_wstate_q <= icq_wstate_d;
    end
  end
  
  always@(*) begin
    icq_wstate_d = icq_wstate_q;

    case(icq_wstate_q)
      WSTATE_IDLE: begin
        if(!icq_wfull && user_lnk_up && !user_reset && rc_ioq_valid) begin
          icq_wstate_d = WSTATE_WRITE;
        end
      end

      WSTATE_WRITE: begin
        if(~icq_wfull) begin
          icq_wstate_d = WSTATE_IDLE;
        end
      end

    endcase
  end


  //-------------------------------------------------------    
  // ICQ Entry size : 256-bit
  // ICQ Entry Format :
  // 127:0    = Completion Data (128-bit)
  // 135:128  = Completion Byte Enable (8-bit)
  // 143:136  = Completion Tag (8-bit)
  // 144      = Completion Poison
  // 148:145  = Completion Error code (4-bit)
  // 151:149  = Completion Status (3-bit)
  // 254:152  = Not Used
  //-------------------------------------------------------    

  reg [127:0] icq_wrdata_q, icq_wrdata_d;
  reg [7:0]   icq_wrbyten_q, icq_wrbyten_d;
  reg [7:0]   icq_wrtag_q, icq_wrtag_d;
  reg         icq_wrpoison_q, icq_wrpoison_d;
  reg [3:0]   icq_wrerrcode_q, icq_wrerrcode_d;
  reg [2:0]   icq_wrstatus_q, icq_wrstatus_d;
  reg         icq_write_q, icq_write_d;

  always @(posedge user_clk or posedge user_reset) begin
    if( user_reset ) begin
      icq_wrdata_q    <= 256'h0;
      icq_wrbyten_q   <= 8'h0;
      icq_wrtag_q     <= 6'h0;
      icq_wrpoison_q  <= 1'b0;
      icq_wrerrcode_q <= 4'h0;
      icq_wrstatus_q  <= 3'h0;
      icq_write_q     <= 1'b0;
    end 
    else begin
      icq_wrdata_q    <= icq_wrdata_d;
      icq_wrbyten_q   <= icq_wrbyten_d;
      icq_wrtag_q     <= icq_wrtag_d;
      icq_wrpoison_q  <= icq_wrpoison_d;
      icq_wrerrcode_q <= icq_wrerrcode_d;
      icq_wrstatus_q  <= icq_wrstatus_d;
      icq_write_q     <= icq_write_d;
    end
  end


  reg icq_write;
  reg [icq_entry_width-1:0] icq_wrdata;


  always @(*) begin
    icq_wrdata_d    = icq_wrdata_q;
    icq_wrbyten_d   = icq_wrbyten_q;
    icq_wrtag_d     = icq_wrtag_q;
    icq_wrpoison_d  = icq_wrpoison_q;
    icq_wrerrcode_d = icq_wrerrcode_q;
    icq_wrstatus_d  = icq_wrstatus_q;
    icq_write_d     = icq_write_q;

    case(icq_wstate_q)
      WSTATE_IDLE: begin
        icq_write_d = 1'b0;
        icq_write   = 1'b0;

        if(!icq_wfull && user_lnk_up && !user_reset && rc_ioq_valid) begin
          icq_wrdata_d    = rc_ioq_data;
          icq_wrbyten_d   = rc_ioq_be;
          icq_wrtag_d     = rc_ioq_tag;
          icq_wrpoison_d  = rc_ioq_poison;
          icq_wrerrcode_d = rc_ioq_errcode;
          icq_wrstatus_d  = rc_ioq_status;
          icq_write_d     = 1'b1;
        end
      end

      WSTATE_WRITE: begin
        icq_wrdata[127:0]   = icq_wrdata_q;
        icq_wrdata[135:128] = icq_wrbyten_q;
        icq_wrdata[143:136] = icq_wrtag_q;
        icq_wrdata[144]     = icq_wrpoison_q;
        icq_wrdata[148:145] = icq_wrerrcode_q;
        icq_wrdata[151:149] = icq_wrstatus_q;
        icq_wrdata[254:152] = 103'h0;

        if(~icq_wfull) begin
          icq_write = icq_write_q;
        end
      end
    endcase

  end


  //-------------------------------------------------------
  //  I/O Completion Queue
  //-------------------------------------------------------

  reg                         icq_rack;
  wire [icq_entry_width-1:0]  icq_rdata;
  wire                        icq_rval;
  wire                        icq_rerr;

  nvme_async_fifo #( 
      .width(icq_entry_width),
      .awidth(10)  // 1024 entries (need at least 5)
  ) icq (
      // write (PCIe RC -> ICQ)
      .wclk                           (user_clk),
      .wreset                         (user_reset),
      .write                          (icq_write),
      .wdata                          (icq_wrdata),
      .wfull                          (icq_wfull),
      .wafull                         (),

      // read (ICQ -> CSR)
      .rclk                           (user_clk),
      .rreset                         (user_reset),
      .rack                           (icq_rack),
      .rdata                          (icq_rdata),
      .rval                           (icq_rval),
      .rerr                           (icq_rerr)              
  );



  //-------------------------------------------------------
  //  Read Completions from ICQ to CSR
  //-------------------------------------------------------
  reg         icq_rdvalid_q, icq_rdvalid_d;
  reg [127:0] icq_rddata_q, icq_rddata_d;
  reg [7:0]   icq_rdbyten_q, icq_rdbyten_d;
  reg [7:0]   icq_rdtag_q, icq_rdtag_d;
  reg         icq_rdpoison_q, icq_rdpoison_d;
  reg [3:0]   icq_rderrcode_q, icq_rderrcode_d;
  reg [2:0]   icq_rdstatus_q, icq_rdstatus_d;

        
  reg [3:0] icq_rstate_q, icq_rstate_d;
  //localparam RSTATE_IDLE = 4'h1;

  always @(posedge user_clk or posedge user_reset) begin
    if( user_reset ) begin
      icq_rdvalid_q   <= 1'b0;
      icq_rddata_q    <= 256'h0;
      icq_rdbyten_q   <= 8'h0;
      icq_rdtag_q     <= 6'h0;
      icq_rdpoison_q  <= 1'b0;
      icq_rderrcode_q <= 4'h0;
      icq_rdstatus_q  <= 3'h0;
    end 
    else begin
      icq_rdvalid_q   <= icq_rdvalid_d;
      icq_rddata_q    <= icq_rddata_d;
      icq_rdbyten_q   <= icq_rdbyten_d;
      icq_rdtag_q     <= icq_rdtag_d;
      icq_rdpoison_q  <= icq_rdpoison_d;
      icq_rderrcode_q <= icq_rderrcode_d;
      icq_rdstatus_q  <= icq_rdstatus_d;
    end
  end


  always @(*) begin
    if( user_reset ) begin
      icq_rstate_d = RSTATE_IDLE;
    end
    icq_rstate_d = icq_rstate_q;

    icq_rddata_d    = icq_rddata_q;
    icq_rdbyten_d   = icq_rdbyten_q;
    icq_rdtag_d     = icq_rdtag_q;
    icq_rdpoison_d  = icq_rdpoison_q;
    icq_rderrcode_d = icq_rderrcode_q;
    icq_rdstatus_d  = icq_rdstatus_q;

    icq_rack = 1'b0;
    icq_rdvalid_d = 1'b0;

    case (icq_rstate_q)
      RSTATE_IDLE: begin
        if( icq_rval ) begin
          icq_rack      = 1'b1;
          icq_rdvalid_d   = 1'b1;
          
          icq_rddata_d    = icq_rdata[128:0];
          icq_rdbyten_d   = icq_rdata[136:129];
          icq_rdtag_d     = icq_rdata[144:137];
          icq_rdpoison_d  = icq_rdata[145];
          icq_rderrcode_d = icq_rdata[149:146];
          icq_rdstatus_d  = icq_rdata[152:150];
        end
      end
    endcase // case (icq_rstate_q)
    
    ioq_csr_data[127:0]   = icq_rddata_q;
    ioq_csr_data[136:129] = icq_rdbyten_q;
    ioq_csr_data[144:137] = icq_rdtag_q;
    ioq_csr_data[145]     = icq_rdpoison_q;
    ioq_csr_data[149:146] = icq_rderrcode_q;
    ioq_csr_data[152:150] = icq_rdstatus_q;
  end


endmodule

