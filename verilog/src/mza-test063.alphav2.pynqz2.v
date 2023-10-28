`timescale 1ns / 1ps

// written 2022-11-16 by mza
// ~/tools/Xilinx/Vivado/2020.2/data/xicom/cable_drivers/lin64/install_script/install_drivers$ sudo ./install_drivers
// last updated 2023-10-27 by mza and makiko

// circuitpython to scan i2c bus:
// import board; i2c = board.I2C(); i2c.try_lock(); i2c.scan()

module icyrus7series10bit (
	input half_bit_clock_p, half_bit_clock_n,
	//output word_clock,
	input word_clock,
	input reset,
	output [9:0] output_word,
	input input_bit
);
	wire refined_half_bit_clock_p, refined_half_bit_clock_n;
	assign refined_half_bit_clock_p = half_bit_clock_p;
//	BUFIO mediate_p (.I(half_bit_clock_p), .O(refined_half_bit_clock_p));
	assign refined_half_bit_clock_n = half_bit_clock_n;
//	BUFIO mediate_n (.I(half_bit_clock_n), .O(refined_half_bit_clock_n));
//	BUFR #(.BUFR_DIVIDE("5"), .SIM_DEVICE("7SERIES")) deviate (.I(refined_half_bit_clock_p), .O(word_clock), .CLR(reset), .CE(1'b1));
	// ISERDESE2: Input SERial/DESerializer with Bitslip 7 Series Xilinx HDL Language Template, version 2018.3 from UG953 (v2018.3) December 5, 2018
	wire shiftout1, shiftout2;
	ISERDESE2 #(
		.DATA_RATE("DDR"), // DDR, SDR
		.DATA_WIDTH(10), // Parallel data width (2-8,10,14)
		.DYN_CLKDIV_INV_EN("FALSE"), // Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
		.DYN_CLK_INV_EN("FALSE"), // Enable DYNCLKINVSEL inversion (FALSE, TRUE)
		.INIT_Q1(1'b0), .INIT_Q2(1'b0), .INIT_Q3(1'b0), .INIT_Q4(1'b0), // INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
		.INTERFACE_TYPE("NETWORKING"), // MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
		.IOBDELAY("NONE"), // NONE, BOTH, IBUF, IFD
		.NUM_CE(1), // Number of clock enables (1,2)
		.OFB_USED("FALSE"), // Select OFB path (FALSE, TRUE)
		.SERDES_MODE("MASTER"), // M*****, S****
		// SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
		.SRVAL_Q1(1'b0), .SRVAL_Q2(1'b0), .SRVAL_Q3(1'b0), .SRVAL_Q4(1'b0)
	) ISERDESE2_a (
		.O(), // 1-bit output: Combinatorial output
		// Q1 - Q8: 1-bit (each) output: Registered data outputs
		.Q1(output_word[0]), .Q2(output_word[1]), .Q3(output_word[2]), .Q4(output_word[3]),
		.Q5(output_word[4]), .Q6(output_word[5]), .Q7(output_word[6]), .Q8(output_word[7]),
		.SHIFTOUT1(shiftout1), .SHIFTOUT2(shiftout2), // SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
		.BITSLIP(1'b0), // 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to CLKDIV when asserted (active High). Subsequently, the data seen on the Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one position every time Bitslip is invoked (DDR operation is different from SDR).
		.CE1(1'b1), .CE2(1'b1), // CE1, CE2: 1-bit (each) input: Data register clock enable inputs
		.CLKDIVP(1'b0), // 1-bit input: MIG only; all others connect to GND
		// Clocks: 1-bit (each) input: ISERDESE2 clock input ports
		.CLK(refined_half_bit_clock_p), // 1-bit input: High-speed clock
		.CLKB(refined_half_bit_clock_n), // 1-bit input: High-speed secondary clock
		.CLKDIV(word_clock), // 1-bit input: Divided clock
		.OCLK(1'b0), // 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY"; all others connect to GND
		.OCLKB(1'b0), // 1-bit input: High speed negative edge output clock
		// Dynamic Clock Inversions: 1-bit (each) input: Dynamic clock inversion pins to switch clock polarity
		.DYNCLKDIVSEL(1'b0), // 1-bit input: Dynamic CLKDIV inversion
		.DYNCLKSEL(1'b0), // 1-bit input: Dynamic CLK/CLKB inversion
		// Input Data: 1-bit (each) input: ISERDESE2 data input ports
		.D(input_bit), // 1-bit input: Data input
		.DDLY(1'b0), // 1-bit input: Serial data from IDELAYE2
		.OFB(1'b0), // 1-bit input: Data feedback from OSERDESE2
		.RST(reset), // 1-bit input: Active high asynchronous reset
		.SHIFTIN1(1'b0), .SHIFTIN2(1'b0) // SHIFTIN1, SHIFTIN2: 1-bit (each) input: Data width expansion input ports; all others connect to GND
	);
	ISERDESE2 #(
		.DATA_RATE("DDR"), // DDR, SDR
		.DATA_WIDTH(10), // Parallel data width (2-8,10,14)
		.DYN_CLKDIV_INV_EN("FALSE"), // Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
		.DYN_CLK_INV_EN("FALSE"), // Enable DYNCLKINVSEL inversion (FALSE, TRUE)
		.INIT_Q1(1'b0), .INIT_Q2(1'b0), .INIT_Q3(1'b0), .INIT_Q4(1'b0), // INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
		.INTERFACE_TYPE("NETWORKING"), // MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
		.IOBDELAY("NONE"), // NONE, BOTH, IBUF, IFD
		.NUM_CE(1), // Number of clock enables (1,2)
		.OFB_USED("FALSE"), // Select OFB path (FALSE, TRUE)
		.SERDES_MODE("SLAVE"), // M*****, S****
		// SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
		.SRVAL_Q1(1'b0), .SRVAL_Q2(1'b0), .SRVAL_Q3(1'b0), .SRVAL_Q4(1'b0)
	) ISERDESE2_1 (
		.O(), // 1-bit output: Combinatorial output
		// Q1 - Q8: 1-bit (each) output: Registered data outputs
		.Q1(), .Q2(), .Q3(output_word[8]), .Q4(output_word[9]),
		.Q5(), .Q6(), .Q7(), .Q8(),
		.SHIFTOUT1(), .SHIFTOUT2(), // SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
		.BITSLIP(1'b0), // 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to CLKDIV when asserted (active High). Subsequently, the data seen on the Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one position every time Bitslip is invoked (DDR operation is different from SDR).
		.CE1(1'b1), .CE2(1'b1), // CE1, CE2: 1-bit (each) input: Data register clock enable inputs
		.CLKDIVP(1'b0), // 1-bit input: MIG only; all others connect to GND
		// Clocks: 1-bit (each) input: ISERDESE2 clock input ports
		.CLK(refined_half_bit_clock_p), // 1-bit input: High-speed clock
		.CLKB(refined_half_bit_clock_n), // 1-bit input: High-speed secondary clock
		.CLKDIV(word_clock), // 1-bit input: Divided clock
		.OCLK(1'b0), // 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY"; all others connect to GND
		.OCLKB(1'b0), // 1-bit input: High speed negative edge output clock
		// Dynamic Clock Inversions: 1-bit (each) input: Dynamic clock inversion pins to switch clock polarity
		.DYNCLKDIVSEL(1'b0), // 1-bit input: Dynamic CLKDIV inversion
		.DYNCLKSEL(1'b0), // 1-bit input: Dynamic CLK/CLKB inversion
		// Input Data: 1-bit (each) input: ISERDESE2 data input ports
		.D(), // 1-bit input: Data input
		.DDLY(1'b0), // 1-bit input: Serial data from IDELAYE2
		.OFB(1'b0), // 1-bit input: Data feedback from OSERDESE2
		.RST(reset), // 1-bit input: Active high asynchronous reset
		.SHIFTIN1(shiftout1), .SHIFTIN2(shiftout2) // SHIFTIN1, SHIFTIN2: 1-bit (each) input: Data width expansion input ports; all others connect to GND
	);
endmodule

//MMCM #(.M(10.0), .D(1), .CLKOUT0_DIVIDE(1.0), .CLOCK_PERIOD_NS(10.0),
//	.CLKOUT1_DIVIDE(1), .CLKOUT2_DIVIDE(1), .CLKOUT3_DIVIDE(1),
//	.CLKOUT4_DIVIDE(1), .CLKOUT5_DIVIDE(1), .CLKOUT6_DIVIDE(1)) (
//	.clock_in(clock), .reset(reset), .locked(mmcm_locked),
//	.clock0_out_p(), .clock0_out_n(), .clock1_out_p(), .clock1_out_n(),
//	.clock2_out_p(), .clock2_out_n(), .clock3_out_p(), .clock3_out_n(),
//	.clock4_out(), .clock5_out(), .clock6_out());
module MMCM #(
	parameter M = 10.0, // overall multiply [2.0,64.0]
	parameter D = 1, // overall divide [1,106]
	parameter CLKOUT0_DIVIDE = 1.0, // this one is fractional [1.0,128.0]
	parameter CLKOUT1_DIVIDE = 1, // [1,128]
	parameter CLKOUT2_DIVIDE = 1,
	parameter CLKOUT3_DIVIDE = 1,
	parameter CLKOUT4_DIVIDE = 1,
	parameter CLKOUT5_DIVIDE = 1,
	parameter CLKOUT6_DIVIDE = 1,
	parameter CLOCK_PERIOD_NS = 10.0
) (
	input clock_in, // input=[10,800]MHz; PFD=[10,450]MHZ; VCO=[600,1200]MHz; OUT=[4.69,800]MHz for a "-1" grade zynq-7020
	input reset,
	output locked,
	output clock0_out_p, clock0_out_n,
	output clock1_out_p, clock1_out_n,
	output clock2_out_p, clock2_out_n,
	output clock3_out_p, clock3_out_n,
	output clock4_out,
	output clock5_out,
	output clock6_out
);
	wire clkfb;
	// MMCME2_BASE: Base Mixed Mode Clock Manager 7 Series Xilinx HDL Language Template, version 2018.3
	MMCME2_BASE #(
		.STARTUP_WAIT("FALSE"), // Delays DONE until MMCM is locked (FALSE, TRUE)
		.BANDWIDTH("OPTIMIZED"), // Jitter programming (OPTIMIZED, HIGH, LOW)
		.REF_JITTER1(0.0), // Reference input jitter in UI (0.000-0.999).
		.DIVCLK_DIVIDE(D), // Master division value (1-106)
		.CLKFBOUT_MULT_F(M), // Multiply value for all CLKOUT (2.000-64.000).
		.CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
		.CLKIN1_PERIOD(CLOCK_PERIOD_NS), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		.CLKOUT0_DIVIDE_F(CLKOUT0_DIVIDE), // Divide amount for CLKOUT0 (1.000-128.000).
		// CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
		.CLKOUT1_DIVIDE(CLKOUT1_DIVIDE),
		.CLKOUT2_DIVIDE(CLKOUT2_DIVIDE),
		.CLKOUT3_DIVIDE(CLKOUT3_DIVIDE),
		.CLKOUT4_DIVIDE(CLKOUT4_DIVIDE),
		.CLKOUT5_DIVIDE(CLKOUT5_DIVIDE),
		.CLKOUT6_DIVIDE(CLKOUT6_DIVIDE),
		// CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT6_DUTY_CYCLE(0.5),
		// CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.CLKOUT6_PHASE(0.0),
		.CLKOUT4_CASCADE("FALSE") // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
	) MMCME2_BASE_inst (
		// Clock Outputs: 1-bit (each) output: User configurable clock outputs
		.CLKOUT0(clock0_out_p), // 1-bit output: CLKOUT0
		.CLKOUT0B(clock0_out_n), // 1-bit output: Inverted CLKOUT0
		.CLKOUT1(clock1_out_p), // 1-bit output: CLKOUT1
		.CLKOUT1B(clock1_out_n), // 1-bit output: Inverted CLKOUT1
		.CLKOUT2(clock2_out_p), // 1-bit output: CLKOUT2
		.CLKOUT2B(clock2_out_n), // 1-bit output: Inverted CLKOUT2
		.CLKOUT3(clock3_out_p), // 1-bit output: CLKOUT3
		.CLKOUT3B(clock3_out_n), // 1-bit output: Inverted CLKOUT3
		.CLKOUT4(clock4_out), // 1-bit output: CLKOUT4
		.CLKOUT5(clock5_out), // 1-bit output: CLKOUT5
		.CLKOUT6(clock6_out), // 1-bit output: CLKOUT6
		// Feedback Clocks: 1-bit (each) output: Clock feedback ports
		.CLKFBOUT(clkfb), // 1-bit output: Feedback clock
		.CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
		// Status Ports: 1-bit (each) output: MMCM status ports
		.LOCKED(locked), // 1-bit output: LOCK
		// Clock Inputs: 1-bit (each) input: Clock input
		.CLKIN1(clock_in), // 1-bit input: Clock
		// Control Ports: 1-bit (each) input: MMCM control ports
		.PWRDWN(1'b0), // 1-bit input: Power-down
		.RST(reset), // 1-bit input: Reset
		// Feedback Clocks: 1-bit (each) input: Clock feedback ports
		.CLKFBIN(clkfb) // 1-bit input: Feedback clock
	);
endmodule

module clock_out_test #(
	parameter ALPHA_V = 2
) (
//	input sysclk, // unreliable 125 MHz, comes from RTL8211 (ethernet) via 50 MHz osc
//	input [5:4] jb, // pmod_osc pmod_port_B
	input [5:4] ja, // 127.216 MHz, comes from PMODA
//	input [7:6] ja, // 42.3724 MHz, comes from PMODA
	input [3:0] btn, // buttons
	input [1:0] sw, // switches
	output [3:0] led,
//	output hdmi_rx_cec, // sysclock out (single-ended because of TMDS/LVDS shenanigans on pynq board)
//	output hdmi_tx_cec, // dummy data
	output ar_sda, // rpio_00_r tok_a_b2f input
	output ar_scl, // rpio_01_r tok_b_m2f input
	output rpio_02_r, // single-ended sysclk
	output rpio_03_r, // pclk_m
	output rpio_04_r, // pclk_t
	output rpio_05_r, // tok_a_f2t
//	output rpio_06_r, // testmode - conflicts with ja[5:4]
//	output rpio_07_r, // t_sin ct5tea
//	output rpio_08_r, // t_sclk ct5tea
//	output rpio_09_r, // t_pclk ct5tea
	output rpio_10_r, // pclk_b
	output rpio_11_r, // tok_b_f2m
	output rpio_12_r, // sync
	inout rpio_13_r, // sda
	output rpio_14_r, // trig_top
	output rpio_15_r, // sclk
//	output rpio_16_r, // dat_b_m2f
	output rpio_17_r, // gpio17
	output rpio_18_r, // sin
	output rpio_19_r, // scl
//	output rpio_20_r, // trig_bot
//	output rpio_21_r, // dat_a_f2b
//	output rpio_22_r, // sstclk
	output rpio_23_r, // gpio23 / auxtrig
//	output rpio_24_r, // trig_mid // driven by SN65EPT23
//	output rpio_25_r, // t_shout ct5tea
//	output rpio_26_r, // dat_b_f2m
//	output rpio_27_r, // dat_a_t2f
	output hdmi_tx_clk_p, // differential sysclk
	output hdmi_tx_clk_n,
	output hdmi_rx_clk_p, // differential sstclk
	output hdmi_rx_clk_n,
	input [1:0] hdmi_rx_d_p, // d0=dat_b_m2f; d1=dat_a_t2f
	input [1:0] hdmi_rx_d_n,
	output hdmi_rx_d2_p, // d2=trigtop/trig_top/trigin_top
	output hdmi_rx_d2_n,
	output [2:0] hdmi_tx_d_p, // d0=dat_a_f2b; d1=dat_b_f2m; d0=trigbot/trig_bot/trigin_bot 
	output [2:0] hdmi_tx_d_n
//	inout hdmi_rx_scl, // 
//	inout hdmi_rx_sda // 
);
	wire pclk, pclk_t, pclk_m, pclk_b, sin, sclk;
	wire sda;
	wire sda_in;
	wire sda_out;
	wire scl;
	wire tok_a_f2t;
	wire testmode;
	wire tok_b_f2m;
	wire sync;
	wire auxtrig;
	wire actual_auxtrig, actual_pclk_t, actual_pclk_m, actual_pclk_b, actual_sclk;
	wire dreset; // auxtrig, pclk, sclk;
	wire gpio17;
	// HDMI -------------------------------------
	wire trig_top, trig_bot;
	OBUFDS obuf_trigtop (.I(trig_top), .O(hdmi_rx_d2_p), .OB(hdmi_rx_d2_n));
	OBUFDS obuf_trigbot (.I(trig_bot), .O(hdmi_tx_d_p[2]), .OB(hdmi_tx_d_n[2]));
	wire sysclk, sstclk;
	OBUFDS obuf_sysclk (.I(sysclk), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	OBUFDS obuf_sstclk (.I(sstclk), .O(hdmi_rx_clk_p), .OB(hdmi_rx_clk_n));
	wire dat_b_m2f;
	IBUFDS ibuf_dat_b_m2f (.I(hdmi_rx_d_p[0]), .IB(hdmi_rx_d_n[0]), .O(dat_b_m2f));
	wire dat_a_t2f;
	IBUFDS ibuf_dat_a_t2f (.I(hdmi_rx_d_p[1]), .IB(hdmi_rx_d_n[1]), .O(dat_a_t2f));
	wire dat_a_f2b;
	OBUFDS obuf_dat_a_f2b (.I(dat_a_f2b), .O(hdmi_tx_d_p[0]), .OB(hdmi_tx_d_n[0]));
	wire dat_b_f2m;                     
	OBUFDS obuf_dat_b_f2m (.I(dat_b_f2m), .O(hdmi_tx_d_p[1]), .OB(hdmi_tx_d_n[1]));
	// RPI --------------------------------------
	wire tok_a_b2f = ar_sda; // rpio_00_r input to fpga
	wire tok_b_m2f = ar_scl; // rpio_01_r
	assign rpio_02_r = sysclk; // single-ended sysclk
	assign rpio_03_r = actual_pclk_m; // output to middle alpha
	assign rpio_04_r = actual_pclk_t;
	assign rpio_05_r = tok_a_f2t;
//	assign rpio_06_r = testmode;
//	wire rpio_07_r, // t_sin ct5tea
//	wire rpio_08_r, // t_sclk ct5tea
//	wire rpio_09_r, // t_pclk ct5tea
	assign rpio_10_r = actual_pclk_b;
	assign rpio_11_r = tok_b_f2m;
	assign rpio_12_r = sync;
	assign rpio_13_r = sda;
	assign rpio_14_r = trig_top; // trigtop
	assign rpio_15_r = actual_sclk;
//	wire rpio_16_r, // dat_b_m2f
	assign rpio_17_r = gpio17;
	assign rpio_18_r = sin;
	assign rpio_19_r = scl;
	assign rpio_20_r = trig_bot; // trigbot
//	wire rpio_21_r, // dat_a_f2b
//	wire rpio_22_r, // sstclk
	assign rpio_23_r = actual_auxtrig;
//	wire rpio_24_r = trig_mid; // driven by SN65EPT23
//	wire rpio_25_r, // t_shout ct5tea
//	wire rpio_26_r, // dat_b_f2m
//	wire rpio_27_r, // dat_a_t2f
	// defaults ---------------------------------
//	assign dreset = 1'b0;
	assign sda = 1'bz;
//	assign scl = 1'bz;
//	assign pclk_t = 1'b0;
	assign pclk_t = pclk;
	assign actual_pclk_t = pclk_t | dreset;
//	assign pclk_m = 1'b0;
	assign pclk_m = pclk;
	assign actual_pclk_m = pclk_m | dreset;
//	assign pclk_b = 1'b0;
	assign pclk_b = pclk;
	assign actual_pclk_b = pclk_b | dreset;
//	assign sclk = 1'b0;
	assign actual_sclk = sclk | dreset;
//	assign sin = 1'b0;
//	assign tok_a_f2t = 1'b0;
	assign testmode = 1'b0;
//	assign sync = 1'b0;
//	assign auxtrig = 1'b0;
	assign actual_auxtrig = auxtrig | dreset;
//	assign dreset = 1'b0;
//	assign trig_top = 1'b0;
	assign trig_mid = 1'b0;
	assign trig_bot = 1'b0;
//	assign sysclk = 1'b0;
	assign sstclk = 1'b0;
	assign dat_b_f2m = 1'b0;
	assign dat_a_f2b = 1'b0;
	assign tok_b_f2m = 1'b0;
	// ------------------------------------------
	wire reset = btn[0];
	wire clock;
	IBUFGDS clock_in_diff (.I(ja[4]), .IB(ja[5]), .O(clock));
	//IBUFG clock_in_se (.I(ja[7]), .O(clock));
//	OBUFDS (.I(clock), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	wire clock_enable;
	assign clock_enable = sw[0];
	wire clock_oddr1;
	wire clock_oddr2;
	wire clock_oddr3;
	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst1 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr1));
	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst2 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr2));
	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst3 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr3));
	assign gpio17 = clock_oddr1;
	//OBUFDS (.I(clock_oddr1), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	//OBUFDS (.I(1'b0), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	//assign hdmi_tx_cec = clock_oddr3;
	//assign hdmi_tx_cec = 0;
	//assign hdmi_rx_cec = clock_oddr3;
	wire mmcm_locked;
	assign led[3] = 1'b0;
	assign led[2] = 1'b0;
	assign led[1] = mmcm_locked;
	assign led[0] = clock_enable;
	wire sysclk_raw;
	BUFG bufg_sysclk (.I(sysclk_raw), .O(sysclk));
	//localparam DIVIDE_RATIO = 3; // 127.22 * 6.0 / 1 / 3 = 254
	//localparam DIVIDE_RATIO = 6; // 127.22 * 6.0 / 1 / 6 = 127
	//localparam DIVIDE_RATIO = 9; // 127.22 * 6.0 / 1 / 9 = 85
	//localparam DIVIDE_RATIO = 10; // 127.22 * 6.0 / 1 / 10 = 76
	localparam DIVIDE_RATIO = 10.5; // 127.22 * 6.0 / 1 / 10 = 80
	//localparam DIVIDE_RATIO = 11; // 127.22 * 6.0 / 1 / 11 = 69
	//localparam DIVIDE_RATIO = 12; // 127.22 * 6.0 / 1 / 12 = 64
	//localparam DIVIDE_RATIO = 25; // 127.22 * 6.0 / 1 / 25 = 30.53
	// 600 - 1200 MHz range VCO frequency
	MMCM #(
		.M(6.0), .D(1), .CLOCK_PERIOD_NS(7.86), .CLKOUT0_DIVIDE(DIVIDE_RATIO)
			) mymmcm (
		.clock_in(clock), .reset(reset), .locked(mmcm_locked),
		.clock0_out_p(sysclk_raw), .clock0_out_n(), .clock1_out_p(), .clock1_out_n(),
		.clock2_out_p(), .clock2_out_n(), .clock3_out_p(), .clock3_out_n(),
		.clock4_out(), .clock5_out(), .clock6_out());
	localparam RESET_BUTTON_PICKOFF = 6;
	reg [RESET_BUTTON_PICKOFF:0] reset_button1_pipeline = 0;
	reg [RESET_BUTTON_PICKOFF:0] reset_button2_pipeline = 0;
	reg startup_sequence_1 = 0;
	reg startup_sequence_2 = 0;
	always @(posedge clock) begin
		if (reset) begin
			reset_button1_pipeline <= 0;
			reset_button2_pipeline <= 0;
			startup_sequence_1 <= 0;
			startup_sequence_2 <= 0;
		end else begin
			startup_sequence_1 <= 0;
			startup_sequence_2 <= 0;
			if (reset_button1_pipeline[RESET_BUTTON_PICKOFF:RESET_BUTTON_PICKOFF-1]==2'b01) begin
				startup_sequence_1 <= 1;
			end
			if (reset_button2_pipeline[RESET_BUTTON_PICKOFF:RESET_BUTTON_PICKOFF-1]==2'b01) begin
				startup_sequence_2 <= 1;
			end
			reset_button1_pipeline <= { reset_button1_pipeline[RESET_BUTTON_PICKOFF-1:0], btn[1] };
			reset_button2_pipeline <= { reset_button2_pipeline[RESET_BUTTON_PICKOFF-1:0], btn[2] };
		end
	end
	alphav2_control alpv2 (.clock(clock), .reset(reset), .startup_sequence_1(startup_sequence_1), .startup_sequence_2(startup_sequence_2), .sync(sync), .dreset(dreset), .tok_a_f2t(tok_a_f2t), .scl(scl), .sda_in(sda_in), .sda_out(sda_out), .sin(sin), .pclk(pclk), .sclk(sclk), .trig_top(trig_top));
endmodule

module alphav2_control_tb;
	reg clock = 0;
	reg reset = 1;
	reg startup_sequence_1 = 0;
	wire sync, dreset, tok_a_f2t;
	initial begin
		reset <= 1;
		#101;
		reset <= 0;
		#100;
		startup_sequence_1 <= 1;
		#4;
		startup_sequence_1 <= 0;
		#400;
		startup_sequence_1 <= 1;
		#4;
		startup_sequence_1 <= 0;
		#400;
	end
	always begin
		clock <= ~clock;
		#2;
	end
	alphav2_control alpv2 (.clock(clock), .reset(reset), .startup_sequence_1(startup_sequence_1), .startup_sequence_2(startup_sequence_2), .sync(sync), .dreset(dreset), .tok_a_f2t(tok_a_f2t), .scl(scl), .sda_in(sda_in), .sda_out(sda_out), .sin(sin), .pclk(pclk), .sclk(sclk), .trig_top(trig_top));
endmodule

module alphav2_control (
	input clock, reset, startup_sequence_1, startup_sequence_2,
	input sda_in,
	output reg sync, dreset, tok_a_f2t, scl, sda_out, sin, pclk, sclk, trig_top
);
	reg [31:0] counter1 = 0;
	reg [31:0] counter2 = 0;
	reg mode1 = 0;
	reg mode2 = 0;
//	reg dunno = 0;
	localparam TIMING_CONSTANT = 100;
	always @(posedge clock) begin
		if (reset) begin
			counter1 <= 0;
			mode1 <= 0;
			sync <= 0;
			dreset <= 0;
			tok_a_f2t <= 0;
			trig_top <= 0;
//			dunno <= 0;
		end else begin
			counter1 <= counter1 + 1'b1;
//			dunno <= 0;
			if (mode1==1'b1) begin
				if (1*TIMING_CONSTANT<counter1 & counter1<2*TIMING_CONSTANT) begin
					dreset <= 1'b1;
				end else if (2*TIMING_CONSTANT<counter1 & counter1<3*TIMING_CONSTANT) begin
					dreset <= 0;
				end else if (3*TIMING_CONSTANT<counter1 & counter1<4*TIMING_CONSTANT) begin
					sync <= 1'b1;
				end else if (4*TIMING_CONSTANT<counter1 & counter1<5*TIMING_CONSTANT) begin
					sync <= 0;
				end else if (5*TIMING_CONSTANT<counter1 & counter1<6*TIMING_CONSTANT) begin
					tok_a_f2t <= 1'b1;
				end else if (6*TIMING_CONSTANT<counter1 & counter1<7*TIMING_CONSTANT) begin
					tok_a_f2t <= 0;
				end else if (7*TIMING_CONSTANT<counter1 & counter1<8*TIMING_CONSTANT) begin
					trig_top <= 1'b1;
				end else if (8*TIMING_CONSTANT<counter1 & counter1<1129*TIMING_CONSTANT) begin
					trig_top <= 0;
				end else if (1129*TIMING_CONSTANT<counter1 & counter1<1130*TIMING_CONSTANT) begin
					tok_a_f2t <= 1'b1;
				end else if (1130*TIMING_CONSTANT<counter1 & counter1<1131*TIMING_CONSTANT) begin
					tok_a_f2t <= 0;
				end else if (1131*TIMING_CONSTANT<counter1) begin
					mode1 <= 1'b0;
//				end else begin
//					dunno <= 1;
				end
			end
			if (startup_sequence_1) begin
				counter1 <= 0;
				mode1 <= 1'b1;
				sync <= 0;
				dreset <= 0;
				tok_a_f2t <= 0;
				trig_top <= 0;
			end
		end
	end
	wire [15:0] data_word = 16'hf0a5;
	reg [3:0] bit_counter = 0;
	always @(posedge clock) begin
		if (reset) begin
			mode2 <= 0;
			counter2 <= 0;
			sin <= 0;
			sclk <= 0;
			pclk <= 0;
			bit_counter <= 0;
		end else begin
			counter2 <= counter2 + 1'b1;
			if (mode2==1'b1) begin
				if (1*TIMING_CONSTANT<counter2 & counter2<2*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (2*TIMING_CONSTANT<counter2 & counter2<3*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (3*TIMING_CONSTANT<counter2 & counter2<4*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (4*TIMING_CONSTANT<counter2 & counter2<5*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (5*TIMING_CONSTANT<counter2 & counter2<6*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (6*TIMING_CONSTANT<counter2 & counter2<7*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (7*TIMING_CONSTANT<counter2 & counter2<8*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (8*TIMING_CONSTANT<counter2 & counter2<9*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (9*TIMING_CONSTANT<counter2 & counter2<10*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (10*TIMING_CONSTANT<counter2 & counter2<11*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (11*TIMING_CONSTANT<counter2 & counter2<12*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (12*TIMING_CONSTANT<counter2 & counter2<13*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (13*TIMING_CONSTANT<counter2 & counter2<14*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (14*TIMING_CONSTANT<counter2 & counter2<15*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (15*TIMING_CONSTANT<counter2 & counter2<16*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (16*TIMING_CONSTANT<counter2 & counter2<17*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (17*TIMING_CONSTANT<counter2 & counter2<18*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (18*TIMING_CONSTANT<counter2 & counter2<19*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (19*TIMING_CONSTANT<counter2 & counter2<20*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (20*TIMING_CONSTANT<counter2 & counter2<21*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (21*TIMING_CONSTANT<counter2 & counter2<22*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (22*TIMING_CONSTANT<counter2 & counter2<23*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (23*TIMING_CONSTANT<counter2 & counter2<24*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (24*TIMING_CONSTANT<counter2 & counter2<25*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (25*TIMING_CONSTANT<counter2 & counter2<26*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (26*TIMING_CONSTANT<counter2 & counter2<27*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (27*TIMING_CONSTANT<counter2 & counter2<28*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (28*TIMING_CONSTANT<counter2 & counter2<29*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (29*TIMING_CONSTANT<counter2 & counter2<30*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (30*TIMING_CONSTANT<counter2 & counter2<31*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (31*TIMING_CONSTANT<counter2 & counter2<32*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (32*TIMING_CONSTANT<counter2 & counter2<33*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (33*TIMING_CONSTANT<counter2 & counter2<34*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (34*TIMING_CONSTANT<counter2 & counter2<35*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (35*TIMING_CONSTANT<counter2 & counter2<36*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (36*TIMING_CONSTANT<counter2 & counter2<37*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (37*TIMING_CONSTANT<counter2 & counter2<38*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (38*TIMING_CONSTANT<counter2 & counter2<39*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (39*TIMING_CONSTANT<counter2 & counter2<40*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (40*TIMING_CONSTANT<counter2 & counter2<41*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (41*TIMING_CONSTANT<counter2 & counter2<42*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (42*TIMING_CONSTANT<counter2 & counter2<43*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (43*TIMING_CONSTANT<counter2 & counter2<44*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (44*TIMING_CONSTANT<counter2 & counter2<45*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (45*TIMING_CONSTANT<counter2 & counter2<46*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (46*TIMING_CONSTANT<counter2 & counter2<47*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (47*TIMING_CONSTANT<counter2 & counter2<48*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (48*TIMING_CONSTANT<counter2 & counter2<49*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				// dummy bits follow --------------------------------
				end else if (49*TIMING_CONSTANT<counter2 & counter2<50*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (50*TIMING_CONSTANT<counter2 & counter2<51*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (51*TIMING_CONSTANT<counter2 & counter2<52*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (52*TIMING_CONSTANT<counter2 & counter2<53*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (53*TIMING_CONSTANT<counter2 & counter2<54*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (54*TIMING_CONSTANT<counter2 & counter2<55*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (55*TIMING_CONSTANT<counter2 & counter2<56*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (56*TIMING_CONSTANT<counter2 & counter2<57*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (57*TIMING_CONSTANT<counter2 & counter2<58*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
				end else if (58*TIMING_CONSTANT<counter2 & counter2<59*TIMING_CONSTANT) begin
					sin <= data_word[bit_counter];
				end else if (59*TIMING_CONSTANT<counter2 & counter2<60*TIMING_CONSTANT) begin
					sclk <= 1'b1;
				end else if (60*TIMING_CONSTANT<counter2 & counter2<61*TIMING_CONSTANT) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter + 1'b1;
					mode2 <= 1'b0;
				end
			end
			if (startup_sequence_2) begin
				counter2 <= 0;
				mode2 <= 1'b1;
				sin <= 0;
				sclk <= 0;
				pclk <= 0;
				bit_counter <= 0;
			end
		end
	end
	reg [31:0] i2c_counter = 0;
	reg [6:0] i2c_address = 0;
	reg [7:0] i2c_data = 0;
	localparam I2C_GRANULARITY = 100;
	always @(posedge clock) begin
		if (reset) begin
			i2c_counter <= 0;
			i2c_address <= 0;
			i2c_data <= 0;
			scl <= 1'bz;
			sda_out <= 1'bz;
		end else begin
//			if (2*I2C_GRANULARITY<counter & 3*I2C_GRANULARITY<counter) begin

//			end
		end
	end
endmodule

