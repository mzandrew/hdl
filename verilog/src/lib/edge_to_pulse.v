// written 2018-07-30 by mza
// originally from file mza-test008.16-segment-driver.button-debounce-duration-counter.v
// last updated 2018-07-30 by mza

module edge_to_pulse(input clock, input polarity, input raw_input, output processed_output);
// .polarity(1) means use positive logic (detect rising edge)
	reg state;
	always @(posedge clock) begin
		processed_output <= ! polarity;
		if (raw_input==polarity) begin
			if (state!=polarity) begin
				processed_output <= polarity;
				state <= polarity;
			end
		end else begin
			state <= ! polarity;
		end
	end
endmodule // edge_to_pulse

