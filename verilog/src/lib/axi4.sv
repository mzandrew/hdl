// written 2021-02-12 by mza
// based off axi4lite.v
// last updated 2021-02-17 by mza

`include "lib/generic.v"
`include "lib/DebugInfoWarningError.sv"
import DebugInfoWarningError::*;

// notes:
// axi::burst_t WRAP mode is unsupported

package axi;
	typedef enum logic [2:0] { FIXED=3'b001, INCR=3'b010, WRAP=3'b100 } burst_t;
endpackage
//import axi::*;

interface axi4 #(
	parameter ADDRESS_WIDTH = 4,
	parameter DATA_WIDTH = 32,
	parameter LEN_WIDTH = 5
) (
	input clock,
	input reset
);
	// axi4 Write Address channel (AW)
	logic [ADDRESS_WIDTH-1:0] awaddr; // Address of the first beat of the burst
	logic [LEN_WIDTH-1:0] awlen; // Number of beats inside the burst
	axi::burst_t awburst; // Type of the burst
	// awprot;
	logic awvalid; // xVALID handshake signal
	logic awready; // xREADY handshake signal
	// axi4 Write Data channel (W)
	logic [DATA_WIDTH-1:0] wdata; // Read/Write data
	logic wlast; // Last beat identifier
	// wstrb; // Byte strobe, to indicate which bytes of the WDATA signal are valid
	logic wvalid; // xVALID handshake signal
	logic wready; // xREADY handshake signal
	// axi4 Write Response channel (B)
	logic bresp; // Write response, to specify the status of the burst
	logic bvalid; // xVALID handshake signal
	logic bready; // xREADY handshake signal
	// axi4 Read Address channel (AR)
	logic [ADDRESS_WIDTH-1:0] araddr; // Address of the first beat of the burst
	logic [LEN_WIDTH-1:0] arlen; // Number of beats inside the burst
	axi::burst_t arburst; // Type of the burst
	// arprot; // Protection type: privilege, security level and data/instruction access
	logic arvalid; // xVALID handshake signal
	logic arready; // xREADY handshake signal
	// axi4 Read Data channel (R)
	logic [DATA_WIDTH-1:0] rdata; // Read/Write data
	//input reg rresp; // Read response, to specify the status of the current RDATA signal
	logic rlast; // Last beat identifier
	logic rvalid; // xVALID handshake signal
	logic rready; // xREADY handshake signal
	modport controller (input clock, reset, output awaddr, awlen, awburst, awvalid, wdata, wlast, wvalid, bready, araddr, arlen, arburst, arvalid, rready,  input awready, wready, bresp, bvalid, arready, rdata, rlast, rvalid);
	modport peripheral (input clock, reset,  input awaddr, awlen, awburst, awvalid, wdata, wlast, wvalid, bready, araddr, arlen, arburst, arvalid, rready, output awready, wready, bresp, bvalid, arready, rdata, rlast, rvalid);
endinterface

module spi_peripheral_axi4_controller__pollable_memory_axi4_peripheral__tb;
	localparam ADDRESS_WIDTH = 4;
	localparam DATA_WIDTH = 32;
	localparam LEN_WIDTH = 5;
	localparam FREQUENCY_OF_CLOCK_HZ = 10000000;
	localparam PERIOD_OF_CLOCK_NS = 1000000000.0/FREQUENCY_OF_CLOCK_HZ; // WHOLE_PERIOD
	localparam DELAY_BETWEEN_TRANSACTIONS = 10*PERIOD_OF_CLOCK_NS;
	localparam DELAY_BETWEEN_BEATS = 10*PERIOD_OF_CLOCK_NS;
	wire clock;
	clock #(.FREQUENCY_OF_CLOCK_HZ(FREQUENCY_OF_CLOCK_HZ)) clockmod (.clock(clock));
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
	axi4 axi(clock, reset);
	reg [LEN_WIDTH-1:0] pre_spi_write_burst_length = 1;
	reg [LEN_WIDTH-1:0] spi_write_burst_length = 1;
	reg [LEN_WIDTH-1:0] pre_spi_read_burst_length = 1;
	reg [LEN_WIDTH-1:0] spi_read_burst_length = 1;
	spi_peripheral__axi4_controller  #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .LEN_WIDTH(LEN_WIDTH)) spac (.*);
	pollable_memory__axi4_peripheral #(.ADDRESS_WIDTH(ADDRESS_WIDTH), .DATA_WIDTH(DATA_WIDTH), .LEN_WIDTH(LEN_WIDTH)) pmap (.*);
	wire awbeat = axi.awready & axi.awvalid;
	wire arbeat = axi.arready & axi.arvalid;
	wire  wbeat =  axi.wready &  axi.wvalid;
	wire  rbeat =  axi.rready &  axi.rvalid;
	wire  bbeat =  axi.bready &  axi.bvalid;
	always @(posedge awbeat) begin $display("%t, awbeat %08x", $time, spi_write_address); end
	always @(posedge arbeat) begin $display("%t, arbeat %08x", $time, spi_read_address); end
	always @(posedge  wbeat) begin $display("%t,  wbeat %08x", $time, axi.wdata); end
	always @(posedge  rbeat) begin $display("%t,  rbeat %08x", $time, axi.rdata); end
	always @(posedge  bbeat) begin $display("%t,  bbeat", $time); end
	task automatic controller_read_transaction(input [ADDRESS_WIDTH-1:0] address, input [LEN_WIDTH:0] len);
		reg [ADDRESS_WIDTH:0] i;
		begin
			#DELAY_BETWEEN_TRANSACTIONS;
			pre_spi_read_burst_length <= len[LEN_WIDTH-1:0];
			pre_spi_read_address <= address;
			pre_spi_read_address_valid <= 1;
			for (i=0; i<len; i++) begin
				pre_spi_read_strobe <= 1;
				#PERIOD_OF_CLOCK_NS;
				pre_spi_read_strobe <= 0;
				pre_spi_read_address_valid <= 0;
				#DELAY_BETWEEN_BEATS;
			end
		end
	endtask
	task automatic controller_write_transaction(input [ADDRESS_WIDTH-1:0] address, input [LEN_WIDTH:0] len, input [DATA_WIDTH-1:0] data []);
		reg [ADDRESS_WIDTH:0] i;
		begin
			#DELAY_BETWEEN_TRANSACTIONS;
			pre_spi_write_burst_length <= len[LEN_WIDTH-1:0];
			pre_spi_write_address <= address;
			pre_spi_write_address_valid <= 1;
			for (i=0; i<len; i++) begin
				pre_spi_write_data <= data[i];
				pre_spi_write_strobe <= 1;
				#PERIOD_OF_CLOCK_NS;
				pre_spi_write_strobe <= 0;
				pre_spi_write_address_valid <= 0;
				#DELAY_BETWEEN_BEATS;
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
		data[0] = 32'h12345678; controller_write_transaction(4'h0, 19, data);
		data[0] = 32'habcdef01; controller_write_transaction(4'h1, 1, data);
		data[0] = 32'h55550000; data[1] = 32'h44bb44bb; controller_write_transaction(4'hc, 2, data);
		data[0] = 32'h00aa00aa; controller_write_transaction(4'hd, 1, data);
		controller_read_transaction(4'h0, 2);
		controller_read_transaction(4'h1, 1);
		controller_read_transaction(4'hc, 2);
		controller_read_transaction(4'hd, 1);
		controller_read_transaction(4'h0, 20);
		#200; $finish;
	end
	always @(posedge clock) begin
		if (reset) begin
			spi_write_address       <= 0;
			spi_write_address_valid <= 0;
			spi_write_data          <= 0;
			spi_write_strobe        <= 0;
			spi_write_burst_length  <= 1;
			spi_read_address       <= 0;
			spi_read_address_valid <= 0;
			spi_read_strobe        <= 0;
			spi_read_burst_length  <= 1;
		end else begin
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
	end
endmodule

module spi_peripheral__axi4_controller #(
	parameter ADDRESS_WIDTH = 4,
	parameter DATA_WIDTH = 32,
	parameter LEN_WIDTH = 5
) (
//	input clock,
//	input reset,
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
	axi4.controller axi
);
	assign axi.awburst = axi::INCR;
//	assign axi.awburst = axi::FIXED;
//	assign axi.awburst = axi::WRAP; // should fail
	assign axi.arburst = axi::INCR;
//	assign axi.arburst = axi::FIXED;
//	assign axi.arburst = 3'b101; // should fail
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
	reg [31:0] error_count = 0;
	always @(posedge axi.clock) begin
		if (axi.reset) begin
			axi.awaddr  <= 0;
			axi.awvalid <= 0;
			axi.wdata   <= 0;
			axi.wvalid  <= 0;
			axi.awlen   <= 1;
			axi.araddr  <= 0;
			axi.arvalid <= 0;
			axi.arlen   <= 1;
			axi.wlast   <= 0;
			pre_awaddr  <= 0;
			pre_awvalid <= 0;
			pre_wdata   <= 0;
			pre_wvalid  <= 0;
			pre_awlen   <= 1;
			axi.bready  <= 1;
			pre_araddr  <= 0;
			pre_arvalid <= 0;
			pre_arlen   <= 1;
			pre_wlast   <= 0;
			axi.rready  <= 0;
			wstate <= 0;
			rstate <= 0;
			last_write_was_succecssful <= 0;
			spi_read_data <= 0;
			write_transaction_counter <= 0;
			read_transaction_counter <= 0;
		end else begin
			axi.awaddr  <= pre_awaddr;
			axi.awvalid <= pre_awvalid;
			axi.wdata   <= pre_wdata;
			axi.wvalid  <= pre_wvalid;
			axi.awlen   <= pre_awlen;
			axi.araddr  <= pre_araddr;
			axi.arvalid <= pre_arvalid;
			axi.arlen   <= pre_arlen;
			axi.wlast   <= pre_wlast;
			// write
			if (wstate[3:1]==0) begin
				if (wstate[0]==0) begin
					if (spi_write_strobe) begin
						if (spi_write_address_valid) begin
							local_spi_write_address <= spi_write_address;
							pre_awlen <= spi_write_burst_length;
							if (write_transaction_counter==0) begin
								write_transaction_counter <= spi_write_burst_length - 1'b1;
							end else begin
								error_count <= error_count + 1'b1;
							end
						end else if (axi.awburst==axi::INCR) begin
							local_spi_write_address <= local_spi_write_address + 1'b1;
							if (write_transaction_counter>=1) begin
								write_transaction_counter <= write_transaction_counter - 1'b1;
							end else if (write_transaction_counter==0) begin
								error_count <= error_count + 1'b1;
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
					axi.bready <= 1;
					wstate[3:1] <= 3'b111;
				end
			end else begin
				wstate[0] <= 0;
				if (wstate[1]) begin
					if (axi.awready) begin
						pre_awvalid <= 0;
						wstate[1] <= 0;
					end
				end
				if (wstate[2]) begin
					if (axi.wready) begin
						pre_wvalid <= 0;
						pre_wlast <= 0;
						wstate[2] <= 0;
					end
				end
				if (wstate[3]) begin
					if (axi.bvalid) begin
						last_write_was_succecssful <= axi.bresp;
						axi.bready <= 0;
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
							end else begin
								error_count <= error_count + 1'b1;
							end
						end else if (axi.arburst==axi::INCR) begin
							local_spi_read_address <= local_spi_read_address + 1'b1;
							if (read_transaction_counter>=1) begin
								read_transaction_counter <= read_transaction_counter - 1'b1;
							end else if (read_transaction_counter==0) begin
								error_count <= error_count + 1'b1;
							end
						end
						rstate[0] <= 1;
					end
				end else begin
					pre_araddr <= local_spi_read_address;
					pre_arvalid <= 1;
					axi.rready <= 1;
					rstate[2:1] <= 2'b11;
				end
			end else begin
				rstate[0] <= 0;
				if (rstate[1]) begin
					if (axi.arready) begin
						pre_arvalid <= 0;
						rstate[1] <= 0;
					end
				end
				if (rstate[2]) begin
					if (axi.rvalid) begin
						spi_read_data <= axi.rdata;
						axi.rready <= 0;
						rstate[2] <= 0;
					end
				end
			end
		end
	end
	initial begin
		#0; // this is crucial for some reason
		assert (^axi.awburst!==1'bx && axi.awburst==axi::FIXED || axi.awburst==axi::INCR) else begin
			`error("%b (%s) is not supported as the axi::burst_t for awburst", axi.awburst, axi.awburst.name);
		end
		assert (^axi.arburst!==1'bx && axi.arburst==axi::FIXED || axi.arburst==axi::INCR) else begin
			`error("%b (%s) is not supported as the axi::burst_t for arburst", axi.arburst, axi.arburst.name);
		end
	end
endmodule

// definitions from https://en.wikipedia.org/wiki/Advanced_eXtensible_Interface
module pollable_memory__axi4_peripheral #(
	parameter ADDRESS_WIDTH = 4,
	parameter DATA_WIDTH = 32,
	parameter LEN_WIDTH = 5
) (
	axi4.peripheral axi
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
	always @(posedge axi.clock) begin
		if (axi.reset) begin
			axi.bresp   <= 0;
			axi.bvalid  <= 0;
			axi.arready <= 1;
			axi.rdata   <= 0;
//			axi.rresp   <= 0;
			axi.rvalid  <= 0;
			axi.rlast   <= 0;
			axi.awready <= 1;
			axi.wready  <= 1;
			pre_wlast   <= 0;
			pre_bresp   <= 0;
			pre_bvalid  <= 0;
			pre_arready <= 1;
			pre_rdata   <= 0;
//			pre_rresp   <= 0;
			pre_rvalid  <= 0;
			pre_rlast   <= 0;
			local_awaddr <= 0;
			local_wdata <= 0;
			local_araddr <= 0;
			write_transaction_counter <= 0;
			read_transaction_counter <= 0;
			wstate <= 0;
		end else begin
			axi.bresp   <= pre_bresp;
			axi.bvalid  <= pre_bvalid;
			axi.arready <= pre_arready;
			axi.rdata   <= pre_rdata;
//			axi.rresp   <= pre_rresp;
			axi.rvalid  <= pre_rvalid;
			axi.rlast   <= pre_rlast;
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
				if (axi.awvalid) begin
					local_awaddr <= axi.awaddr;
					axi.awready <= 0;
					wstate[0] <= 1;
					if (write_transaction_counter==0) begin
						write_transaction_counter <= axi.awlen - 1'b1;
					end else if (write_transaction_counter>=1) begin
						write_transaction_counter <= write_transaction_counter - 1'b1;
					end
				end
				if (axi.wvalid) begin
					local_wdata <= axi.wdata;
					axi.wready <= 0;
					wstate[1] <= 1;
				end
			end else begin
				wstate[1:0] <= 0;
				if (axi.bready) begin
					pre_bresp <= 0;
					pre_bvalid <= 0;
					pre_wlast <= 0;
					axi.awready <= 1;
					axi.wready <= 1;
					wstate[2] <= 0;
				end
			end
			// read
			if (rstate[1]==0) begin
				if (rstate[0]==0) begin
					if (axi.arvalid) begin
						local_araddr <= axi.araddr;
						axi.arready <= 0;
						rstate[0] <= 1;
						if (read_transaction_counter==0) begin
							read_transaction_counter <= axi.arlen - 1'b1;
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
				if (axi.rready) begin
					pre_rvalid <= 0;
					pre_rlast <= 0;
//					pre_rresp <= ;
					axi.arready <= 1;
					rstate[1] <= 0;
				end
			end
		end
	end
	initial begin
		#0; // this is crucial for some reason
		assert (^axi.awburst!==1'bx && axi.awburst==axi::FIXED || axi.awburst==axi::INCR) else begin
			`error("%b (%s) is not supported as the axi::burst_t for awburst", axi.awburst, axi.awburst.name);
		end
		assert (^axi.arburst!==1'bx && axi.arburst==axi::FIXED || axi.arburst==axi::INCR) else begin
			`error("%b (%s) is not supported as the axi::burst_t for arburst", axi.arburst, axi.arburst.name);
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

