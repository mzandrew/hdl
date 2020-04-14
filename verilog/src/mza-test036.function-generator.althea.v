`timescale 1ns / 1ps
// written 2020-04-01 by mza
// content borrowed from mza-test017.serializer-ram.v
// content borrowed from mza-test031.clock509_and_revo_generator.althea.v
// content borrowed from mza-test032.pll_509divider_and_revo_encoder_plus_calibration_serdes.althea.v
// grabs output from XRM.py corresponding to an array from the bunch current monitor
// last updated 2020-04-13 by mza

// todo:
// implement A/B so we can write into an array while playing back the other
// implement full scatter-gather
// implement slowly rising intensity of a fixed pattern

`define RF_BUCKETS 5120 // set by accelerator geometry/parameters
`define REVOLUTIONS 9 // set by FTSW/TOP firmware
`define BITS_PER_WORD 8 // matches oserdes input width
`define SCALING 2 // off-between-on functionality (@1GHz)

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
				write_enable <= 1;
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
				end else if (1) begin
					data_in <= 8'h00;
					if ( (counter==0) || (counter==3) || (counter==6) || (counter==9) || (counter==26) || (counter==29) || (counter==32) || (counter==35) || (counter==49) || (counter==52) || (counter==55) || (counter==58) || (counter==75) || (counter==78) || (counter==81) || (counter==84) || (counter==98) || (counter==101) || (counter==104) || (counter==107) || (counter==124) || (counter==127) || (counter==130) || (counter==133) || (counter==147) || (counter==150) || (counter==153) || (counter==156) || (counter==173) || (counter==176) || (counter==179) || (counter==182) || (counter==196) || (counter==199) || (counter==202) || (counter==205) || (counter==222) || (counter==225) || (counter==228) || (counter==231) || (counter==245) || (counter==248) || (counter==251) || (counter==254) || (counter==271) || (counter==274) || (counter==277) || (counter==280) || (counter==294) || (counter==297) || (counter==300) || (counter==303) || (counter==320) || (counter==323) || (counter==326) || (counter==329) || (counter==343) || (counter==346) || (counter==349) || (counter==352) || (counter==369) || (counter==372) || (counter==375) || (counter==378) || (counter==392) || (counter==395) || (counter==398) || (counter==401) || (counter==418) || (counter==421) || (counter==424) || (counter==427) || (counter==441) || (counter==444) || (counter==447) || (counter==450) || (counter==467) || (counter==470) || (counter==473) || (counter==476) || (counter==490) || (counter==493) || (counter==496) || (counter==499) || (counter==516) || (counter==519) || (counter==522) || (counter==525) || (counter==539) || (counter==542) || (counter==545) || (counter==548) || (counter==565) || (counter==568) || (counter==571) || (counter==574) || (counter==588) || (counter==591) || (counter==594) || (counter==597) || (counter==640) || (counter==643) || (counter==646) || (counter==663) || (counter==666) || (counter==669) || (counter==672) || (counter==686) || (counter==689) || (counter==692) || (counter==695) || (counter==712) || (counter==715) || (counter==718) || (counter==721) || (counter==735) || (counter==738) || (counter==741) || (counter==744) || (counter==761) || (counter==764) || (counter==767) || (counter==770) || (counter==784) || (counter==787) || (counter==790) || (counter==793) || (counter==810) || (counter==813) || (counter==816) || (counter==819) || (counter==833) || (counter==836) || (counter==839) || (counter==842) || (counter==859) || (counter==862) || (counter==865) || (counter==868) || (counter==882) || (counter==885) || (counter==888) || (counter==891) || (counter==908) || (counter==911) || (counter==914) || (counter==917) || (counter==931) || (counter==934) || (counter==937) || (counter==940) || (counter==957) || (counter==960) || (counter==963) || (counter==966) || (counter==980) || (counter==983) || (counter==986) || (counter==989) || (counter==1006) || (counter==1009) || (counter==1012) || (counter==1015) || (counter==1029) || (counter==1032) || (counter==1035) || (counter==1038) || (counter==1055) || (counter==1058) || (counter==1061) || (counter==1064) || (counter==1078) || (counter==1081) || (counter==1084) || (counter==1087) || (counter==1104) || (counter==1107) || (counter==1110) || (counter==1113) || (counter==1127) || (counter==1130) || (counter==1133) || (counter==1136) || (counter==1153) || (counter==1156) || (counter==1159) || (counter==1162) || (counter==1176) || (counter==1179) || (counter==1182) || (counter==1185) || (counter==1202) || (counter==1205) || (counter==1208) || (counter==1211) || (counter==1225) || (counter==1228) || (counter==1231) || (counter==1234) ) begin
						data_in <= 8'h20;
					end else if ( (counter==12) || (counter==15) || (counter==18) || (counter==21) || (counter==38) || (counter==41) || (counter==44) || (counter==47) || (counter==61) || (counter==64) || (counter==67) || (counter==70) || (counter==87) || (counter==90) || (counter==93) || (counter==96) || (counter==110) || (counter==113) || (counter==116) || (counter==119) || (counter==136) || (counter==139) || (counter==142) || (counter==145) || (counter==159) || (counter==162) || (counter==165) || (counter==168) || (counter==185) || (counter==188) || (counter==191) || (counter==194) || (counter==208) || (counter==211) || (counter==214) || (counter==217) || (counter==234) || (counter==237) || (counter==240) || (counter==243) || (counter==257) || (counter==260) || (counter==263) || (counter==266) || (counter==283) || (counter==286) || (counter==289) || (counter==292) || (counter==306) || (counter==309) || (counter==312) || (counter==315) || (counter==332) || (counter==335) || (counter==338) || (counter==341) || (counter==355) || (counter==358) || (counter==361) || (counter==364) || (counter==381) || (counter==384) || (counter==387) || (counter==390) || (counter==404) || (counter==407) || (counter==410) || (counter==413) || (counter==430) || (counter==433) || (counter==436) || (counter==439) || (counter==453) || (counter==456) || (counter==459) || (counter==462) || (counter==479) || (counter==482) || (counter==485) || (counter==488) || (counter==502) || (counter==505) || (counter==508) || (counter==511) || (counter==528) || (counter==531) || (counter==534) || (counter==537) || (counter==551) || (counter==554) || (counter==557) || (counter==560) || (counter==577) || (counter==580) || (counter==583) || (counter==586) || (counter==600) || (counter==603) || (counter==606) || (counter==649) || (counter==652) || (counter==655) || (counter==658) || (counter==675) || (counter==678) || (counter==681) || (counter==684) || (counter==698) || (counter==701) || (counter==704) || (counter==707) || (counter==724) || (counter==727) || (counter==730) || (counter==733) || (counter==747) || (counter==750) || (counter==753) || (counter==756) || (counter==773) || (counter==776) || (counter==779) || (counter==782) || (counter==796) || (counter==799) || (counter==802) || (counter==805) || (counter==822) || (counter==825) || (counter==828) || (counter==831) || (counter==845) || (counter==848) || (counter==851) || (counter==854) || (counter==871) || (counter==874) || (counter==877) || (counter==880) || (counter==894) || (counter==897) || (counter==900) || (counter==903) || (counter==920) || (counter==923) || (counter==926) || (counter==929) || (counter==943) || (counter==946) || (counter==949) || (counter==952) || (counter==969) || (counter==972) || (counter==975) || (counter==978) || (counter==992) || (counter==995) || (counter==998) || (counter==1001) || (counter==1018) || (counter==1021) || (counter==1024) || (counter==1027) || (counter==1041) || (counter==1044) || (counter==1047) || (counter==1050) || (counter==1067) || (counter==1070) || (counter==1073) || (counter==1076) || (counter==1090) || (counter==1093) || (counter==1096) || (counter==1099) || (counter==1116) || (counter==1119) || (counter==1122) || (counter==1125) || (counter==1139) || (counter==1142) || (counter==1145) || (counter==1148) || (counter==1165) || (counter==1168) || (counter==1171) || (counter==1174) || (counter==1188) || (counter==1191) || (counter==1194) || (counter==1197) || (counter==1214) || (counter==1217) || (counter==1220) || (counter==1223) || (counter==1237) || (counter==1240) || (counter==1243) || (counter==1246) ) begin
						data_in <= 8'h08;
					end else if ( (counter==1) || (counter==4) || (counter==7) || (counter==10) || (counter==24) || (counter==27) || (counter==30) || (counter==33) || (counter==50) || (counter==53) || (counter==56) || (counter==59) || (counter==73) || (counter==76) || (counter==79) || (counter==82) || (counter==99) || (counter==102) || (counter==105) || (counter==108) || (counter==122) || (counter==125) || (counter==128) || (counter==131) || (counter==148) || (counter==151) || (counter==154) || (counter==157) || (counter==171) || (counter==174) || (counter==177) || (counter==180) || (counter==197) || (counter==200) || (counter==203) || (counter==206) || (counter==220) || (counter==223) || (counter==226) || (counter==229) || (counter==246) || (counter==249) || (counter==252) || (counter==255) || (counter==269) || (counter==272) || (counter==275) || (counter==278) || (counter==295) || (counter==298) || (counter==301) || (counter==304) || (counter==318) || (counter==321) || (counter==324) || (counter==327) || (counter==344) || (counter==347) || (counter==350) || (counter==353) || (counter==367) || (counter==370) || (counter==373) || (counter==376) || (counter==393) || (counter==396) || (counter==399) || (counter==402) || (counter==416) || (counter==419) || (counter==422) || (counter==425) || (counter==442) || (counter==445) || (counter==448) || (counter==451) || (counter==465) || (counter==468) || (counter==471) || (counter==474) || (counter==491) || (counter==494) || (counter==497) || (counter==500) || (counter==514) || (counter==517) || (counter==520) || (counter==523) || (counter==540) || (counter==543) || (counter==546) || (counter==549) || (counter==563) || (counter==566) || (counter==569) || (counter==572) || (counter==589) || (counter==592) || (counter==595) || (counter==598) || (counter==641) || (counter==644) || (counter==647) || (counter==661) || (counter==664) || (counter==667) || (counter==670) || (counter==687) || (counter==690) || (counter==693) || (counter==696) || (counter==710) || (counter==713) || (counter==716) || (counter==719) || (counter==736) || (counter==739) || (counter==742) || (counter==745) || (counter==759) || (counter==762) || (counter==765) || (counter==768) || (counter==785) || (counter==788) || (counter==791) || (counter==794) || (counter==808) || (counter==811) || (counter==814) || (counter==817) || (counter==834) || (counter==837) || (counter==840) || (counter==843) || (counter==857) || (counter==860) || (counter==863) || (counter==866) || (counter==883) || (counter==886) || (counter==889) || (counter==892) || (counter==906) || (counter==909) || (counter==912) || (counter==915) || (counter==932) || (counter==935) || (counter==938) || (counter==941) || (counter==955) || (counter==958) || (counter==961) || (counter==964) || (counter==981) || (counter==984) || (counter==987) || (counter==990) || (counter==1004) || (counter==1007) || (counter==1010) || (counter==1013) || (counter==1030) || (counter==1033) || (counter==1036) || (counter==1039) || (counter==1053) || (counter==1056) || (counter==1059) || (counter==1062) || (counter==1079) || (counter==1082) || (counter==1085) || (counter==1088) || (counter==1102) || (counter==1105) || (counter==1108) || (counter==1111) || (counter==1128) || (counter==1131) || (counter==1134) || (counter==1137) || (counter==1151) || (counter==1154) || (counter==1157) || (counter==1160) || (counter==1177) || (counter==1180) || (counter==1183) || (counter==1186) || (counter==1200) || (counter==1203) || (counter==1206) || (counter==1209) || (counter==1226) || (counter==1229) || (counter==1232) || (counter==1235) || (counter==1248) ) begin
						data_in <= 8'h02;
					end else if ( (counter==14) || (counter==17) || (counter==20) || (counter==23) || (counter==37) || (counter==40) || (counter==43) || (counter==46) || (counter==63) || (counter==66) || (counter==69) || (counter==72) || (counter==86) || (counter==89) || (counter==92) || (counter==95) || (counter==112) || (counter==115) || (counter==118) || (counter==121) || (counter==135) || (counter==138) || (counter==141) || (counter==144) || (counter==161) || (counter==164) || (counter==167) || (counter==170) || (counter==184) || (counter==187) || (counter==190) || (counter==193) || (counter==210) || (counter==213) || (counter==216) || (counter==219) || (counter==233) || (counter==236) || (counter==239) || (counter==242) || (counter==259) || (counter==262) || (counter==265) || (counter==268) || (counter==282) || (counter==285) || (counter==288) || (counter==291) || (counter==308) || (counter==311) || (counter==314) || (counter==317) || (counter==331) || (counter==334) || (counter==337) || (counter==340) || (counter==357) || (counter==360) || (counter==363) || (counter==366) || (counter==380) || (counter==383) || (counter==386) || (counter==389) || (counter==406) || (counter==409) || (counter==412) || (counter==415) || (counter==429) || (counter==432) || (counter==435) || (counter==438) || (counter==455) || (counter==458) || (counter==461) || (counter==464) || (counter==478) || (counter==481) || (counter==484) || (counter==487) || (counter==504) || (counter==507) || (counter==510) || (counter==513) || (counter==527) || (counter==530) || (counter==533) || (counter==536) || (counter==553) || (counter==556) || (counter==559) || (counter==562) || (counter==576) || (counter==579) || (counter==582) || (counter==585) || (counter==602) || (counter==605) || (counter==651) || (counter==654) || (counter==657) || (counter==660) || (counter==674) || (counter==677) || (counter==680) || (counter==683) || (counter==700) || (counter==703) || (counter==706) || (counter==709) || (counter==723) || (counter==726) || (counter==729) || (counter==732) || (counter==749) || (counter==752) || (counter==755) || (counter==758) || (counter==772) || (counter==775) || (counter==778) || (counter==781) || (counter==798) || (counter==801) || (counter==804) || (counter==807) || (counter==821) || (counter==824) || (counter==827) || (counter==830) || (counter==847) || (counter==850) || (counter==853) || (counter==856) || (counter==870) || (counter==873) || (counter==876) || (counter==879) || (counter==896) || (counter==899) || (counter==902) || (counter==905) || (counter==919) || (counter==922) || (counter==925) || (counter==928) || (counter==945) || (counter==948) || (counter==951) || (counter==954) || (counter==968) || (counter==971) || (counter==974) || (counter==977) || (counter==994) || (counter==997) || (counter==1000) || (counter==1003) || (counter==1017) || (counter==1020) || (counter==1023) || (counter==1026) || (counter==1043) || (counter==1046) || (counter==1049) || (counter==1052) || (counter==1066) || (counter==1069) || (counter==1072) || (counter==1075) || (counter==1092) || (counter==1095) || (counter==1098) || (counter==1101) || (counter==1115) || (counter==1118) || (counter==1121) || (counter==1124) || (counter==1141) || (counter==1144) || (counter==1147) || (counter==1150) || (counter==1164) || (counter==1167) || (counter==1170) || (counter==1173) || (counter==1190) || (counter==1193) || (counter==1196) || (counter==1199) || (counter==1213) || (counter==1216) || (counter==1219) || (counter==1222) || (counter==1239) || (counter==1242) || (counter==1245) ) begin
						data_in <= 8'h80;
					end
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
	wire [ADDRESS_BUS_DEPTH-1:0] START_READ_ADDRESS = `RF_BUCKETS * 0 * `SCALING / `BITS_PER_WORD;
	//wire [ADDRESS_BUS_DEPTH-1:0] START_READ_ADDRESS = 0;
	wire [ADDRESS_BUS_DEPTH-1:0] END_READ_ADDRESS = `RF_BUCKETS * 1 * `SCALING / `BITS_PER_WORD;
	//wire [ADDRESS_BUS_DEPTH-1:0] END_READ_ADDRESS = `RF_BUCKETS * REVOLUTIONS * `SCALING / `BITS_PER_WORD; // 11520
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
		.start_read_address(START_READ_ADDRESS),
		.end_read_address(END_READ_ADDRESS),
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

