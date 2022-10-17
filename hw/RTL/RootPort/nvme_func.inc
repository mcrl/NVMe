


localparam [511:0] zero = 512'h0;
localparam [511:0] one = {511'h0, 1'b1};

// address region encodes
localparam ENUM_ADDR_REGS = 4'h0;
localparam ENUM_ADDR_ADQ  = 4'h1;
localparam ENUM_ADDR_IOQ  = 4'h2;
localparam ENUM_ADDR_PRP  = 4'h3;
localparam ENUM_ADDR_SISL = 4'h4;
localparam ENUM_ADDR_INTN = 4'h5;

// base address for NVME controller registers
// these need to be in sync with microcode
localparam NVME_BAR1 = 32'h00000000;
localparam NVME_BAR0 = 32'h93800000;

// offsets from NVME_BAR0/1 for doorbell registers
// todo: check that SQ1TDBL/CQ1HDBL are really fixed addresses
localparam NVME_REG_SQ0TDBL = 32'h1000;
localparam NVME_REG_CQ0HDBL = 32'h1004;
localparam NVME_REG_SQ1TDBL = 32'h1008;
localparam NVME_REG_CQ1HDBL = 32'h100C;


// NVME opcodes
localparam NVME_IO_FLUSH = 8'h0;
localparam NVME_IO_WRITE = 8'h1;
localparam NVME_IO_READ  = 8'h2;

localparam rr_max_width=32;      
function [rr_max_width-1:0] roundrobin;
   input [rr_max_width-1:0] valid;
   input [rr_max_width-1:0] ptr;
   
   reg [rr_max_width*2-1:0] request;
   reg [rr_max_width*2-1:0] nextptr;
   reg                      any_request;      
   integer                  i,j,k;
   
   begin

      // wrap around by duplicating the valid input
      request = {valid, valid};

      // the input pointer should be 1 hot with the last granted position set
      // shift 1 to the right and unroll the wrap around
      nextptr = {1'b0, ptr, ptr[rr_max_width-1:1]};

      for(i=0;i<rr_max_width;i=i+1)
        begin
           // grant the request if asserted and the pointer says input i is next
           // or if the request to the left is next and its not asserted
           // and so on
           roundrobin[i] = request[i] & nextptr[i];
           for (j=1;j<rr_max_width;j=j+1)
             begin
                any_request = 1'b0;
                for (k=i+1;k<=(i+j);k=k+1)
                  begin
                     any_request = any_request | request[k];
                  end
                roundrobin[i] = roundrobin[i] | 
                                (request[i] & 
                                 nextptr[i+j] & 
                                 ~any_request);                   
             end
        end                           
   end
endfunction // roundrobin


// function to implement $clog2 from systemverilog (IEEE Std 1800-2012)
// xilinx vivado uses verilog 2001 ?
// probably could get vivado to use system verilog with the right compile switches
// see ieee 1364-2001 pg 162
function integer clogb2;
   input integer value;
   begin
      value = value - 1;
      for (clogb2=0; value>0; clogb2=clogb2+1)
        value = value >> 1;
   end
endfunction

function [127:0] byteswap128;
   input [127:0] din;  
   begin
      byteswap128[7:0]      = din[127:120];
      byteswap128[15:8]     = din[119:112];
      byteswap128[23:16]    = din[111:104];
      byteswap128[31:24]    = din[103:96];
      byteswap128[39:32]    = din[95:88];
      byteswap128[47:40]    = din[87:80];
      byteswap128[55:48]    = din[79:72];
      byteswap128[63:56]    = din[71:64];
      byteswap128[71:64]    = din[63:56];
      byteswap128[79:72]    = din[55:48];
      byteswap128[87:80]    = din[47:40];
      byteswap128[95:88]    = din[39:32];
      byteswap128[103:96]   = din[31:24];
      byteswap128[111:104]  = din[23:16];
      byteswap128[119:112]  = din[15:8];
      byteswap128[127:120]  = din[7:0];    
   end
endfunction
   
   

   
// i_req  interface command encoding
// ---------------------------------
// range is [cmd_width-1:0]
localparam FCP_GSCSI_RD = 32'h03;
localparam FCP_GSCSI_WR = 32'h04;
localparam FCP_ABORT    = 32'h05;
localparam FCP_TASKMAN  = 32'h06;

// internal command event encoding - 8b
localparam CMD_RD        = FCP_GSCSI_RD;
localparam CMD_WR        = FCP_GSCSI_WR;
localparam CMD_ABORT     = FCP_ABORT;
localparam CMD_TASKMAN   = FCP_TASKMAN;
localparam CMD_RD_LOOKUP = 32'h83;
localparam CMD_WR_LOOKUP = 32'h84;
localparam CMD_CPL_IOQ   = 32'h85;
localparam CMD_CPL_ADMIN = 32'h86;
localparam CMD_INVALID   = 32'h8e;
localparam CMD_TIMEOUT   = 32'h90;
localparam CMD_INIT      = 32'h91;
localparam CMD_DEBUG     = 32'h92;


// o_rsp  interface response encoding
// ---------------------------------
// range is [rsp_width-1:0]
// codes x00 to x40 are scsi status codes from SAM-4
// codes > x40 are fc_module specific
localparam FCP_RSP_GOOD    = 32'h00;
localparam FCP_RSP_CHECK   = 32'h02;
localparam FCP_RSP_BUSY    = 32'h08;


localparam FCP_RSP_CRCERR    = 32'h51;
localparam FCP_RSP_ABORTPEND = 32'h52;
localparam FCP_RSP_WRABORT   = 32'h53;
localparam FCP_RSP_NOLOGI    = 32'h54;
localparam FCP_RSP_NOEXP     = 32'h55;
localparam FCP_RSP_INUSE     = 32'h56;
localparam FCP_RSP_LINKDOWN  = 32'h57;
localparam FCP_RSP_ABORTOK   = 32'h58;
localparam FCP_RSP_ABORTFAIL = 32'h59;
localparam FCP_RSP_RESID     = 32'h5A;
localparam FCP_RSP_RESIDERR  = 32'h5B;
localparam FCP_RSP_TGTABORT  = 32'h5C;
localparam FCP_RSP_IDLE      = 32'h5D;

// fcx_status
localparam FCX_STAT_NONE     = 32'h00;
localparam FCX_STAT_TIMEOUT  = 32'h01;
localparam FCX_STAT_AFUABORT = 32'h02;
localparam FCX_STAT_WRERR    = 32'h03;

// SCSI opcodes
// perl -ne 'if( /.define\s*(SCSI_\S+)\s*0x(\S+)/ ) { print "localparam [7:0] $1 = 8'"'"'h$2;\n";}' ../../surelock-sw/src/include/cflash_scsi_user.h
localparam [7:0] SCSI_INQUIRY = 8'h12;
localparam [7:0] SCSI_MODE_SELECT = 8'h15;
localparam [7:0] SCSI_MODE_SELECT_10 = 8'h55;
localparam [7:0] SCSI_MODE_SENSE = 8'h1A;
localparam [7:0] SCSI_MODE_SENSE_10 = 8'h5A;
localparam [7:0] SCSI_PERSISTENT_RESERVE_IN = 8'h5E;
localparam [7:0] SCSI_PERSISTENT_RESERVE_OUT = 8'h5F;
localparam [7:0] SCSI_READ = 8'h08;
localparam [7:0] SCSI_READ_6 = 8'h08;
localparam [7:0] SCSI_READ_10 = 8'h28;
localparam [7:0] SCSI_READ_12 = 8'hA8;
localparam [7:0] SCSI_READ_16 = 8'h88;
localparam [7:0] SCSI_READ_CAPACITY = 8'h25;
localparam [7:0] SCSI_READ_EXTENDED = 8'h28;
localparam [7:0] SCSI_REPORT_LUNS = 8'hA0;
localparam [7:0] SCSI_REQUEST_SENSE = 8'h03;
localparam [7:0] SCSI_LOG_SENSE = 8'h4d;
localparam [7:0] SCSI_SERVICE_ACTION_IN = 8'h9E;
localparam [7:0] SCSI_SERVICE_ACTION_OUT = 8'h9F;
localparam [7:0] SCSI_START_STOP_UNIT = 8'h1B;
localparam [7:0] SCSI_TEST_UNIT_READY = 8'h00;
localparam [7:0] SCSI_WRITE = 8'h0A;
localparam [7:0] SCSI_WRITE_6 = 8'h0A;
localparam [7:0] SCSI_WRITE_10 = 8'h2A;
localparam [7:0] SCSI_WRITE_12 = 8'hAA;
localparam [7:0] SCSI_WRITE_16 = 8'h8A;
localparam [7:0] SCSI_WRITE_AND_VERIFY = 8'h2E;
localparam [7:0] SCSI_WRITE_AND_VERIFY_16 = 8'h8E;
localparam [7:0] SCSI_WRITE_EXTENDED = 8'h2A;
localparam [7:0] SCSI_WRITE_SAME = 8'h41;
localparam [7:0] SCSI_WRITE_SAME_16 = 8'h93;

localparam [7:0] SCSI_GOOD_STATUS = 8'h00;
localparam [7:0] SCSI_CHECK_CONDITION = 8'h02;
localparam [7:0] SCSI_BUSY_STATUS = 8'h08;
localparam [7:0] SCSI_INTMD_GOOD = 8'h10;
localparam [7:0] SCSI_RESERVATION_CONFLICT = 8'h18;
localparam [7:0] SCSI_COMMAND_TERMINATED = 8'h22;
localparam [7:0] SCSI_QUEUE_FULL = 8'h28;
localparam [7:0] SCSI_ACA_ACTIVE = 8'h30;
localparam [7:0] SCSI_TASK_ABORTED = 8'h40;

localparam [3:0] SKEY_NO_SENSE = 4'h0;
localparam [3:0] SKEY_NOT_READY = 4'h2;
localparam [3:0] SKEY_MEDIUM_ERROR = 4'h3;
localparam [3:0] SKEY_HARDWARE_ERROR = 4'h4;
localparam [3:0] SKEY_ILLEGAL_REQUEST = 4'h5;
localparam [3:0] SKEY_UNIT_ATTENTION = 4'h6;
localparam [3:0] SKEY_WRITE_PROTECT = 4'h7;
localparam [3:0] SKEY_ABORTED_COMMAND = 4'hB;

// www.t10.org/lists/asc-num.htm
localparam [15:0] ASCQ_NO_ERROR = 16'h0000;
localparam [15:0] ASCQ_NO_ADDITIONAL_SENSE_CODE = 16'h0000;
localparam [15:0] ASCQ_INVALID_COMMAND_OPERATION_CODE = 16'h2000;
localparam [15:0] ASCQ_LOGICAL_BLOCK_ADDRESS_OUT_OF_RANGE = 16'h2100;
localparam [15:0] ASCQ_INVALID_FIELD_IN_CDB = 16'h2400;
localparam [15:0] ASCQ_LOGICAL_UNIT_NOT_SUPPORTED = 16'h2500;
localparam [15:0] ASCQ_INVALID_FIELD_IN_COMMAND_INFORMATION_UNIT = 16'h0E03;
localparam [15:0] ASCQ_INTERNAL_TARGET_FAILURE = 16'h4400;
localparam [15:0] ASCQ_POWER_LOSS_EXPECTED = 16'h0B08;
localparam [15:0] ASCQ_ACCESS_DENIED_INVALID_LU_IDENTIFIER = 16'h2009;
localparam [15:0] ASCQ_NOT_READY_CAUSE_NOT_REPORTABLE = 16'h0400;
localparam [15:0] ASCQ_NOT_READY_BECOMING_READY = 16'h0401;
localparam [15:0] ASCQ_WRITE_PROTECT = 16'h2700;
localparam [15:0] ASCQ_WRITE_FAULT = 16'h0300;
localparam [15:0] ASCQ_UNRECOVERED_READ_ERROR = 16'h1100;
localparam [15:0] ASCQ_ACCESS_DENIED_NO_ACCESS_RIGHTS = 16'h2002;

// NVMe status codes
// see NVM-Express-1_1b 4.6.1
localparam [2:0] NVME_SCT_GENERIC = 3'h0;
localparam [2:0] NVME_SCT_CMDSPEC = 3'h1;
localparam [2:0] NVME_SCT_MEDIA   = 3'h2;
localparam [2:0] NVME_SCT_VENDOR  = 3'h7;
localparam [2:0] NVME_SCT_SISLITE = 3'h4;  // use reserved status code type for sislite errors

// generic status codes
localparam [7:0] NVME_SC_G_SUCCESS          = 8'h0;
localparam [7:0] NVME_SC_G_INVALID_OPCODE   = 8'h1;
localparam [7:0] NVME_SC_G_INVALID_FIELD    = 8'h2;
localparam [7:0] NVME_SC_G_ID_CONFLICT      = 8'h3;
localparam [7:0] NVME_SC_G_DATA_ERROR       = 8'h4;
localparam [7:0] NVME_SC_G_POWERLOSS        = 8'h5;
localparam [7:0] NVME_SC_G_INTERNAL         = 8'h6;
localparam [7:0] NVME_SC_G_ABORTREQ         = 8'h7;
localparam [7:0] NVME_SC_G_ABORTSQDEL       = 8'h8;
localparam [7:0] NVME_SC_G_ABORTFUSE1       = 8'h9;
localparam [7:0] NVME_SC_G_ABORTFUSE2       = 8'ha;
localparam [7:0] NVME_SC_G_INVALID_NSPACE   = 8'hb;
localparam [7:0] NVME_SC_G_LBA_RANGE        = 8'h80;
localparam [7:0] NVME_SC_G_CAPACITY_EXCEED  = 8'h81;
localparam [7:0] NVME_SC_G_NSPACE_NOT_READY = 8'h82;
localparam [7:0] NVME_SC_G_RESV_CONFLICT    = 8'h83;

// command spec status codes
localparam [7:0] NVME_SC_C_ABORT_LIMIT      = 8'h03;
localparam [7:0] NVME_SC_C_INVALID_FORMAT   = 8'h0A;
localparam [7:0] NVME_SC_C_ATTR_CONFLICT    = 8'h80;
localparam [7:0] NVME_SC_C_INVALID_PROT     = 8'h81;
localparam [7:0] NVME_SC_C_RO_WRITE         = 8'h82;

// Media status codes
localparam [7:0] NVME_SC_M_WRITE_FAULT      = 8'h80;
localparam [7:0] NVME_SC_M_UNRECOVERD_READ_ERROR = 8'h81;
localparam [7:0] NVME_SC_M_ACCESS_DENIED    = 8'h86;


// sislite status codes (not part of NVMe)
localparam [7:0] NVME_SC_S_NOT_IMPL         = 8'h50;
localparam [7:0] NVME_SC_S_ID_CONFLICT      = 8'h53;
localparam [7:0] NVME_SC_S_INVALID_FIELD    = 8'h54;  // invalid field in command information unit (ie: resid-over)
localparam [7:0] NVME_SC_S_LOGICAL_UNIT_NOT_SUPPORTED = 8'h55;
localparam [7:0] NVME_SC_S_DMA_ACCESS_ERR = 8'h56;  // dma read or write to offset > length

// tracking table entry fields
localparam [7:0] TRK_ST_IDLE  = 8'h00;
localparam [7:0] TRK_ST_RD    = 8'h01;  // sislite read command - expect DMA write to sislite
localparam [7:0] TRK_ST_WR    = 8'h02;  // sislite write command - expect DMA read request to sislite
localparam [7:0] TRK_ST_ADMIN = 8'h03;  // sislite command requiring admin queue or microcode
localparam [7:0] TRK_ST_RDERR = 8'h04;  // sislite read command - DMA write attempted past end of buffer
localparam [7:0] TRK_ST_WRERR = 8'h05;  // sislite read command - DMA read attempted past end of buffer
localparam [7:0] TRK_ST_WRSAME =  8'h06;







