
//  *************************************************************************
//  File : nvme_async_fifo.v
//  *************************************************************************
//  Todd Greenfield
//  IBM
//  toddg@us.ibm.com
//  *************************************************************************
//  Description : asynchronous fifo
//                Uses gray code counters for async crossing
//                Only power of 2 sizes allowed.
//
//                If wfull is asserted and write is asserted, 
//                the write data is silently dropped
//
//                when rval is asserted, rdata is valid
//                when the rack input is asserted, 
//                  rval and rdata are updated on the following cycle.
//  
//  *************************************************************************

module nvme_async_fifo#
  ( 
    parameter width = 8,             // data width
    parameter awidth = 4,            // address width.  Number of entries is based on this.
    parameter almost_full_count = 0  // almost full count.  Assert wafull when this many entries are left
    )
   (
    input                  wreset,
    input                  wclk,
    input                  write,
    input      [width-1:0] wdata,
    output reg             wfull,
    output reg             wafull,

    
    input                  rreset,
    input                  rclk,
    input                  rack,
    output reg [width-1:0] rdata,
    output reg             rval,
    output reg             rerr
    
    );

`include "nvme_func.inc"
   
   localparam words = (1<<awidth);
 

   (* RAM_STYLE="block" *)  reg [width-1:0] fifo[0:words-1];

   // write clock domain
   wire            wreset_int;
   reg             write_int; 
   reg  [awidth:0] wbin_q, wbin_d;
   reg  [awidth:0] wgry_q, wgry_d;
   reg             wfull_q, wfull_d;
   reg             wafull_q, wafull_d;   

   // read clock domain
   wire            rreset_int;
   reg  [awidth:0] s0_rbin_q, s0_rbin_d;
   reg  [awidth:0] s0_rgry_q, s0_rgry_d;
   reg             s0_rempty_q, s0_rempty_d;
   reg [awidth-1:0] s0_raddr;
   reg              s1_ready;
   reg   [awidth:0] s1_rbin_q, s1_rbin_d;
   reg   [awidth:0] s1_rgry_q, s1_rgry_d;
   reg  [width-1:0] s1_rdata;
   reg              s1_rdata_v_q, s1_rdata_v_d;
   reg              s2_ready;
   reg  [width-1:0] s2_rdata_q, s2_rdata_d;
   reg              s2_rdata_v_q, s2_rdata_v_d;
   reg              s2_rerr_q, s2_rerr_d;

function [awidth:0] gray2bin;
   input [awidth:0] gray;

   integer      i;

   begin
      gray2bin[awidth]=gray[awidth];
      for (i=awidth-1;i<=0;i=i-1)
        begin
           gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
   end
endfunction // gray2bin

   
   //------------------------------------------------------
   // infer simple two port ram with separate read and write clocks
   //------------------------------------------------------
   always @(posedge wclk)
     if (write_int)
       fifo[wbin_q[awidth-1:0]] <= wdata;

   always @(posedge rclk)
     s1_rdata <= fifo[s0_raddr];

   
   //------------------------------------------------------
   // write clock domain
   //------------------------------------------------------

   always @(posedge wclk or posedge wreset_int)
     begin
        if ( wreset_int == 1'b1 )
          begin
             wbin_q   <= zero[awidth:0];             
             wgry_q   <= zero[awidth:0];             
             wfull_q  <= 1'b0;
             wafull_q <= 1'b0;
          end
        else
          begin
             wbin_q   <= wbin_d;           
             wgry_q   <= wgry_d;           
             wfull_q  <= wfull_d;
             wafull_q <= wafull_d;
          end
     end
   
   // synchronize read pointer in write clock domain
   // use stage 1 gray pointer because pipeline stall uses this as array address
   (* ASYNC_REG="TRUE" *) reg [awidth:0] wclkm1_rgry_q;
   (* ASYNC_REG="TRUE" *) reg [awidth:0] wclkm2_rgry_q;
   always @(posedge wclk)
     begin
        wclkm1_rgry_q <= s1_rgry_q;
        wclkm2_rgry_q <= wclkm1_rgry_q;
     end

   // force both pointers to reset if either are reset
   // resetting only one pointer is bad...
   // synchronize reset from read domain
   (* ASYNC_REG="TRUE" *) reg [1:0] wclk_rreset_q;
   always @(posedge wclk) 
     wclk_rreset_q[1:0] <= { wclk_rreset_q[0], rreset };

   assign wreset_int = wreset | wclk_rreset_q[1];

   // write to fifo
   always @*
     begin
               
        if( write & ~wfull_q )
          begin
             write_int  = 1'b1;
             wbin_d     = wbin_q + one[awidth:0];  
             wgry_d     = {1'b0, wbin_d[awidth:1]} ^ wbin_d;  // convert binary to gray
          end
        else
          begin
             write_int  = 1'b0;
             wbin_d     = wbin_q;
             wgry_d     = wgry_q;
          end

        // compare write pointer with synchronized read pointer
        // converting gray to binary is more painful than binary to gray, so do the compare with gray code
        //
        // in binary:  full = (write_pointer - read_pointer)==fifo_size   # pointers wrap at fifo_size * 2
        //
        // with gray code, can't just subtract.  Instead, take advantage of how the gray code is "inverted"
        // For an n bit gray counter, you can invert the two most sig bits to subtract 2**(n-1)
        //  example:  8b counter with 256 gray codes.  
        //            2**(n-1)='d128.  
        //               d175 = x0f8 in gray code
        //       175-128=d47  = x038 in gray code

        wfull_d  = (wgry_d ^ {2'b11,zero[awidth-2:0]}) == wclkm2_rgry_q;
        wfull    = wfull_q;

        // for the "almost full" calculation, we will need to convert to binary
        // use the registered write count for timing, so wafull_q is delayed by 1 cycle
        if( almost_full_count == 0 )
          begin
             wafull_d = wfull_d;
          end
        else
          begin
             wafull_d = (wbin_q-gray2bin(wclkm2_rgry_q)) <= almost_full_count[awidth:0];
          end

        wafull = wafull_q;
     end


   //------------------------------------------------------
   // read clock domain
   //------------------------------------------------------
   always @(posedge rclk or posedge rreset_int)
     begin
        if ( rreset_int == 1'b1 )
          begin            
             s0_rbin_q    <= zero[awidth:0];
             s0_rgry_q    <= zero[awidth:0];
             s0_rempty_q  <= 1'b1;           
             s1_rdata_v_q <= 1'b0;
             s1_rbin_q    <= zero[awidth:0];
             s1_rgry_q    <= zero[awidth:0];
             s2_rdata_v_q <= 1'b0;
             s2_rdata_q   <= zero[width-1:0];
             s2_rerr_q    <= 1'b0;
          end
        else
          begin             
             s0_rbin_q    <= s0_rbin_d;
             s0_rgry_q    <= s0_rgry_d;
             s0_rempty_q  <= s0_rempty_d;           
             s1_rdata_v_q <= s1_rdata_v_d;
             s1_rbin_q    <= s1_rbin_d;
             s1_rgry_q    <= s1_rgry_d;
             s2_rdata_v_q <= s2_rdata_v_d;
             s2_rdata_q   <= s2_rdata_d;
             s2_rerr_q    <= s2_rerr_d;
           end
     end
      
   // synchronize write pointer in read clock domain
   (* ASYNC_REG="TRUE" *) reg [awidth:0] rclkm1_wgry_q;
   (* ASYNC_REG="TRUE" *) reg [awidth:0] rclkm2_wgry_q;
   always @(posedge rclk)
     begin
        rclkm1_wgry_q <= wgry_q;
        rclkm2_wgry_q <= rclkm1_wgry_q;
     end

   // synchronize reset from write domain
   (* ASYNC_REG="TRUE" *) reg [1:0] rclk_wreset_q; 
   always @(posedge rclk) 
     rclk_wreset_q[1:0] <= { rclk_wreset_q[0], wreset };
   assign rreset_int = rreset | rclk_wreset_q[1];
   
   // read from array into output register
   reg       s0_valid;
   always @*
     begin
        // advance read address if stage 1 is ready
        if( ~s0_rempty_q & s1_ready)
          begin
             s0_rbin_d  = s0_rbin_q + one[awidth:0];
             s0_raddr   = s0_rbin_q[awidth-1:0];
             s0_valid   = 1'b1;
             s0_rgry_d  = {1'b0,s0_rbin_d[awidth:1]} ^ s0_rbin_d;  // convert binary to gray
          end
        else
          begin
             s0_rbin_d  = s0_rbin_q;
             s0_raddr   = s1_rbin_q[awidth-1:0];        
             s0_valid   = 1'b0;
             s0_rgry_d  = s0_rgry_q;
          end

        // if pointers are equal, then the fifo is empty
        // compare using synchronized write pointer
        s0_rempty_d  = s0_rgry_d == rclkm2_wgry_q;
     end

   // stage 1 - read data from array
   always @*
     begin
        s1_rdata_v_d  = (s1_rdata_v_q & ~s2_ready) | s0_valid;
        s1_ready      = ~s1_rdata_v_q | s2_ready;
        if( s1_ready )   
          begin
             // advance pipeline
             s1_rbin_d   = s0_rbin_q;
             s1_rgry_d   = s0_rgry_q;
          end
        else
          begin
             // stall pipeline
             // s0_raddr stalled as well
             s1_rbin_d   = s1_rbin_q;
             s1_rgry_d   = s1_rgry_q;
          end
     end

   // stage 2 - load output register and assert valid on interface
   always @*
     begin
        s2_rdata_v_d  = s2_rdata_v_q & ~rack;
        s2_rdata_d    = s2_rdata_q;
        s2_rerr_d     = 1'b0; // todo: ECC or parity coverage
        s2_ready      = ~s2_rdata_v_q | rack;
       
        // load output register
        if(s2_ready & s1_rdata_v_q)
          begin
             s2_rdata_v_d  = 1'b1;
             s2_rdata_d    = s1_rdata;
          end
 
        // outputs
        rval      = s2_rdata_v_q;
        rdata     = s2_rdata_q;    
        rerr      = s2_rerr_q;   
     end

endmodule // nvme_async_fifo


  
