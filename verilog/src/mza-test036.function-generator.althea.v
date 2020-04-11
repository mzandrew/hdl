`timescale 1ns / 1ps
// written 2020-04-01 by mza
// content borrowed from mza-test017.serializer-ram.v
// content borrowed from mza-test031.clock509_and_revo_generator.althea.v
// content borrowed from mza-test032.pll_509divider_and_revo_encoder_plus_calibration_serdes.althea.v
// grabs output from XRM.py corresponding to an array from the bunch current monitor
// last updated 2020-04-10 by mza

// todo:
// implement end address
// implement start address
// implement A/B so we can write into an array while playing back the other
// implement full scatter-gather
// implement slowly rising intensity of a fixed pattern

module function_generator_althea #(
	parameter DATA_BUS_WIDTH = 8, // should correspond to corresponding oserdes input width
	parameter ADDRESS_BUS_DEPTH = 14,
	parameter NUMBER_OF_CHANNELS = 1
) (
	input local_clock50_in_p, local_clock50_in_n,
	output bit_out,
	output led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0
);
	wire [7:0] leds;
	assign { led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0 } = leds;
	wire clock50;
	IBUFDS clocky (.I(local_clock50_in_p), .IB(local_clock50_in_n), .O(clock50));
	reg reset = 1;
	wire rawclock125;
	wire pll_locked;
	simplepll_BASE #(.overall_divide(1), .multiply(10), .divide0(4), .phase0(0.0), .period(20.0)) kronos (.clockin(clock50), .reset(reset), .clock0out(rawclock125), .locked(pll_locked)); // 50->125
	assign leds[0] = pll_locked;
	wire clock; // 125 MHz
	BUFG mrt (.I(rawclock125), .O(clock));
	reg [DATA_BUS_WIDTH-1:0] data_in = 0;
	reg [ADDRESS_BUS_DEPTH-1:0] write_address = 0;
	reg write_enable = 0;
	reg initialized = 0;
	//reg [9:0] bunch_counter = 795;
	//reg [3:0] bucket_counter = 12;
	reg [9:0] outer_loop_counter = 265;
	reg [1:0] inner_loop_counter = 2;
	reg [7:0] reset_counter = 0;
	localparam PRBSWIDTH = 128;
	wire [PRBSWIDTH-1:0] rand;
	reg [PRBSWIDTH-1:0] buffered_rand = 0;
	prbs #(.WIDTH(PRBSWIDTH)) mrpibs (.clock(clock), .reset(reset), .word(rand));
	localparam ADDRESS_MAX = (2**ADDRESS_BUS_DEPTH)-1;
	always @(posedge clock50) begin
		if (reset) begin
			if (reset_counter[7]) begin
				reset <= 0;
			end
			reset_counter = reset_counter + 1'b1;
		end
	end
	reg [ADDRESS_BUS_DEPTH-1:0] counter = 0;
	always @(posedge clock) begin
		if (reset) begin
			counter <= 0;
			data_in <= 0;
			write_address <= 0;
			write_enable <= 0;
			initialized <= 0;
		end else begin
			if (!initialized) begin
				//write_enable <= 1;
				if (0) begin
					data_in <= counter;
				end else if (0) begin
//						data_in <= { counter[9:6], 4'b0000 };
					if (counter[4:0]==0) begin
						data_in <= 8'hff;
					end else if (counter[4:0]==1) begin
						data_in <= { counter[ADDRESS_BUS_DEPTH-1:ADDRESS_BUS_DEPTH-8] }; // 9:2 or 10:3
					end else if (counter[4:0]==2) begin
						data_in[7:ADDRESS_BUS_DEPTH-8] <= 0;
						data_in[ADDRESS_BUS_DEPTH-9:0] <= counter[ADDRESS_BUS_DEPTH-9:0]; // 1:0 or 2:0
						//data_in <= { (ADDRESS_BUS_DEPTH-8)'d0, counter[ADDRESS_BUS_DEPTH-9:0] }; // 1:0 or 2:0
						//data_in <= { 0, counter[ADDRESS_BUS_DEPTH-9:0] }; // 1:0 or 2:0
					end else if (counter[4:0]==3) begin
						data_in <= 8'hff;
					end else begin
						data_in <= 0;
					end
				end else if (0) begin
					// this mode helps show that there's no shenanigans between BRAM boundaries when using an array of them
					if (counter[5:0]==0) begin
//						data_in <= 8'h80;
//					end else if (counter[7:0]==1) begin
						data_in <= counter[ADDRESS_BUS_DEPTH-1:ADDRESS_BUS_DEPTH-8]; // 9:2 or 10:3 or 13:6
//					end else if (counter[4:0]==2) begin
//						data_in[7:ADDRESS_BUS_DEPTH-8] <= 0;
//					end else begin
//						data_in <= 0;
					end
				end else if (0) begin
					// this mode pulses the laser once per microsecond with a pulse width proportional to the location in ram
					data_in <= 8'h00;
					if (counter[6:0]==0) begin
						case (counter[ADDRESS_BUS_DEPTH-1:ADDRESS_BUS_DEPTH-3])
							3'd0:    data_in <= 8'b10000000;
							3'd1:    data_in <= 8'b11000000;
							3'd2:    data_in <= 8'b11100000;
							3'd3:    data_in <= 8'b11110000;
							3'd4:    data_in <= 8'b11111000;
							3'd5:    data_in <= 8'b11111100;
							3'd6:    data_in <= 8'b11111110;
							default: data_in <= 8'b11111111;
						endcase
					end
				end else if (0) begin
					// this mode drives out something like a signal that would come from the bunch current monitor
					// from 2019-11-15.075530 HER
					data_in <= 8'h00;
					if ( (counter==981) || (counter==993) || (counter==1653) || (counter==2143) || (counter==2561) || (counter==3087) || (counter==3161) || (counter==3921) || (counter==4729) || (counter==5157) || (counter==5881) || (counter==6567) || (counter==8391) || (counter==8857) || (counter==9175) || (counter==9421) || (counter==9481) ) begin
						data_in <= 8'b11100000;
					end else if ( (counter==1) || (counter==13) || (counter==25) || (counter==37) || (counter==49) || (counter==61) || (counter==85) || (counter==99) || (counter==111) || (counter==123) || (counter==135) || (counter==147) || (counter==159) || (counter==171) || (counter==183) || (counter==197) || (counter==209) || (counter==221) || (counter==245) || (counter==257) || (counter==269) || (counter==281) || (counter==295) || (counter==307) || (counter==319) || (counter==343) || (counter==355) || (counter==367) || (counter==379) || (counter==393) || (counter==405) || (counter==429) || (counter==441) || (counter==453) || (counter==465) || (counter==477) || (counter==491) || (counter==503) || (counter==515) || (counter==527) || (counter==563) || (counter==575) || (counter==601) || (counter==613) || (counter==625) || (counter==637) || (counter==661) || (counter==673) || (counter==687) || (counter==699) || (counter==723) || (counter==735) || (counter==747) || (counter==759) || (counter==771) || (counter==785) || (counter==797) || (counter==809) || (counter==821) || (counter==833) || (counter==845) || (counter==857) || (counter==895) || (counter==919) || (counter==931) || (counter==943) || (counter==967) || (counter==1029) || (counter==1041) || (counter==1053) || (counter==1065) || (counter==1079) || (counter==1091) || (counter==1103) || (counter==1115) || (counter==1139) || (counter==1151) || (counter==1163) || (counter==1177) || (counter==1189) || (counter==1201) || (counter==1213) || (counter==1225) || (counter==1237) || (counter==1249) || (counter==1261) || (counter==1275) || (counter==1287) || (counter==1299) || (counter==1311) || (counter==1323) || (counter==1335) || (counter==1347) || (counter==1373) || (counter==1385) || (counter==1397) || (counter==1421) || (counter==1445) || (counter==1471) || (counter==1483) || (counter==1495) || (counter==1507) || (counter==1519) || (counter==1531) || (counter==1543) || (counter==1569) || (counter==1581) || (counter==1593) || (counter==1605) || (counter==1617) || (counter==1629) || (counter==1641) || (counter==1667) || (counter==1679) || (counter==1691) || (counter==1703) || (counter==1715) || (counter==1727) || (counter==1739) || (counter==1751) || (counter==1765) || (counter==1777) || (counter==1789) || (counter==1813) || (counter==1837) || (counter==1849) || (counter==1863) || (counter==1875) || (counter==1887) || (counter==1899) || (counter==1911) || (counter==1923) || (counter==1947) || (counter==1961) || (counter==1973) || (counter==1985) || (counter==2009) || (counter==2021) || (counter==2033) || (counter==2045) || (counter==2059) || (counter==2071) || (counter==2083) || (counter==2095) || (counter==2107) || (counter==2119) || (counter==2131) || (counter==2157) || (counter==2169) || (counter==2181) || (counter==2193) || (counter==2205) || (counter==2217) || (counter==2229) || (counter==2241) || (counter==2255) || (counter==2267) || (counter==2279) || (counter==2291) || (counter==2303) || (counter==2327) || (counter==2339) || (counter==2353) || (counter==2365) || (counter==2377) || (counter==2401) || (counter==2413) || (counter==2425) || (counter==2437) || (counter==2451) || (counter==2463) || (counter==2475) || (counter==2487) || (counter==2499) || (counter==2511) || (counter==2523) || (counter==2535) || (counter==2549) || (counter==2573) || (counter==2585) || (counter==2597) || (counter==2621) || (counter==2633) || (counter==2647) || (counter==2659) || (counter==2671) || (counter==2683) || (counter==2695) || (counter==2707) || (counter==2719) || (counter==2731) || (counter==2745) || (counter==2757) || (counter==2769) || (counter==2781) || (counter==2793) || (counter==2805) || (counter==2817) || (counter==2829) || (counter==2843) || (counter==2855) || (counter==2879) || (counter==2891) || (counter==2903) || (counter==2915) || (counter==2927) || (counter==2953) || (counter==2965) || (counter==2977) || (counter==2989) || (counter==3025) || (counter==3039) || (counter==3051) || (counter==3063) || (counter==3075) || (counter==3099) || (counter==3111) || (counter==3123) || (counter==3137) || (counter==3173) || (counter==3185) || (counter==3197) || (counter==3209) || (counter==3221) || (counter==3235) || (counter==3247) || (counter==3259) || (counter==3271) || (counter==3283) || (counter==3295) || (counter==3307) || (counter==3319) || (counter==3333) || (counter==3345) || (counter==3357) || (counter==3369) || (counter==3381) || (counter==3393) || (counter==3417) || (counter==3431) || (counter==3443) || (counter==3455) || (counter==3467) || (counter==3479) || (counter==3491) || (counter==3503) || (counter==3529) || (counter==3541) || (counter==3553) || (counter==3565) || (counter==3577) || (counter==3613) || (counter==3627) || (counter==3651) || (counter==3663) || (counter==3675) || (counter==3687) || (counter==3711) || (counter==3725) || (counter==3737) || (counter==3749) || (counter==3761) || (counter==3773) || (counter==3785) || (counter==3809) || (counter==3823) || (counter==3835) || (counter==3859) || (counter==3871) || (counter==3883) || (counter==3895) || (counter==3907) || (counter==3933) || (counter==3945) || (counter==3957) || (counter==3969) || (counter==3981) || (counter==3993) || (counter==4005) || (counter==4019) || (counter==4043) || (counter==4055) || (counter==4067) || (counter==4079) || (counter==4091) || (counter==4103) || (counter==4117) || (counter==4129) || (counter==4141) || (counter==4153) || (counter==4165) || (counter==4177) || (counter==4201) || (counter==4215) || (counter==4227) || (counter==4239) || (counter==4251) || (counter==4263) || (counter==4275) || (counter==4287) || (counter==4299) || (counter==4313) || (counter==4325) || (counter==4337) || (counter==4361) || (counter==4373) || (counter==4385) || (counter==4397) || (counter==4411) || (counter==4423) || (counter==4435) || (counter==4447) || (counter==4459) || (counter==4471) || (counter==4483) || (counter==4495) || (counter==4509) || (counter==4521) || (counter==4533) || (counter==4545) || (counter==4557) || (counter==4569) || (counter==4581) || (counter==4593) || (counter==4607) || (counter==4619) || (counter==4631) || (counter==4643) || (counter==4655) || (counter==4667) || (counter==4679) || (counter==4691) || (counter==4705) || (counter==4717) || (counter==4741) || (counter==4753) || (counter==4765) || (counter==4777) || (counter==4789) || (counter==4803) || (counter==4815) || (counter==4839) || (counter==4851) || (counter==5133) || (counter==5145) || (counter==5169) || (counter==5207) || (counter==5219) || (counter==5231) || (counter==5243) || (counter==5267) || (counter==5279) || (counter==5317) || (counter==5329) || (counter==5353) || (counter==5365) || (counter==5377) || (counter==5391) || (counter==5403) || (counter==5415) || (counter==5427) || (counter==5439) || (counter==5451) || (counter==5463) || (counter==5475) || (counter==5489) || (counter==5501) || (counter==5513) || (counter==5549) || (counter==5561) || (counter==5573) || (counter==5587) || (counter==5599) || (counter==5611) || (counter==5623) || (counter==5635) || (counter==5647) || (counter==5659) || (counter==5671) || (counter==5697) || (counter==5721) || (counter==5733) || (counter==5757) || (counter==5769) || (counter==5783) || (counter==5795) || (counter==5819) || (counter==5831) || (counter==5855) || (counter==5867) || (counter==5893) || (counter==5905) || (counter==5917) || (counter==5929) || (counter==5953) || (counter==5965) || (counter==5991) || (counter==6003) || (counter==6015) || (counter==6027) || (counter==6039) || (counter==6063) || (counter==6077) || (counter==6089) || (counter==6101) || (counter==6113) || (counter==6137) || (counter==6161) || (counter==6175) || (counter==6187) || (counter==6199) || (counter==6211) || (counter==6223) || (counter==6247) || (counter==6259) || (counter==6273) || (counter==6285) || (counter==6297) || (counter==6309) || (counter==6321) || (counter==6345) || (counter==6357) || (counter==6371) || (counter==6383) || (counter==6395) || (counter==6407) || (counter==6419) || (counter==6431) || (counter==6443) || (counter==6455) || (counter==6469) || (counter==6481) || (counter==6493) || (counter==6505) || (counter==6529) || (counter==6541) || (counter==6553) || (counter==6579) || (counter==6591) || (counter==6603) || (counter==6615) || (counter==6627) || (counter==6639) || (counter==6651) || (counter==6665) || (counter==6677) || (counter==6689) || (counter==6701) || (counter==6713) || (counter==6725) || (counter==6737) || (counter==6749) || (counter==6763) || (counter==6775) || (counter==6787) || (counter==6799) || (counter==6811) || (counter==6823) || (counter==6835) || (counter==6861) || (counter==6873) || (counter==6885) || (counter==6897) || (counter==6921) || (counter==6933) || (counter==6945) || (counter==6959) || (counter==6971) || (counter==6983) || (counter==6995) || (counter==7007) || (counter==7019) || (counter==7031) || (counter==7043) || (counter==7057) || (counter==7069) || (counter==7081) || (counter==7093) || (counter==7105) || (counter==7129) || (counter==7141) || (counter==7179) || (counter==7203) || (counter==7215) || (counter==7227) || (counter==7239) || (counter==7253) || (counter==7265) || (counter==7277) || (counter==7289) || (counter==7301) || (counter==7325) || (counter==7337) || (counter==7351) || (counter==7363) || (counter==7375) || (counter==7387) || (counter==7399) || (counter==7411) || (counter==7423) || (counter==7435) || (counter==7449) || (counter==7461) || (counter==7473) || (counter==7485) || (counter==7497) || (counter==7509) || (counter==7521) || (counter==7533) || (counter==7547) || (counter==7559) || (counter==7571) || (counter==7583) || (counter==7595) || (counter==7607) || (counter==7619) || (counter==7631) || (counter==7645) || (counter==7657) || (counter==7669) || (counter==7681) || (counter==7693) || (counter==7717) || (counter==7729) || (counter==7743) || (counter==7755) || (counter==7767) || (counter==7779) || (counter==7803) || (counter==7815) || (counter==7827) || (counter==7841) || (counter==7853) || (counter==7865) || (counter==7877) || (counter==7889) || (counter==7913) || (counter==7925) || (counter==7939) || (counter==7951) || (counter==7963) || (counter==7975) || (counter==7987) || (counter==7999) || (counter==8011) || (counter==8023) || (counter==8037) || (counter==8049) || (counter==8061) || (counter==8073) || (counter==8085) || (counter==8097) || (counter==8135) || (counter==8147) || (counter==8159) || (counter==8171) || (counter==8183) || (counter==8195) || (counter==8207) || (counter==8219) || (counter==8233) || (counter==8245) || (counter==8257) || (counter==8269) || (counter==8281) || (counter==8305) || (counter==8317) || (counter==8355) || (counter==8367) || (counter==8379) || (counter==8403) || (counter==8415) || (counter==8429) || (counter==8441) || (counter==8453) || (counter==8465) || (counter==8477) || (counter==8501) || (counter==8513) || (counter==8539) || (counter==8551) || (counter==8563) || (counter==8587) || (counter==8599) || (counter==8611) || (counter==8625) || (counter==8637) || (counter==8661) || (counter==8673) || (counter==8685) || (counter==8697) || (counter==8709) || (counter==8723) || (counter==8735) || (counter==8747) || (counter==8759) || (counter==8771) || (counter==8795) || (counter==8807) || (counter==8821) || (counter==8833) || (counter==8845) || (counter==8869) || (counter==8881) || (counter==8893) || (counter==8919) || (counter==8931) || (counter==8943) || (counter==8967) || (counter==8979) || (counter==8991) || (counter==9003) || (counter==9017) || (counter==9029) || (counter==9041) || (counter==9065) || (counter==9089) || (counter==9101) || (counter==9115) || (counter==9127) || (counter==9139) || (counter==9151) || (counter==9163) || (counter==9187) || (counter==9199) || (counter==9213) || (counter==9225) || (counter==9237) || (counter==9249) || (counter==9261) || (counter==9273) || (counter==9285) || (counter==9297) || (counter==9311) || (counter==9323) || (counter==9335) || (counter==9347) || (counter==9359) || (counter==9371) || (counter==9383) || (counter==9395) || (counter==9409) || (counter==9433) || (counter==9445) || (counter==9469) || (counter==9493) || (counter==9507) || (counter==9519) || (counter==9531) || (counter==9543) || (counter==9555) || (counter==9567) || (counter==9579) || (counter==9591) || (counter==9605) || (counter==9617) || (counter==9629) || (counter==9641) || (counter==9665) || (counter==9677) || (counter==9689) || (counter==9715) || (counter==9727) || (counter==9739) || (counter==9751) || (counter==9763) || (counter==9775) || (counter==9787) || (counter==9801) || (counter==9813) || (counter==9825) || (counter==9837) || (counter==9849) || (counter==9861) || (counter==9873) || (counter==9885) || (counter==9899) || (counter==9911) || (counter==9923) || (counter==9935) || (counter==9947) || (counter==9959) || (counter==9971) ) begin
						data_in <= 8'b11110000;
					end else if ( (counter==73) || (counter==233) || (counter==331) || (counter==417) || (counter==539) || (counter==551) || (counter==589) || (counter==649) || (counter==711) || (counter==869) || (counter==883) || (counter==907) || (counter==955) || (counter==1005) || (counter==1017) || (counter==1127) || (counter==1359) || (counter==1409) || (counter==1433) || (counter==1457) || (counter==1555) || (counter==1801) || (counter==1825) || (counter==1935) || (counter==1997) || (counter==2315) || (counter==2389) || (counter==2609) || (counter==2867) || (counter==2941) || (counter==3001) || (counter==3013) || (counter==3149) || (counter==3405) || (counter==3515) || (counter==3589) || (counter==3601) || (counter==3639) || (counter==3699) || (counter==3797) || (counter==3847) || (counter==4031) || (counter==4189) || (counter==4349) || (counter==4827) || (counter==5121) || (counter==5181) || (counter==5195) || (counter==5255) || (counter==5293) || (counter==5305) || (counter==5341) || (counter==5525) || (counter==5537) || (counter==5685) || (counter==5709) || (counter==5745) || (counter==5807) || (counter==5843) || (counter==5941) || (counter==5979) || (counter==6051) || (counter==6125) || (counter==6149) || (counter==6235) || (counter==6333) || (counter==6517) || (counter==6847) || (counter==6909) || (counter==7117) || (counter==7155) || (counter==7167) || (counter==7191) || (counter==7313) || (counter==7705) || (counter==7791) || (counter==7901) || (counter==8109) || (counter==8121) || (counter==8293) || (counter==8331) || (counter==8343) || (counter==8489) || (counter==8527) || (counter==8575) || (counter==8649) || (counter==8783) || (counter==8905) || (counter==8955) || (counter==9053) || (counter==9077) || (counter==9457) || (counter==9653) || (counter==9703) ) begin
						data_in <= 8'b11111000;
					end else if ( (counter==9989) ) begin
						data_in <= 8'b11111111;
					end
//				end else if (0) begin
//					// this mode drives out something like a signal that would come from the bunch current monitor
//					// from 2019-11-15.075530 HER (but simplified/compressed)
//					data_in <= 8'h00;
//					if (bunch_counter) begin
//						if (bucket_counter) begin
//							bucket_counter <= bucket_counter - 1;
//						end else begin
//							data_in <= 8'b10000000;
//							bucket_counter <= 4'd12;
//							bunch_counter <= bunch_counter - 1;
//						end
//					end
				end else if (0) begin
					// this mode drives out something like a signal that would come from the bunch current monitor
					// from 2019-11-15.075530 HER (but simplified/compressed)
					data_in <= 8'h00;
					if (outer_loop_counter) begin
						if (inner_loop_counter==2) begin
							inner_loop_counter <= inner_loop_counter - 1'b1;
							data_in <= 8'b10000000;
						end else if (inner_loop_counter==1) begin
							inner_loop_counter <= inner_loop_counter - 1'b1;
							data_in <= 8'b00001000;
						end else begin
							data_in <= 8'b00000000;
							inner_loop_counter <= 2'd2;
							outer_loop_counter <= outer_loop_counter - 1'b1;
						end
					end
				end else if (0) begin
					data_in <= 8'h00;
				end else if (0) begin
					// this mode drives out something like a single pilot bunch
					// from 2019-11-15.072853 HER
					data_in <= 8'h00;
					if (counter==9989) begin
						data_in <= 8'b11111111;
					end
				end else if (0) begin
					// this mode drives out only something during the abort gaps
				end else begin
					data_in <= buffered_rand[7:0];
					buffered_rand <= rand;
				end
				if (ADDRESS_MAX==counter) begin
					initialized <= 1;
				end
				write_address <= counter;
				counter <= counter + 1'b1;
			end else begin
				data_in <= 0;
				write_address <= 0;
				write_enable <= 0;
			end
		end
	end
	wire [7:0] data_out;
//	assign leds = data_out;
	function_generator #(
		.DATA_BUS_WIDTH(DATA_BUS_WIDTH),
		.ADDRESS_BUS_DEPTH(ADDRESS_BUS_DEPTH),
		.NUMBER_OF_CHANNELS(NUMBER_OF_CHANNELS)
	) fg (
		.clock(clock),
		.reset(reset),
		.channel(2'd1),
		.write_address(write_address),
		.data_in(data_in),
		.write_enable(write_enable),
		.data_out(data_out)
//		.output_0(led_0), .output_1(led_1), .output_2(led_2), .output_3(led_3),
//		.output_4(led_4), .output_5(led_5), .output_6(led_6), .output_7(led_7)
	);
	wire oserdes_pll_locked;
	ocyrus_single8 #(.BIT_DEPTH(8), .PERIOD(20.0), .DIVIDE(1), .MULTIPLY(8), .SCOPE("BUFPLL"), .MODE("WORD_CLOCK_IN"), .PHASE(0.0)) single (.clock_in(clock), .reset(reset), .word_clock_out(), .word_in(data_out), .D_out(bit_out), .locked(oserdes_pll_locked));
	assign leds[1] = oserdes_pll_locked;
	assign leds[7:2] = 5'd0;
endmodule

module function_generator_althea_tb;
	reg clock50_p = 0;
	reg clock50_n = 0;
	wire lemo;
	wire led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0;
	function_generator_althea #(
		.DATA_BUS_WIDTH(8), // should correspond to corresponding oserdes input width
		.ADDRESS_BUS_DEPTH(14),
		.NUMBER_OF_CHANNELS(1)
	) fga (
		.local_clock50_in_p(clock50_p), .local_clock50_in_n(clock50_n),
		.bit_out(lemo),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
	initial begin
		clock50_p <= 0; clock50_n <= 1;
	end
	always begin
		#10;
		clock50_p = ~clock50_p;
		clock50_n = ~clock50_n;
	end
endmodule

//module mza_test036_function_generator_althea (
module althea (
	input clock50_p, clock50_n,
//	input a_p, a_n,
//	output b_p, b_n,
//	input c_p, c_n,
//	output d_p, d_n,
//	output e_p, e_n,
//	output f_p, f_n,
//	input g_p, g_n,
//	input h_p, h_n,
//	input j_p, j_n,
//	input k_p, k_n,
//	output l_p, l_n,
	output lemo,
	output led_7, led_6, led_5, led_4, led_3, led_2, led_1, led_0
);
	function_generator_althea #(
		.DATA_BUS_WIDTH(8), // should correspond to corresponding oserdes input width
		.ADDRESS_BUS_DEPTH(14),
		.NUMBER_OF_CHANNELS(1)
	) fga (
		.local_clock50_in_p(clock50_p), .local_clock50_in_n(clock50_n),
//		.local_clock509_in_p(j_p), .local_clock509_in_n(j_n),
//		.remote_clock509_in_p(k_p), .remote_clock509_in_n(k_n),
//		.remote_revo_in_p(h_p), .remote_revo_in_n(h_n),
//		.ack12_p(a_p), .ack12_n(a_n),
//		.trg36_p(f_p), .trg36_n(f_n),
//		.rsv54_p(c_p), .rsv54_n(c_n),
//		.clk78_p(d_p), .clk78_n(d_n),
//		.out1_p(e_p), .out1_n(e_n),
//		.outa_p(b_p), .outa_n(b_n),
		.bit_out(lemo),
//		.led_revo(l_n),
//		.led_rfclock(l_p),
//		.driven_high(g_p), .clock_select(g_n),
		.led_0(led_0), .led_1(led_1), .led_2(led_2), .led_3(led_3),
		.led_4(led_4), .led_5(led_5), .led_6(led_6), .led_7(led_7)
	);
endmodule

