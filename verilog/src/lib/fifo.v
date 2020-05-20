// last updated 2020-05-20 by mza

// from http://www.asic-world.com/code/hdl_models/syn_fifo.v
// Function    : Synchronous (single clock) FIFO
// Coder       : Deepak Kumar Tala
module syn_fifo #(
	parameter DATA_WIDTH = 8,
	parameter ADDR_WIDTH = 8
) (
	input clk, // Clock input
	input rst, // Active high reset
	input wr_cs, // Write chip select
	input rd_cs, // Read chip select
	input [DATA_WIDTH-1:0] data_in, // Data input
	input rd_en, // Read enable
	input wr_en, // Write Enable
	output [DATA_WIDTH-1:0] data_out, // Data Output
	output empty, // FIFO empty
	output full // FIFO full
);
	// FIFO constants
	parameter RAM_DEPTH = (1 << ADDR_WIDTH);
	//-----------Internal variables-------------------
	reg [ADDR_WIDTH-1:0] wr_pointer;
	reg [ADDR_WIDTH-1:0] rd_pointer;
	reg [ADDR_WIDTH :0] status_cnt;
	reg [DATA_WIDTH-1:0] data_out ;
	wire [DATA_WIDTH-1:0] data_ram ;
	//-----------Variable assignments---------------
	assign full = (status_cnt == (RAM_DEPTH-1));
	assign empty = (status_cnt == 0);
	//-----------Code Start---------------------------
	always @(posedge clk or posedge rst) begin : WRITE_POINTER
	  if (rst) begin
	    wr_pointer <= 0;
	  end else if (wr_cs && wr_en) begin
	    wr_pointer <= wr_pointer + 1;
	  end
	end
	always @(posedge clk or posedge rst) begin : READ_POINTER
	  if (rst) begin
	    rd_pointer <= 0;
	  end else if (rd_cs && rd_en) begin
	    rd_pointer <= rd_pointer + 1;
	  end
	end
	always @(posedge clk or posedge rst) begin : READ_DATA
	  if (rst) begin
	    data_out <= 0;
	  end else if (rd_cs && rd_en) begin
	    data_out <= data_ram;
	  end
	end
	always @(posedge clk or posedge rst) begin : STATUS_COUNTER
	  if (rst) begin
	    status_cnt <= 0;
	  end else if ((rd_cs && rd_en) && !(wr_cs && wr_en) && (status_cnt != 0)) begin // Read but no write.
	    status_cnt <= status_cnt - 1;
	  end else if ((wr_cs && wr_en) && !(rd_cs && rd_en) && (status_cnt != RAM_DEPTH)) begin // Write but no read.
	    status_cnt <= status_cnt + 1;
	  end
	end
	ram_dp_ar_aw #(DATA_WIDTH,ADDR_WIDTH) DP_RAM (
		.address_0 (wr_pointer) , // address_0 input
		.data_0    (data_in)    , // data_0 bi-directional
		.cs_0      (wr_cs)      , // chip select
		.we_0      (wr_en)      , // write enable
		.oe_0      (1'b0)       , // output enable
		.address_1 (rd_pointer) , // address_q input
		.data_1    (data_ram)   , // data_1 bi-directional
		.cs_1      (rd_cs)      , // chip select
		.we_1      (1'b0)       , // Read enable
		.oe_1      (rd_en)        // output enable
	);
endmodule

