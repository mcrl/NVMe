module kernel (
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host ADDR" *)
  input logic [14:0] host_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host CLK" *)
  input logic host_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host DIN" *)
  input logic [31:0] host_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host DOUT" *)
  output logic [31:0] host_dout,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host EN" *)
  input logic host_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host RST" *)
  input logic host_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host WE" *)
  input logic [3:0] host_we
);

always_ff @(posedge host_clk) begin
  if (host_rst) begin
  end else begin
  end
end

endmodule
			
			