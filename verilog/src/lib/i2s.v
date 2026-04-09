// written 2024-12-03 by mza
// last updated 2024-12-12 by mza

`ifndef I2S_LIB
`define I2S_LIB

module fake_i2s_controller #(
	parameter RATIO_OF_WORD_STROBE_TO_BCLK = 64,
	parameter NUMBER_OF_BITS_OF_DATA = 24,
	parameter NUMBER_OF_MEANINGFUL_BITS_OF_DATA = 18
) (
	input word_clock, bit_clock, sample_clock,
	input device_data_out,
	output device_bclk,
	output reg device_word_strobe = 0
);
	assign device_bclk = bit_clock;
	always @(negedge bit_clock) begin
		device_word_strobe <= sample_clock;
	end
endmodule

// common to i2s devices:
// a 10-100 kOhm resistor to GND should be on the data line
// ratio of device_bclk to device_ws is 64
// device_word_strobe is supposed to change on the falling edge of device_bclk
// specific to SPH0645LM4H-B datasheet:
// pin names are clk/bclk, ws, data
// MSB of device_data_out starts on the rising edge of device_bclk after that according to the timing diagram on page 7
// device_data_out shows up 65.92 ns at most after device_bclk
// device_bclk can by 2.048 to 4.096 MHz (32 to 64 kSa/sec)
// specific to ICS-43434 datasheet:
// pin names are sck, ws, sd
// 0.4 to 3.3 MHz (3.125 to 51.563 kSa/sec)
// left channel data comes out when device_ws=0
// timing diagram on page 13 suggests the delay between ws falling and data needing to be valid is 1.5 sck cycles
module fake_i2s_device #(
	parameter WS_PIPELINE_PICKOFF = 1,
	parameter NUMBER_OF_BIT_BUCKETS_PER_CHANNEL = 32,
	parameter NUMBER_OF_BIT_BUCKETS_PER_CHANNEL_MINUS_TWO = NUMBER_OF_BIT_BUCKETS_PER_CHANNEL - 2,
	parameter LOG2_OF_NUMBER_OF_BIT_BUCKETS_PER_CHANNEL = $clog2(NUMBER_OF_BIT_BUCKETS_PER_CHANNEL),
	parameter NUMBER_OF_BITS_PER_CHANNEL = 24,
	parameter N = NUMBER_OF_BIT_BUCKETS_PER_CHANNEL - NUMBER_OF_BITS_PER_CHANNEL - 1,
	parameter NUMBER_OF_MEANINGFUL_BITS_PER_CHANNEL = 18
) (
	input [NUMBER_OF_MEANINGFUL_BITS_PER_CHANNEL-1:0] sample,
	input bclk, ws, sel,
	output data
);
	wire [NUMBER_OF_BIT_BUCKETS_PER_CHANNEL-1:0] extended_sample = { sample, {NUMBER_OF_BIT_BUCKETS_PER_CHANNEL-NUMBER_OF_MEANINGFUL_BITS_PER_CHANNEL{1'b0}} };
	reg [WS_PIPELINE_PICKOFF:0] ws_pipeline = 0;
	reg [LOG2_OF_NUMBER_OF_BIT_BUCKETS_PER_CHANNEL-1:0] counter = 0;
	wire mode = ws;
	always @(posedge bclk) begin
		counter <= counter - 1'b1;
		if (ws_pipeline[WS_PIPELINE_PICKOFF-:2]==2'b10) begin
			counter <= NUMBER_OF_BIT_BUCKETS_PER_CHANNEL_MINUS_TWO;
		end else if (ws_pipeline[WS_PIPELINE_PICKOFF-:2]==2'b01) begin
			counter <= NUMBER_OF_BIT_BUCKETS_PER_CHANNEL_MINUS_TWO;
		end
		ws_pipeline <= { ws_pipeline[WS_PIPELINE_PICKOFF-1:0], ws };
	end
	assign data = (sel==mode) && (N<counter) ? extended_sample[counter] : 1'bz;
endmodule

module i2s_controller_tb #(
	parameter BIT_CLOCK_FREQUENCY_MHZ = 3.072, // 2.048, 3.072, 4.096
	parameter BIT_CLOCK_PERIOD_NS = 1000.0/BIT_CLOCK_FREQUENCY_MHZ, // 488.28, 325.52, 244.14
	parameter HALF_BIT_CLOCK_PERIOD_NS = BIT_CLOCK_PERIOD_NS/2,
	parameter N = 64,
	parameter SAMPLE_CLOCK_PERIOD_NS = BIT_CLOCK_PERIOD_NS * N, // 31250.0, 20833.33, 15625.0
	parameter SAMPLE_CLOCK_FREQUNCY_KHZ = 1000000.0 / SAMPLE_CLOCK_PERIOD_NS, // 32.0, 48.0, 64.0
	parameter HALF_SAMPLE_CLOCK_PERIOD_NS = SAMPLE_CLOCK_PERIOD_NS/2,
	parameter ISERDES_WIDTH = 8,
	parameter WORD_CLOCK_PERIOD_NS = BIT_CLOCK_PERIOD_NS * ISERDES_WIDTH, // 3906.25, 2604.166, 1953.125
	parameter HALF_WORD_CLOCK_PERIOD_NS = WORD_CLOCK_PERIOD_NS/2
) ();
	reg word_clock = 0, bit_clock = 0, sample_clock = 0;
	always begin word_clock   <= ~word_clock;   #HALF_WORD_CLOCK_PERIOD_NS;   end
	always begin sample_clock <= ~sample_clock; #HALF_SAMPLE_CLOCK_PERIOD_NS; end
	always begin bit_clock    <= ~bit_clock;    #HALF_BIT_CLOCK_PERIOD_NS;    end
	reg [17:0] pre_left = 0, pre_right = 0;
	reg [17:0] left = 0, right = 0;
	always @(posedge sample_clock) begin
		left <= pre_left;
		right <= pre_right;
	end
	initial begin
		#(1*SAMPLE_CLOCK_PERIOD_NS);
		pre_left <= 18'h00000; pre_right <= 18'h00000; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h00000; pre_right <= 18'h3f000; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h3f000; pre_right <= 18'h00000; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h00000; pre_right <= 18'h00000; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h3f000; pre_right <= 18'h3f000; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h00000; pre_right <= 18'h00000; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h33210; pre_right <= 18'h33210; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h01234; pre_right <= 18'h01234; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h3ffff; pre_right <= 18'h3ffff; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h2aaaa; pre_right <= 18'h2aaaa; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h15555; pre_right <= 18'h15555; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'hbbbbb; pre_right <= 18'hddddd; #SAMPLE_CLOCK_PERIOD_NS;
		pre_left <= 18'h00000; pre_right <= 18'h00000; #SAMPLE_CLOCK_PERIOD_NS;
		#(1*SAMPLE_CLOCK_PERIOD_NS);
		$finish;
	end
	wire device_bclk, device_word_strobe, device_data_out;
	fake_i2s_controller c (.word_clock(word_clock), .bit_clock(bit_clock), .sample_clock(sample_clock), .device_bclk(device_bclk), .device_word_strobe(device_word_strobe), .device_data_out(device_data_out));
	fake_i2s_device l (.sample(left),  .sel(1'b0), .bclk(device_bclk), .ws(device_word_strobe), .data(device_data_out));
	fake_i2s_device r (.sample(right), .sel(1'b1), .bclk(device_bclk), .ws(device_word_strobe), .data(device_data_out));
	initial begin
		$display("BIT_CLOCK_FREQUENCY_MHZ=%f", BIT_CLOCK_FREQUENCY_MHZ);
		$display("BIT_CLOCK_PERIOD_NS=%f", BIT_CLOCK_PERIOD_NS);
		$display("N=%d", N);
		$display("SAMPLE_CLOCK_PERIOD_NS=%f", SAMPLE_CLOCK_PERIOD_NS);
		$display("SAMPLE_CLOCK_FREQUNCY_KHZ=%f", SAMPLE_CLOCK_FREQUNCY_KHZ);
		$display("ISERDES_WIDTH=%d", ISERDES_WIDTH);
		$display("WORD_CLOCK_PERIOD_NS=%f", WORD_CLOCK_PERIOD_NS);
	end
endmodule

`endif

