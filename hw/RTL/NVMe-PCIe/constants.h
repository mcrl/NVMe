// Constants 

// Request Type
localparam [3:0]  CfgRd         = 4'b1000;
localparam [3:0]  CfgWr         = 4'b1010;
localparam [3:0]  MemRd         = 4'b0000;
localparam [3:0]  MemWr         = 4'b0001;

// BAR
localparam [63:0] BAR0          = 64'h0000_0010_0000_0000;

// Requester and Completer ID
localparam [15:0] REQUESTER_ID  = 16'h4508;
localparam [15:0] COMPLETER_ID  = 16'h0000;

// Admin Submission/Completion Queue Doorbell Register Offset
localparam [63:0] SQT_OFFSET = 64'h0000_0000_0000_1000;
localparam [63:0] CQH_OFFSET = 64'h0000_0000_0000_1004;

