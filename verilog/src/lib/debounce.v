// written 2018-07-27 by mza
// originally from file mza-test008.16-segment-driver.button-debounce-duration-counter.v
// last updated 2018-07-30 by mza

module debounce(input clock, input polarity, input raw_button_input, output button_active);
	localparam timeout = 120000; // 10ms
	reg [$clog2(timeout)+1:0] counter;
	reg old_status = 0;
	reg new_status = 0;
	always @(posedge clock) begin
		if (counter==0) begin // idle, so time to check raw_button_input...
			if (raw_button_input==polarity) begin
				new_status <= 1; // raw_button_input is active
				if (old_status==0) begin // old_status != new_status, so act, then implement delay before checking again
					counter <= timeout;
					button_active <= 1;
				end
			end else begin
				new_status <= 0; // raw_button_input is inactive
				if (old_status==1) begin // old_status != new_status, so implement delay before checking again
					counter <= timeout;
					button_active <= 0;
				end
			end
		end else begin
			counter--;
			button_active <= new_status;
		end
		old_status <= new_status;
	end
endmodule // debounce

