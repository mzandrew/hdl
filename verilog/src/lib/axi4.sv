// written 2021-02-12 by mza
// based off axi4lite.v
// last updated 2021-02-20 by mza

`include "lib/generic.v"
`include "lib/DebugInfoWarningError.sv"
import DebugInfoWarningError::*;

// notes:
// axi::burst_t WRAP mode is unsupported

package axi;
	typedef enum logic [2:0] { FIXED=3'b001, INCR=3'b010, WRAP=3'b100 } burst_t;
	typedef enum logic [7:0] {
		               IDLE = 8'b00000000,
		WAITING_FOR_AWREADY = 8'b00000010,
		WAITING_FOR_AWVALID = 8'b00000100,
		 WAITING_FOR_WREADY = 8'b00001000,
		 WAITING_FOR_WVALID = 8'b00010000,
		 WAITING_FOR_BREADY = 8'b00100000,
		 WAITING_FOR_BVALID = 8'b01000000,
		              ERROR = 8'b11111111
	} state_t;
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
	// definitions from https://en.wikipedia.org/wiki/Advanced_eXtensible_Interface
	// axi4 Write Address channel (AW)
	logic [ADDRESS_WIDTH-1:0] awaddr; // Address of the first beat of the burst
	logic [LEN_WIDTH-1:0] awlen; // Number of beats inside the burst - 1
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
	logic [LEN_WIDTH-1:0] arlen; // Number of beats inside the burst - 1
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
	localparam DELAY_BETWEEN_TRANSACTIONS = 16*PERIOD_OF_CLOCK_NS;
	localparam DELAY_BETWEEN_WRITE_BEATS = 1*PERIOD_OF_CLOCK_NS;
	localparam DELAY_BETWEEN_BEATS = 8*PERIOD_OF_CLOCK_NS; // can't go below 2 or it fails
	localparam LONG_DELAY = 8*PERIOD_OF_CLOCK_NS;
	wire clock;
	clock #(.FREQUENCY_OF_CLOCK_HZ(FREQUENCY_OF_CLOCK_HZ)) clockmod (.clock(clock));
	reg reset = 1;
	reg [ADDRESS_WIDTH-1:0] pre_spi_write_address = 0;
	reg [ADDRESS_WIDTH-1:0] spi_write_address = 0;
	reg pre_spi_write_address_valid = 0;
	reg spi_write_address_valid = 0;
	reg [DATA_WIDTH-1:0] pre_spi_write_data = 0;
	reg [DATA_WIDTH-1:0] spi_write_data = 0;
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
	reg pre_spi_write_data_valid = 0;
	reg spi_write_data_valid = 0;
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
			#PERIOD_OF_CLOCK_NS;
			pre_spi_write_address_valid <= 0;
			for (i=0; i<len; i++) begin
				pre_spi_write_data <= data[i];
				pre_spi_write_data_valid <= 1;
				#PERIOD_OF_CLOCK_NS;
//				pre_spi_write_data_valid <= 0;
//				#DELAY_BETWEEN_WRITE_BEATS;
			end
			pre_spi_write_data_valid <= 0;
		end
	endtask
	reg [DATA_WIDTH-1:0] data [];
	reg [31:0] i = 0;
	initial begin
		#DELAY_BETWEEN_TRANSACTIONS; reset <= 0;
		data = new[2**LEN_WIDTH];
		for (i=i; i<2**LEN_WIDTH; i++) begin
			data[i] = i;
		end
		data[0] = 32'h12345678; controller_write_transaction(4'h0, 19, data);
		data[0] = 32'habcdef01; data[1] = 32'h00aa00aa; controller_write_transaction(4'h1, 1, data);
		data[0] = 32'h55550000; data[1] = 32'h44bb44bb; controller_write_transaction(4'hb, 2, data);
		data[0] = 32'hcc00cc00; data[1] = 32'hdd00dd00; data[2] = 32'hee00ee00; data[3] = 32'hff00ff00; controller_write_transaction(4'hc, 4, data);
		controller_read_transaction(4'h0, 2);
		controller_read_transaction(4'h1, 1);
		controller_read_transaction(4'hc, 2);
		controller_read_transaction(4'hd, 1);
		controller_read_transaction(4'h0, 20);
		#LONG_DELAY; $finish;
	end
	always @(posedge clock) begin
		if (reset) begin
			spi_write_address       <= 0;
			spi_write_address_valid <= 0;
			spi_write_data          <= 0;
			spi_write_burst_length  <= 1;
			spi_write_data_valid    <= 0;
			spi_read_address       <= 0;
			spi_read_address_valid <= 0;
			spi_read_strobe        <= 0;
			spi_read_burst_length  <= 1;
		end else begin
			spi_write_address       <= pre_spi_write_address;
			spi_write_address_valid <= pre_spi_write_address_valid;
			spi_write_data          <= pre_spi_write_data;
			spi_write_burst_length  <= pre_spi_write_burst_length;
			spi_write_data_valid    <= pre_spi_write_data_valid;
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
	// SPI write channel
	input [ADDRESS_WIDTH-1:0] spi_write_address,
	input spi_write_address_valid,
	input [DATA_WIDTH-1:0] spi_write_data,
	input [LEN_WIDTH-1:0] spi_write_burst_length,
	input spi_write_data_valid,
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
	reg [1:0] rstate = 0;
	reg [2:0] wstate = 0;
	reg last_write_was_succecssful = 0;
	reg [LEN_WIDTH-1:0] write_transaction_counter = 0;
	reg [LEN_WIDTH-1:0] read_transaction_counter = 0;
	reg our_rlast = 0; // our own personal copy
	axi::state_t cw_state;
	axi::state_t cr_state;
	reg [31:0] error_count = 0;
	reg [LEN_WIDTH-1:0] internal_copy_of_awlen = 0;
	always @(posedge axi.clock) begin
		if (axi.reset) begin
			axi.awaddr  <= 0;
			axi.awvalid <= 0;
			axi.wdata   <= 0;
			axi.wvalid  <= 0;
			axi.awlen   <= 0;
			axi.araddr  <= 0;
			axi.arvalid <= 0;
			axi.arlen   <= 0;
			axi.wlast   <= 0;
			axi.bready  <= 0;
			axi.rready  <= 0;
			wstate <= 0;
			rstate <= 0;
			last_write_was_succecssful <= 0;
			spi_read_data <= 0;
			write_transaction_counter <= 0;
			read_transaction_counter <= 0;
			our_rlast <= 0;
			cw_state <= axi::IDLE;
			cr_state <= axi::IDLE;
			internal_copy_of_awlen <= 0;
		end else begin
			// write
			case (cw_state)
				axi::IDLE: begin
						axi.awvalid <= 0;
						axi.wvalid <= 0;
						axi.wlast <= 0;
						axi.bready <= 0;
						if (spi_write_address_valid) begin
							axi.awaddr <= spi_write_address;
							axi.awlen <= spi_write_burst_length - 1'b1;
							internal_copy_of_awlen <= spi_write_burst_length - 1'b1;
							axi.awvalid <= 1;
							cw_state <= axi::WAITING_FOR_AWREADY;
						end
					end
				axi::WAITING_FOR_AWREADY: begin
						axi.awvalid <= 1;
						axi.wvalid <= 0;
						axi.wlast <= 0;
						axi.bready <= 0;
						if (axi.awready) begin
							cw_state <= axi::WAITING_FOR_WREADY;
							axi.awvalid <= 0;
							if (spi_write_data_valid) begin
								axi.wdata <= spi_write_data;
							end
							axi.wvalid <= 1;
							if (internal_copy_of_awlen==0) begin
								axi.wlast <= 1;
							end
						end
					end
				axi::WAITING_FOR_WREADY: begin
						axi.awvalid <= 0;
						if (spi_write_data_valid) begin
							axi.wdata <= spi_write_data;
						end
						axi.wvalid <= 1;
						if (internal_copy_of_awlen==1) begin // will be ==0 by the end of this timestep if wready is active
							axi.wlast <= 1;
						end
						axi.bready <= 0;
						if (axi.wready) begin
							if (internal_copy_of_awlen>0) begin
								internal_copy_of_awlen <= internal_copy_of_awlen - 1'b1;
							end else begin // internal_copy_of_awlen==0
								cw_state <= axi::WAITING_FOR_BVALID;
								axi.wvalid <= 0;
								axi.wlast <= 0;
								axi.bready <= 1;
							end
						end
					end
				axi::WAITING_FOR_BVALID: begin
						axi.awvalid <= 0;
						axi.wvalid <= 0;
						axi.wlast <= 0;
						axi.bready <= 0;
						if (axi.bvalid) begin
							cw_state <= axi::IDLE;
						end
					end
				default: begin
						error_count <= error_count + 1'b1;
						cw_state <= axi::IDLE;
				end
			endcase
			// read

			if (rstate==0) begin
				if (spi_read_strobe) begin
					if (spi_read_address_valid) begin
						axi.araddr <= spi_read_address;
						axi.arlen <= spi_read_burst_length - 1'b1;
						if (spi_read_burst_length==1) begin
							our_rlast <= 1;
						end
						if (read_transaction_counter!=0) begin
							error_count <= error_count + 1'b1; // previous run was not complete
						end
						read_transaction_counter <= spi_read_burst_length - 1'b1;
					end else begin
						if (read_transaction_counter>0) begin
							read_transaction_counter <= read_transaction_counter - 1'b1;
							if (read_transaction_counter==1) begin
								our_rlast <= 1;
							end
						end else begin // read_transaction_counter==0
							error_count <= error_count + 1'b1; // asking for more than the indicated run length
						end
						if (axi.arburst==axi::INCR) begin
							axi.araddr <= axi.araddr + 1'b1;
						end
					end
					axi.arvalid <= 1;
					axi.rready <= 1;
					rstate <= 2'b11;
				end
			end else begin
				if (rstate[0]) begin
					if (axi.arready) begin
						axi.arvalid <= 0;
						rstate[0] <= 0;
					end
				end
				if (rstate[1]) begin
					if (axi.rvalid) begin
						spi_read_data <= axi.rdata;
						axi.rready <= 0;
						our_rlast <= 0;
						rstate[1] <= 0;
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
	wire rbeat = axi.rready & axi.rvalid;
	wire rlast_mismatch = (axi.rlast ^ our_rlast) & rbeat;
endmodule

module pollable_memory__axi4_peripheral #(
	parameter ADDRESS_WIDTH = 4,
	parameter DATA_WIDTH = 32,
	parameter LEN_WIDTH = 5
) (
	axi4.peripheral axi
);
	reg [3:0] wstate = 0;
	reg [ADDRESS_WIDTH-1:0] local_awaddr = 0;
	reg [DATA_WIDTH-1:0] local_wdata = 0;
	reg [1:0] rstate = 0;
	reg [DATA_WIDTH-1:0] mem [2**ADDRESS_WIDTH-1:0];
	reg [LEN_WIDTH-1:0] write_transaction_counter = 0;
	reg [LEN_WIDTH-1:0] read_transaction_counter = 0;
	reg their_wlast = 0; // our own personal delayed copy
	reg [31:0] error_count = 0;
	axi::state_t pw_state;
	axi4 modified_copy(clock, reset);
	always @(posedge axi.clock) begin
		if (axi.reset) begin
			axi.arready <= 1;
			axi.rdata   <= 0;
			axi.rvalid  <= 0;
			axi.rlast   <= 0;
			their_wlast <= 0;
			local_awaddr <= 0;
			local_wdata <= 0;
			write_transaction_counter <= 0;
			read_transaction_counter <= 0;
			wstate <= 0;
			rstate <= 0;
			pw_state <= axi::WAITING_FOR_AWVALID;
			modified_copy.awaddr <= 0;
			modified_copy.awlen <= 0;
			modified_copy.wdata <= 0;
			axi.awready <= 1;
			axi.wready <= 0;
			axi.bresp <= 0;
			axi.bvalid <= 0;
		end else begin
			// write
			case (pw_state)
				axi::WAITING_FOR_AWVALID: begin
						axi.awready <= 1;
						axi.wready <= 0;
						axi.bresp <= 0;
						axi.bvalid <= 0;
						if (axi.awvalid) begin
							modified_copy.awaddr <= axi.awaddr;
							modified_copy.awlen <= axi.awlen;
							modified_copy.awburst <= axi.awburst;
							pw_state <= axi::WAITING_FOR_WVALID;
							axi.awready <= 0;
							axi.wready <= 1;
						end
					end
				axi::WAITING_FOR_WVALID: begin
						axi.awready <= 0;
						axi.wready <= 1;
						axi.bresp <= 0;
						axi.bvalid <= 0;
						if (axi.wvalid) begin
							axi.awready <= 0;
							axi.wready <= 1;
							mem[modified_copy.awaddr] <= axi.wdata;
							modified_copy.wdata <= axi.wdata;
							if (modified_copy.awlen>0) begin
								modified_copy.awlen <= modified_copy.awlen - 1'b1;
								if (modified_copy.awburst==axi::INCR) begin
									modified_copy.awaddr <= modified_copy.awaddr + 1'b1;
								end
							end else begin // modified_copy.awlen==0
								axi.wready <= 0;
								axi.bresp <= 1;
								axi.bvalid <= 1;
								pw_state <= axi::WAITING_FOR_BREADY;
							end
						end
					end
				axi::WAITING_FOR_BREADY: begin
						axi.awready <= 0;
						axi.wready <= 0;
						axi.bresp <= 1;
						axi.bvalid <= 1;
						if (axi.bready) begin
							axi.awready <= 1;
							axi.bresp <= 0;
							axi.bvalid <= 0;
							pw_state <= axi::WAITING_FOR_AWVALID;
						end
					end
				default: begin
						error_count <= error_count + 1'b1;
						pw_state <= axi::WAITING_FOR_AWVALID;
					end
			endcase
			// read
			if (rstate==0) begin
				if (axi.arvalid) begin
					axi.arready <= 0;
					axi.rdata <= mem[axi.araddr];
					axi.rvalid <= 1;
					// when axi.arlen=0; read_transaction_counter = {0}
					// when axi.arlen=1; read_transaction_counter = {0, 1}
					// when axi.arlen=3; read_transaction_counter = {0, 3, 2, 1}
					if (read_transaction_counter==0) begin
						if (axi.arlen==0) begin
							axi.rlast <= 1;
						end
						read_transaction_counter <= axi.arlen;
					end else begin
						if (read_transaction_counter==1) begin
							axi.rlast <= 1;
						end
						read_transaction_counter <= read_transaction_counter - 1'b1;
					end
					rstate[0] <= 1;
				end
			end else begin
				if (axi.rready) begin
					axi.rvalid <= 0;
					axi.rlast <= 0;
					axi.arready <= 1;
					rstate[0] <= 0;
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
//	wire wbeat = axi.wready & axi.wvalid;
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

