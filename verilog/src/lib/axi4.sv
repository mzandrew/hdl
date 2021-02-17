// written 2021-02-12 by mza
// based off axi4lite.v
// last updated 2021-02-16 by mza

// notes:
// axi::burst_t WRAP mode is unsupported

package axi;
	typedef enum logic [2:0] { FIXED=3'b001, INCR=3'b010, WRAP=3'b100 } burst_t;
endpackage
//import axi::*;

module spi_slave_axi4_master__pollable_memory_axi4_slave__tb;
	localparam ADDRESS_WIDTH = 4;
	localparam DATA_WIDTH = 32;
	localparam LEN_WIDTH = 5;
	reg clock = 0;
	reg reset = 1;
	reg [ADDRESS_WIDTH-1:0] pre_spi_write_address = 0;
	reg [ADDRESS_WIDTH-1:0] spi_write_address = 0;
	reg pre_spi_write_address_valid = 0;
	reg spi_write_address_valid = 0;
	reg [DATA_WIDTH-1:0] pre_spi_write_data = 0;
	reg [DATA_WIDTH-1:0] spi_write_data = 0;
	reg pre_spi_write_strobe = 0;
	reg spi_write_strobe = 0;
	reg [ADDRESS_WIDTH-1:0] pre_spi_read_address = 0;
	reg [ADDRESS_WIDTH-1:0] spi_read_address = 0;
	reg pre_spi_read_address_valid = 0;
	reg spi_read_address_valid = 0;
	wire [DATA_WIDTH-1:0] spi_read_data;
	reg pre_spi_read_strobe = 0;
	reg spi_read_strobe = 0;
	wire [ADDRESS_WIDTH-1:0] awaddr;
	wire awvalid;
	wire awready;
	wire [DATA_WIDTH-1:0] wdata;
	wire wvalid;
	wire wready;
	wire bresp;
	wire bvalid;
	wire bready;
	wire [ADDRESS_WIDTH-1:0] araddr;
	wire arvalid;
	wire arready;
	wire [DATA_WIDTH-1:0] rdata;
	wire rvalid;
	wire rready;
	wire axi::burst_t awburst;
	wire axi::burst_t arburst;
	wire rlast;
	wire wlast;
	wire [LEN_WIDTH-1:0] awlen;
	wire [LEN_WIDTH-1:0] arlen;
	reg [LEN_WIDTH-1:0] pre_spi_write_burst_length = 1;
	reg [LEN_WIDTH-1:0] spi_write_burst_length = 1;
	reg [LEN_WIDTH-1:0] pre_spi_read_burst_length = 1;
	reg [LEN_WIDTH-1:0] spi_read_burst_length = 1;
	spi_slave__axi4_master      #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .LEN_WIDTH(LEN_WIDTH)) ssam (.*);
	pollable_memory__axi4_slave #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .LEN_WIDTH(LEN_WIDTH)) pmas (.*);
	wire awbeat = awready & awvalid;
	wire arbeat = arready & arvalid;
	wire  wbeat =  wready &  wvalid;
	wire  rbeat =  rready &  rvalid;
	wire  bbeat =  bready &  bvalid;
	always @(posedge awbeat) begin $display("%t, awbeat %08x", $time, spi_write_address); end
	always @(posedge arbeat) begin $display("%t, arbeat %08x", $time, spi_read_address); end
	always @(posedge  wbeat) begin $display("%t,  wbeat %08x", $time, wdata); end
	always @(posedge  rbeat) begin $display("%t,  rbeat %08x", $time, rdata); end
	always @(posedge  bbeat) begin $display("%t,  bbeat", $time); end
	task automatic master_read_transaction(input [ADDRESS_WIDTH-1:0] address, input [LEN_WIDTH:0] len);
		reg [ADDRESS_WIDTH:0] i;
		begin
			#100;
			pre_spi_read_burst_length <= len[LEN_WIDTH-1:0];
			pre_spi_read_address <= address;
			pre_spi_read_address_valid <= 1;
			for (i=0; i<len; i++) begin
				pre_spi_read_strobe <= 1;
				#10;
				pre_spi_read_strobe <= 0;
				pre_spi_read_address_valid <= 0;
				#100;
			end
		end
	endtask
	task automatic master_write_transaction(input [ADDRESS_WIDTH-1:0] address, input [LEN_WIDTH:0] len, input [DATA_WIDTH-1:0] data []);
		reg [ADDRESS_WIDTH:0] i;
		begin
			#100;
			pre_spi_write_burst_length <= len[LEN_WIDTH-1:0];
			pre_spi_write_address <= address;
			pre_spi_write_address_valid <= 1;
			for (i=0; i<len; i++) begin
				pre_spi_write_data <= data[i];
				pre_spi_write_strobe <= 1;
				#10;
				pre_spi_write_strobe <= 0;
				pre_spi_write_address_valid <= 0;
				#100;
			end
		end
	endtask
	reg [DATA_WIDTH-1:0] data [];
	reg [31:0] i = 0;
	initial begin
		#100; reset <= 0;
		data = new[2**LEN_WIDTH];
		for (i=i; i<2**LEN_WIDTH; i++) begin
			data[i] = i;
		end
		#100; data[0] = 32'h12345678; master_write_transaction(4'h0, 19, data);
		#100; data[0] = 32'habcdef01; master_write_transaction(4'h1, 1, data);
		#100; data[0] = 32'h55550000; data[1] = 32'h44bb44bb; master_write_transaction(4'hc, 2, data);
		#100; data[0] = 32'h00aa00aa; master_write_transaction(4'hd, 1, data);
		#100; master_read_transaction(4'h0, 2);
		#100; master_read_transaction(4'h1, 1);
		#100; master_read_transaction(4'hc, 2);
		#100; master_read_transaction(4'hd, 1);
		#100; master_read_transaction(4'h0, 20);
		#200; $finish;
	end
	always @(posedge clock) begin
		spi_write_address       <= pre_spi_write_address;
		spi_write_address_valid <= pre_spi_write_address_valid;
		spi_write_data          <= pre_spi_write_data;
		spi_write_strobe        <= pre_spi_write_strobe;
		spi_write_burst_length  <= pre_spi_write_burst_length;
		spi_read_address       <= pre_spi_read_address;
		spi_read_address_valid <= pre_spi_read_address_valid;
		spi_read_strobe        <= pre_spi_read_strobe;
		spi_read_burst_length  <= pre_spi_read_burst_length;
	end
	always begin
		#5;
		clock <= ~clock;
	end
endmodule

module spi_slave__axi4_master #(
//module axi4_master #(
	parameter ADDRESS_WIDTH = 4,
	parameter DATA_WIDTH = 32,
	parameter LEN_WIDTH = 5
) (
	input clock,
	input reset,
	// SPI write channel
	input [ADDRESS_WIDTH-1:0] spi_write_address,
	input spi_write_address_valid,
	input [DATA_WIDTH-1:0] spi_write_data,
	input spi_write_strobe,
	input [LEN_WIDTH-1:0] spi_write_burst_length,
	// SPI read channel
	input [ADDRESS_WIDTH-1:0] spi_read_address,
	input spi_read_address_valid,
	output reg [DATA_WIDTH-1:0] spi_read_data = 0,
	input spi_read_strobe,
	input [LEN_WIDTH-1:0] spi_read_burst_length,
	// axi4 Write Address channel (AW)
	output reg [ADDRESS_WIDTH-1:0] awaddr = 0, // Address of the first beat of the burst
	output reg [LEN_WIDTH-1:0] awlen = 1, // Number of beats inside the burst
	output axi::burst_t awburst, // Type of the burst
	// awprot
	output reg awvalid = 0, // xVALID handshake signal
	input awready, // xREADY handshake signal
	// axi4 Write Data channel (W)
	output reg [DATA_WIDTH-1:0] wdata = 0, // Read/Write data
	output reg wlast = 0, // Last beat identifier
	// wstrb, // Byte strobe, to indicate which bytes of the WDATA signal are valid
	output reg wvalid = 0, // xVALID handshake signal
	input wready, // xREADY handshake signal
	// axi4 Write Response channel (B)
	input bresp, // Write response, to specify the status of the burst
	input bvalid, // xVALID handshake signal
	output reg bready = 0, // xREADY handshake signal
	// axi4 Read Address channel (AR)
	output reg [ADDRESS_WIDTH-1:0] araddr = 0, // Address of the first beat of the burst
	output reg [LEN_WIDTH-1:0] arlen = 1, // Number of beats inside the burst
	output axi::burst_t arburst, // Type of the burst
	// arprot, // Protection type: privilege, security level and data/instruction access
	output reg arvalid = 0, // xVALID handshake signal
	input arready, // xREADY handshake signal
	// axi4 Read Data channel (R)
	input [DATA_WIDTH-1:0] rdata, // Read/Write data
//	input reg rresp, // Read response, to specify the status of the current RDATA signal
	input rlast, // Last beat identifier
	input rvalid, // xVALID handshake signal
	output reg rready = 0 // xREADY handshake signal);
);
	assign awburst = axi::INCR;
	assign arburst = axi::INCR;
	reg [ADDRESS_WIDTH-1:0] pre_awaddr = 0;
	reg pre_awvalid = 0;
	reg [DATA_WIDTH-1:0] pre_wdata = 0;
	reg pre_wvalid  = 0;
	reg [ADDRESS_WIDTH-1:0] pre_araddr = 0;
	reg pre_arvalid = 0;
	reg [2:0] rstate = 0;
	reg [3:0] wstate = 0;
	reg [ADDRESS_WIDTH-1:0] local_spi_write_address = 0;
	reg [DATA_WIDTH-1:0] local_spi_write_data = 0;
	reg [ADDRESS_WIDTH-1:0] local_spi_read_address = 0;
	reg [DATA_WIDTH-1:0] local_spi_read_data = 0;
	reg last_write_was_succecssful = 0;
	reg [LEN_WIDTH-1:0] pre_awlen = 1; // Number of beats inside the burst
	reg [LEN_WIDTH-1:0] pre_arlen = 1; // Number of beats inside the burst
	reg [LEN_WIDTH-1:0] write_transaction_counter = 0;
	reg [LEN_WIDTH-1:0] read_transaction_counter = 0;
	reg pre_wlast = 0;
	reg pre_rlast = 0;
	always @(posedge clock) begin
		pre_wlast <= 0;
		if (reset) begin
			pre_awaddr  <= 0;
			pre_awvalid <= 0;
			pre_wdata   <= 0;
			pre_wvalid  <= 0;
			bready  <= 0;
			pre_araddr  <= 0;
			pre_arvalid <= 0;
			rready  <= 0;
			wstate <= 0;
			rstate <= 0;
			last_write_was_succecssful <= 0;
			spi_read_data <= 0;
			pre_awlen <= 1;
			pre_arlen <= 1;
			write_transaction_counter <= 0;
			read_transaction_counter <= 0;
		end else begin
			awvalid <= pre_awvalid;
			awaddr  <= pre_awaddr;
			wvalid  <= pre_wvalid;
			wdata   <= pre_wdata;
			araddr  <= pre_araddr;
			arvalid <= pre_arvalid;
			awlen   <= pre_awlen;
			arlen   <= pre_arlen;
			wlast   <= pre_wlast;
			// write
			if (wstate[3:1]==0) begin
				if (wstate[0]==0) begin
					if (spi_write_strobe) begin
						if (spi_write_address_valid) begin
							local_spi_write_address <= spi_write_address;
							pre_awlen <= spi_write_burst_length;
							if (write_transaction_counter==0) begin
								write_transaction_counter <= spi_write_burst_length - 1'b1;
//							end else begin
//								error_count <= error_counter + 1'b1;
							end
						end else if (awburst==axi::INCR) begin
							local_spi_write_address <= local_spi_write_address + 1'b1;
							if (write_transaction_counter>=1) begin
								write_transaction_counter <= write_transaction_counter - 1'b1;
//							end else if (write_transaction_counter==0) begin
//								error_count <= error_counter + 1'b1;
							end
						end
						local_spi_write_data <= spi_write_data;
						wstate[0] <= 1;
					end
				end else begin
					pre_awaddr <= local_spi_write_address;
					pre_awvalid <= 1;
					pre_wdata <= local_spi_write_data;
					pre_wvalid <= 1;
					if (write_transaction_counter==0) begin
						pre_wlast <= 1;
					end
					bready <= 1;
					wstate[3:1] <= 3'b111;
				end
			end else begin
				wstate[0] <= 0;
				if (wstate[1]) begin
					if (awready) begin
						pre_awvalid <= 0;
						wstate[1] <= 0;
					end
				end
				if (wstate[2]) begin
					if (wready) begin
						pre_wvalid <= 0;
						pre_wlast <= 0;
						wstate[2] <= 0;
					end
				end
				if (wstate[3]) begin
					if (bvalid) begin
						last_write_was_succecssful <= bresp;
						bready <= 0;
						wstate[3] <= 0;
					end
				end
			end
			// read
			if (rstate[2:1]==0) begin
				if (rstate[0]==0) begin
					if (spi_read_strobe) begin
						if (spi_read_address_valid) begin
							local_spi_read_address <= spi_read_address;
							pre_arlen <= spi_read_burst_length;
							if (read_transaction_counter==0) begin
								read_transaction_counter <= spi_read_burst_length - 1'b1;
//							end else begin
//								error_count <= error_counter + 1'b1;
							end
						end else if (arburst==axi::INCR) begin
							local_spi_read_address <= local_spi_read_address + 1'b1;
							if (read_transaction_counter>=1) begin
								read_transaction_counter <= read_transaction_counter - 1'b1;
//							end else if (read_transaction_counter==0) begin
//								error_count <= error_counter + 1'b1;
							end
						end
						rstate[0] <= 1;
					end
				end else begin
					pre_araddr <= local_spi_read_address;
					pre_arvalid <= 1;
					rready <= 1;
					rstate[2:1] <= 2'b11;
				end
			end else begin
				rstate[0] <= 0;
				if (rstate[1]) begin
					if (arready) begin
						pre_arvalid <= 0;
						rstate[1] <= 0;
					end
				end
				if (rstate[2]) begin
					if (rvalid) begin
						spi_read_data <= rdata;
						rready <= 0;
						rstate[2] <= 0;
					end
				end
			end
		end
	end
	reg [7:0] error_count = 0;
	initial begin
		#0; // this is crucial for some reason
		if (awburst==axi::WRAP) begin
			$display("ERROR: %s is not supported as the axi::burst_t for awburst", awburst.name);
			error_count++;
		end
		if (arburst==axi::WRAP) begin
			$display("ERROR: %s is not supported as the axi::burst_t for arburst", arburst.name);
			error_count++;
		end
		if (error_count) begin
			#1;
			$finish;
		end
	end
endmodule

// definitions from https://en.wikipedia.org/wiki/Advanced_eXtensible_Interface
module pollable_memory__axi4_slave #(
	parameter ADDRESS_WIDTH = 4,
	parameter DATA_WIDTH = 32,
	parameter LEN_WIDTH = 5
) (
	input clock,
	input reset,
	// axi4 Write Address channel (AW)
	input [ADDRESS_WIDTH-1:0] awaddr, // Address of the first beat of the burst
	input [LEN_WIDTH-1:0] awlen, // Number of beats inside the burst
	input axi::burst_t awburst, // Type of the burst
	// awprot
	input awvalid, // xVALID handshake signal
	output reg awready = 0, // xREADY handshake signal
	// axi4 Write Data channel (W)
	input [DATA_WIDTH-1:0] wdata, // Read/Write data
	input wlast, // Last beat identifier
	// wstrb, // Byte strobe, to indicate which bytes of the WDATA signal are valid
	input wvalid, // xVALID handshake signal
	output reg wready = 0, // xREADY handshake signal
	// axi4 Write Response channel (B)
	output reg bresp = 0, // Write response, to specify the status of the burst
	output reg bvalid = 0, // xVALID handshake signal
	input bready, // xREADY handshake signal
	// axi4 Read Address channel (AR)
	input [ADDRESS_WIDTH-1:0] araddr, // Address of the first beat of the burst
	input [LEN_WIDTH-1:0] arlen, // Number of beats inside the burst
	input axi::burst_t arburst, // Type of the burst
	// arprot, // Protection type: privilege, security level and data/instruction access
	input arvalid, // xVALID handshake signal
	output reg arready = 0, // xREADY handshake signal
	// axi4 Read Data channel (R)
	output reg [DATA_WIDTH-1:0] rdata = 0, // Read/Write data
//	output reg rresp = 0, // Read response, to specify the status of the current RDATA signal
	output reg rlast = 0, // Last beat identifier
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
	reg [LEN_WIDTH-1:0] write_transaction_counter = 0;
	reg [LEN_WIDTH-1:0] read_transaction_counter = 0;
	reg pre_wlast = 0;
	reg pre_rlast = 0;
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
			write_transaction_counter <= 0;
			read_transaction_counter <= 0;
			pre_wlast <= 0;
			pre_rlast <= 0;
		end else begin
			bresp   <= pre_bresp;
			bvalid  <= pre_bvalid;
			arready <= pre_arready;
			rdata   <= pre_rdata;
//			rresp   <= pre_rresp;
			rvalid  <= pre_rvalid;
			rlast   <= pre_rlast;
			// write
			if (wstate[2]==0) begin
				if (wstate[1:0]==2'b11) begin
					mem[local_awaddr] <= local_wdata;
					pre_bresp <= 1;
					pre_bvalid <= 1;
					if (write_transaction_counter==0) begin
						pre_wlast <= 1;
					end
					wstate[2] <= 1;
				end
				if (awvalid) begin
					local_awaddr <= awaddr;
					awready <= 0;
					wstate[0] <= 1;
					if (write_transaction_counter==0) begin
						write_transaction_counter <= awlen - 1'b1;
					end else if (write_transaction_counter>=1) begin
						write_transaction_counter <= write_transaction_counter - 1'b1;
					end
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
					pre_wlast <= 0;
					awready <= 1;
					wready <= 1;
					wstate[2] <= 0;
				end
			end
			// read
			if (rstate[1]==0) begin
				if (rstate[0]==0) begin
					if (arvalid) begin
						local_araddr <= araddr;
						arready <= 0;
						rstate[0] <= 1;
						if (read_transaction_counter==0) begin
							read_transaction_counter <= arlen - 1'b1;
						end else if (read_transaction_counter>=1) begin
							read_transaction_counter <= read_transaction_counter - 1'b1;
						end
					end
				end else begin
					pre_rdata <= mem[local_araddr];
					pre_rvalid <= 1;
					if (read_transaction_counter==0) begin
						pre_rlast <= 1;
					end
					rstate[1] <= 1;
				end
			end else begin
				rstate[0] <= 0;
				if (rready) begin
					pre_rvalid <= 0;
					pre_rlast <= 0;
//					pre_rresp <= ;
					arready <= 1;
					rstate[1] <= 0;
				end
			end
		end
	end
	reg [7:0] error_count = 0;
	initial begin
		#0; // this is crucial for some reason
		error_count = 0;
		if (awburst==axi::WRAP) begin
			$display("ERROR: %s is not supported as the axi::burst_t for awburst", awburst.name);
			error_count++;
		end
		if (arburst==axi::WRAP) begin
			$display("ERROR: %s is not supported as the axi::burst_t for arburst", arburst.name);
			error_count++;
		end
		if (error_count) begin
			#1;
			$finish;
		end
	end
endmodule

module axi4_handshake (
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

