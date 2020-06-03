// written 2020-06-03 by mza
// last updated 2020-06-03 by mza

// definitions from https://en.wikipedia.org/wiki/Advanced_eXtensible_Interface
module pollable_memory_axi4lite_slave #(
	parameter ADDRESS_WIDTH = 4,
	parameter DATA_WIDTH = 32
) (
	input clock,
	input reset,
	// Write Address channel (AW)
	input [ADDRESS_WIDTH-1:0] awaddr, // Address of the first beat of the burst
	// awprot
	input awvalid, // xVALID handshake signal
	output reg awready = 0, // xREADY handshake signal
	// Write Data channel (W)
	input [DATA_WIDTH-1:0] wdata, // Read/Write data
	//input wlast, // Last beat identifier
	// wstrb, // Byte strobe, to indicate which bytes of the WDATA signal are valid
	input wvalid, // xVALID handshake signal
	output reg wready = 0, // xREADY handshake signal
	// Write Response channel (B)
	output reg bresp = 0, // Write response, to specify the status of the burst
	output reg bvalid = 0, // xVALID handshake signal
	input bready, // xREADY handshake signal
	// Read Address channel (AR)
	input [ADDRESS_WIDTH-1:0] araddr, // Address of the first beat of the burst
	// arprot, // Protection type: privilege, security level and data/instruction access
	input arvalid, // xVALID handshake signal
	output reg arready = 0, // xREADY handshake signal
	// Read Data channel (R)
	output reg [DATA_WIDTH-1:0] rdata = 0, // Read/Write data
//	output reg rresp = 0, // Read response, to specify the status of the current RDATA signal
	//output rlast, // Last beat identifier
	output reg rvalid = 0, // xVALID handshake signal
	input rready // xREADY handshake signal
);
	reg [2:0] wstate = 0;
	reg [ADDRESS_WIDTH-1:0] local_awaddr = 0;
	reg [DATA_WIDTH-1:0] local_wdata = 0;
	reg pre_bresp   = 0;
	reg pre_bvalid  = 0;
	reg [1:0] rstate = 0;
	reg [ADDRESS_WIDTH-1:0] local_araddr = 0;
	reg pre_arready = 0;
	reg [DATA_WIDTH-1:0] pre_rdata = 0;
//	reg pre_rresp  = 0;
	reg pre_rvalid = 0;
	reg [DATA_WIDTH-1:0] mem [2**ADDRESS_WIDTH-1:0];
	always @(posedge clock) begin
//		pre_bresp   <= 0;
//		pre_bvalid  <= 0;
//		pre_arready <= 0;
//		pre_rdata   <= 0;
//		pre_rresp   <= 0;
//		pre_rvalid  <= 0;
		if (reset) begin
			wstate <= 0;
			local_awaddr <= 0;
			awready <= 1;
			local_wdata <= 0;
			wready <= 1;
			local_araddr <= 0;
			arready <= 1;
			pre_bresp   <= 0;
			pre_bvalid  <= 0;
			pre_arready <= 1;
			pre_rdata   <= 0;
//			pre_rresp   <= 0;
			pre_rvalid  <= 0;
		end else begin
			bresp   <= pre_bresp;
			bvalid  <= pre_bvalid;
			arready <= pre_arready;
			rdata   <= pre_rdata;
//			rresp   <= pre_rresp;
			rvalid  <= pre_rvalid;
			// write
			if (wstate[2]==0) begin
				if (wstate[1:0]==2'b11) begin
					mem[local_awaddr] <= local_wdata;
					pre_bresp <= 1;
					pre_bvalid <= 1;
					wstate[2] <= 1;
				end
				if (awvalid) begin
					local_awaddr <= awaddr;
					awready <= 0;
					wstate[0] <= 1;
				end
				if (wvalid) begin
					local_wdata <= wdata;
					wready <= 0;
					wstate[1] <= 1;
				end
			end else begin
				wstate[1:0] <= 0;
				if (bready) begin
					pre_bresp <= 0;
					pre_bvalid <= 0;
					awready <= 1;
					wready <= 1;
					wstate[2] <= 0;
				end
			end
			// read
			if (rstate[1]==0) begin
				if (rstate[0]) begin
					pre_rdata <= mem[local_araddr];
					pre_rvalid <= 1;
					rstate[1] <= 1;
				end
				if (arvalid) begin
					local_araddr <= araddr;
					arready <= 0;
					rstate[0] <= 1;
				end
			end else begin
				rstate[0] <= 0;
				if (rready) begin
					pre_rvalid <= 0;
//					pre_rresp <= ;
					arready <= 1;
					rstate[1] <= 0;
				end
			end
		end
	end
endmodule


module axi4lite_handshake (
	input clock,
	input reset,
	input ready,
	input valid_in,
	output reg valid_out = 0
);
	reg state = 0;
	always @(posedge clock) begin
		if (reset) begin
			valid_out <= 0;
			state <= 0;
		end else begin
			if (state==0) begin
				if (valid_in) begin
					valid_out <= 1;
					state <= 1;
				end
			end else begin
				if (ready) begin
					valid_out <= 0;
					state <= 0;
				end
			end
		end
	end
endmodule

module pollable_memory_axi4lite_slave_tb;
	localparam ADDRESS_WIDTH = 4;
	localparam DATA_WIDTH = 32;
	reg clock = 0;
	reg reset = 1;
	reg [ADDRESS_WIDTH-1:0] pre_awaddr = 0;
	reg [ADDRESS_WIDTH-1:0] awaddr = 0;
	reg pre_awvalid = 0;
	wire awvalid;
	wire awready;
	reg [DATA_WIDTH-1:0] pre_wdata = 0;
	reg [DATA_WIDTH-1:0] wdata = 0;
	reg pre_wvalid = 0;
	wire wvalid;
	wire wready;
	wire bresp;
	wire bvalid;
	reg pre_bready = 0;
	reg bready = 0;
	reg [ADDRESS_WIDTH-1:0] pre_araddr = 0;
	reg [ADDRESS_WIDTH-1:0] araddr = 0;
	reg pre_arvalid = 0;
	reg arvalid = 0;
	wire arready;
	wire [DATA_WIDTH-1:0] rdata;
//	wire rresp;
	wire rvalid;
	reg pre_rready = 0;
	reg rready = 0;
	pollable_memory_axi4lite_slave #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH)) pmas (
		.clock(clock), .reset(reset),
		.awaddr(awaddr), .awvalid(awvalid), .awready(awready),
		.wdata(wdata), .wvalid(wvalid), .wready(wready),
		.bresp(bresp), .bvalid(bvalid), .bready(bready),
		.araddr(araddr), .arvalid(arvalid), .arready(arready),
		.rdata(rdata), .rvalid(rvalid), .rready(rready)
	);
	axi4lite_handshake awhandshake (.clock(clock), .reset(reset), .ready(awready), .valid_in(pre_awvalid), .valid_out(awvalid));
	axi4lite_handshake whandshake (.clock(clock), .reset(reset), .ready(wready), .valid_in(pre_wvalid), .valid_out(wvalid));
	axi4lite_handshake arhandshake (.clock(clock), .reset(reset), .ready(arready), .valid_in(pre_arvalid), .valid_out(arvalid));
	task automatic master_read_transaction;
		input [ADDRESS_WIDTH-1:0] address;
		begin
			#100;
			pre_araddr <= address;
			pre_arvalid <= 1;
			#10;
			pre_arvalid <= 0;
		end
	endtask
	task automatic master_write_transaction;
		input [ADDRESS_WIDTH-1:0] address;
		input [DATA_WIDTH-1:0] data;
		begin
			#100;
			pre_awaddr <= address;
			pre_awvalid <= 1;
			#10;
			pre_awvalid <= 0;
			#100;
			pre_wdata <= data;
			pre_wvalid <= 1;
			#10;
			pre_wvalid <= 0;
//			#30;
//			if (bvalid) begin
	//			if (bresp) begin
	//			end
//				pre_bready <= 0;
//			end
			#100;
			pre_bready <= 1;
		end
	endtask
	initial begin
		#100;
		reset <= 0;
		pre_awaddr <= 0;
		pre_awvalid <= 0;
		pre_wdata <= 0;
		pre_wvalid <= 0;
		pre_bready <= 1;
		pre_araddr <= 0;
		pre_arvalid <= 0;
		pre_rready <= 1;
		#100; master_write_transaction(.address(4'h2), .data(32'h12345678));
		#100; master_write_transaction(.address(4'h5), .data(32'habcdef01));
		#100; master_write_transaction(.address(4'he), .data(32'h55550000));
		#100; master_write_transaction(.address(4'hc), .data(32'h00aa00aa));
		#100; master_read_transaction(.address(4'h2));
		#100; master_read_transaction(.address(4'hc));
		#100; master_read_transaction(.address(4'he));
		#100; master_read_transaction(.address(4'hc));
	end
	always @(posedge clock) begin
		awaddr <= pre_awaddr;
		wdata <= pre_wdata;
		bready <= pre_bready;
		araddr <= pre_araddr;
		arvalid <= pre_arvalid;
		rready <= pre_rready;
	end
	always begin
		#5;
		clock <= ~clock;
	end
endmodule

