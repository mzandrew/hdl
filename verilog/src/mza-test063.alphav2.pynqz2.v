`timescale 1ns / 1ps

// written 2022-11-16 by mza
// ~/tools/Xilinx/Vivado/2020.2/data/xicom/cable_drivers/lin64/install_script/install_drivers$ sudo ./install_drivers
// last updated 2024-02-07 by mza and makiko

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
	parameter D = 1, // overall divide [1,106]
	parameter M = 10.0, // overall multiply [2.0,64.0]
	parameter CLKOUT0_DIVIDE = 1.0, // this one is fractional [1.0,128.0]
	parameter CLKOUT1_DIVIDE = 1, // [1,128]
	parameter CLKOUT2_DIVIDE = 1,
	parameter CLKOUT3_DIVIDE = 1,
	parameter CLKOUT4_DIVIDE = 1,
	parameter CLKOUT5_DIVIDE = 1,
	parameter CLKOUT6_DIVIDE = 1,
	parameter CLOCK_PERIOD_NS = 10.0
) (
	input clock_in, // input=[10,800]MHz; PFD=[10,450]MHz; VCO=[600,1200]MHz; OUT=[4.69,800]MHz for a "-1" grade zynq-7020
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
		.REF_JITTER1(0.1), // Reference input jitter in UI (0.000-0.999).
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
		.CLKFBOUT(clkfb), // 1-bit output: Feedback clock
		.CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
		.CLKFBIN(clkfb), // 1-bit input: Feedback clock
		.LOCKED(locked), // 1-bit output: LOCK
		.CLKIN1(clock_in), // 1-bit input: Clock
		.PWRDWN(1'b0), // 1-bit input: Power-down
		.RST(reset) // 1-bit input: Reset
	);
endmodule

module MMCM_advanced #(
	parameter D = 1, // overall divide [1,106]
	parameter M = 10.0, // overall multiply [2.0,64.0]
	parameter CLKOUT0_DIVIDE = 1.0, // this one is fractional [1.0,128.0]
	parameter CLKOUT1_DIVIDE = 1, // [1,128]
	parameter CLKOUT2_DIVIDE = 1,
	parameter CLKOUT3_DIVIDE = 1,
	parameter CLKOUT4_DIVIDE = 1,
	parameter CLKOUT5_DIVIDE = 1,
	parameter CLKOUT6_DIVIDE = 1,
	parameter CLOCK1_PERIOD_NS = 10.0,
	parameter CLOCK2_PERIOD_NS = 10.0
) (
	input clock1_in, // input=[10,800]MHz; PFD=[10,450]MHz; VCO=[600,1200]MHz; OUT=[4.69,800]MHz for a "-1" grade zynq-7020
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
	wire [15:0] drp_DO, drp_DI;
	wire [6:0] drp_DADDR;
	wire drp_DCLK, drp_DEN, drp_DWE, drp_DRDY;
	assign drp_DCLK = 0;
	assign drp_DEN = 0;
	assign drp_DWE = 0;
	assign drp_DADDR = 0;
	assign drp_DI = 0;
	wire clk_fb;
	// MMCME2_ADV: Advanced Mixed Mode Clock Manager 7 Series
	// modified from Xilinx HDL Language Template, version 2023.2 (ug953)
	MMCME2_ADV #(
		.BANDWIDTH("OPTIMIZED"), // Jitter programming (OPTIMIZED, HIGH, LOW)
		.DIVCLK_DIVIDE(D), // Master division value (1-106)
		.CLKFBOUT_MULT_F(M), // Multiply value for all CLKOUT (2.000-64.000).
		.CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
		.CLKIN1_PERIOD(CLOCK1_PERIOD_NS), // CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		.CLKIN2_PERIOD(CLOCK2_PERIOD_NS),
		.CLKOUT0_DIVIDE_F(CLKOUT0_DIVIDE), // Divide amount for CLKOUT0 (1.000-128.000).
		.CLKOUT1_DIVIDE(CLKOUT1_DIVIDE), // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
		.CLKOUT2_DIVIDE(CLKOUT2_DIVIDE),
		.CLKOUT3_DIVIDE(CLKOUT3_DIVIDE),
		.CLKOUT4_DIVIDE(CLKOUT4_DIVIDE),
		.CLKOUT5_DIVIDE(CLKOUT5_DIVIDE),
		.CLKOUT6_DIVIDE(CLKOUT6_DIVIDE),
		.CLKOUT0_DUTY_CYCLE(0.5), // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		.CLKOUT6_DUTY_CYCLE(0.5),
		.CLKOUT0_PHASE(0.0), // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.CLKOUT6_PHASE(0.0),
		.CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
		.COMPENSATION("ZHOLD"), // ZHOLD, BUF_IN, EXTERNAL, INTERNAL
		.REF_JITTER1(0.1), // REF_JITTER: Reference input jitter in UI (0.000-0.999).
		.REF_JITTER2(0.1),
		.STARTUP_WAIT("FALSE"), // Delays DONE until MMCM is locked (FALSE, TRUE)
		.SS_EN("FALSE"), // Enables spread spectrum (FALSE, TRUE)
		.SS_MODE("CENTER_HIGH"), // CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
		.SS_MOD_PERIOD(10000), // Spread spectrum modulation period (ns) (VALUES)
		.CLKFBOUT_USE_FINE_PS("FALSE"), // USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
		.CLKOUT0_USE_FINE_PS("FALSE"),
		.CLKOUT1_USE_FINE_PS("FALSE"),
		.CLKOUT2_USE_FINE_PS("FALSE"),
		.CLKOUT3_USE_FINE_PS("FALSE"),
		.CLKOUT4_USE_FINE_PS("FALSE"),
		.CLKOUT5_USE_FINE_PS("FALSE"),
		.CLKOUT6_USE_FINE_PS("FALSE")
	) MMCME2_ADV_inst (
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
		.PSCLK(1'b0), // 1-bit input: Phase shift clock
		.PSEN(1'b0), // 1-bit input: Phase shift enable
		.PSINCDEC(1'b0), // 1-bit input: Phase shift increment/decrement
		.PSDONE(), // 1-bit output: Phase shift done
		.CLKFBIN(clk_fb), // 1-bit input: Feedback clock
		.CLKFBOUT(clk_fb), // 1-bit output: Feedback clock
		.CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
		.CLKFBSTOPPED(), // 1-bit output: Feedback clock stopped
		.CLKINSTOPPED(), // 1-bit output: Input clock stopped
		.LOCKED(locked), // 1-bit output: LOCK
		.CLKIN1(clock1_in), // 1-bit input: Primary clock
		.CLKIN2(1'b0), // 1-bit input: Secondary clock
		.CLKINSEL(1'b1), // 1-bit input: Clock select, 1=CLKIN1 0=CLKIN2
		.PWRDWN(1'b0), // 1-bit input: Power-down
		.RST(reset), // 1-bit input: Reset
		.DO(drp_DO), // 16-bit output: DRP data
		.DRDY(drp_DRDY), // 1-bit output: DRP ready
		.DADDR(drp_DADDR), // 7-bit input: DRP address
		.DCLK(drp_DCLK), // 1-bit input: DRP clock
		.DEN(drp_DEN), // 1-bit input: DRP enable
		.DI(drp_DI), // 16-bit input: DRP data
		.DWE(drp_DWE) // 1-bit input: DRP write enable
	);
endmodule

module clock_out_test #(
	parameter ALPHA_V = 2
) (
//	input sysclk, // unreliable 125 MHz, comes from RTL8211 (ethernet) via 50 MHz osc
//	input [5:4] jb, // pmod_osc pmod_port_B
	output [7:0] jb, // PMODB
	input [5:4] ja, // 100.0 MHz, comes from PMODA
//	output [3:2] jc, // ja[3] is the clock output, renamed jc here for verilog in/out reasons
//	input [7:6] ja,
	input [3:0] btn, // buttons
	input [1:0] sw, // switches
	output [3:0] led,
	output led4_g,
//	output hdmi_rx_cec, // sysclock out (single-ended because of TMDS/LVDS shenanigans on pynq board)
//	output hdmi_tx_cec, // dummy data
	output rpio_sd_r, // rpio_00_r tok_a_b2f input
	output rpio_sc_r, // rpio_01_r tok_b_m2f input
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
//	input rpio_16_r, // dat_b_m2f
	output rpio_17_r, // gpio17
	output rpio_18_r, // sin
	output rpio_19_r, // scl
//	output rpio_20_r, // trig_bot
//	output rpio_21_r, // dat_a_f2b
//	output rpio_22_r, // sstclk
	output rpio_23_r, // gpio23 / auxtrig
	output rpio_24_r, // trig_mid // driven by SN65EPT23; also goes to CT5TEA
//	input rpio_25_r, // t_shout ct5tea
//	output rpio_26_r, // dat_b_f2m
	input rpio_27_r, // dat_a_t2f
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
	//wire [3:0] rot = { jb[7], jb[3], jb[1], jb[0] }; // as it should be {7,6,5,4,3,2,1,0}
	//wire [3:0] rot = { jb[3], jb[1], jb[0], jb[4] }; // pmod 0.05" breakout board has different wiring {6,4,2,0,7,5,3,1}
	wire [3:0] rot = 4'hb; // 79 us ramp
	wire nclk;
//	assign jb[4] = nclk;
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
	wire trig_top, trig_mid, trig_bot;
	OBUFDS obuf_trigtop (.I(trig_top), .O(hdmi_rx_d2_p), .OB(hdmi_rx_d2_n));
	OBUFDS obuf_trigbot (.I(trig_bot), .O(hdmi_tx_d_p[2]), .OB(hdmi_tx_d_n[2]));
	wire sysclk, sstclk;
	wire sysclk_for_output, sstclk_for_output;
	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_sysclk (.C(sysclk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(sysclk_for_output));
	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_sstclk (.C(sstclk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(sstclk_for_output));
	OBUFDS obuf_sysclk (.I(sysclk_for_output), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	OBUFDS obuf_sstclk (.I(sstclk_for_output), .O(hdmi_rx_clk_p), .OB(hdmi_rx_clk_n));
	wire dat_b_m2f;
	IBUFDS ibuf_dat_b_m2f (.I(hdmi_rx_d_p[0]), .IB(hdmi_rx_d_n[0]), .O(dat_b_m2f));
	wire dat_a_t2f;
	assign dat_a_t2f = rpio_27_r;
//	IBUFDS ibuf_dat_a_t2f (.I(hdmi_rx_d_p[1]), .IB(hdmi_rx_d_n[1]), .O(dat_a_t2f));
	wire dat_a_f2b;
	OBUFDS obuf_dat_a_f2b (.I(dat_a_f2b), .O(hdmi_tx_d_p[0]), .OB(hdmi_tx_d_n[0]));
	wire dat_b_f2m;                     
	OBUFDS obuf_dat_b_f2m (.I(dat_b_f2m), .O(hdmi_tx_d_p[1]), .OB(hdmi_tx_d_n[1]));
	// RPI --------------------------------------
	wire tok_a_b2f = rpio_sd_r; // rpio_00_r input to fpga
	wire tok_b_m2f = rpio_sc_r; // rpio_01_r
	assign rpio_02_r = sysclk; // single-ended sysclk
	assign rpio_03_r = actual_pclk_m; // output to middle alpha
	assign rpio_04_r = actual_pclk_t;
	assign rpio_05_r = tok_a_f2t;
//	assign rpio_06_r = testmode;
//	assign rpio_07_r, // t_sin ct5tea
//	assign rpio_08_r, // t_sclk ct5tea
//	assign rpio_09_r, // t_pclk ct5tea
	assign rpio_10_r = actual_pclk_b;
	assign rpio_11_r = tok_b_f2m;
	assign rpio_12_r = sync;
	assign rpio_13_r = sda;
	assign rpio_14_r = trig_top; // trigtop
	assign rpio_15_r = actual_sclk;
//	assign rpio_16_r, // dat_b_m2f
	assign rpio_17_r = gpio17;
	assign rpio_18_r = sin;
	assign rpio_19_r = scl;
//	assign rpio_20_r = trig_bot; // trigbot
//	assign rpio_21_r, // dat_a_f2b
//	assign rpio_22_r, // sstclk
	assign rpio_23_r = actual_auxtrig; // gpio23
	assign rpio_24_r = trig_mid; // driven by SN65EPT23; also goes to CT5TEA
//	assign rpio_25_r, // t_shout ct5tea
//	assign rpio_26_r, // dat_b_f2m
//	assign rpio_27_r, // dat_a_t2f
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
//	assign trig_mid = 1'b0;
//	assign trig_bot = 1'b0;
//	assign sysclk = 1'b0;
//	assign sstclk = 1'b0;
	assign dat_b_f2m = 1'b0;
	assign dat_a_f2b = 1'b0;
	assign tok_b_f2m = 1'b0;
	// ------------------------------------------
	wire reset = btn[0];
	wire clock;
	IBUFGDS clock_in_diff (.I(ja[4]), .IB(ja[5]), .O(clock));
	//IBUFG clock_in_se (.I(ja[7]), .O(clock));
//	OBUFDS (.I(clock), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	//wire clock_enable;
	//assign clock_enable = sw[0];
	//assign clock_enable = 1'b1;
	//wire clock_oddr1;
	//wire clock_oddr2;
	//wire clock_oddr3;
	//ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst1 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr1));
	//ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst2 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr2));
	//ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_inst3 (.C(clock), .CE(clock_enable), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(clock_oddr3));
	assign gpio17 = sw[0] ? 1'b1 : 1'b0; // alphav2 pin43 = LS_I2C (selects between legacy serial and i2c control over 4 registers: CMPbias, ISEL, SBbias, DBbias)
	//assign gpio17 = clock_oddr1;
	//OBUFDS (.I(clock_oddr1), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	//OBUFDS (.I(1'b0), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));
	//assign hdmi_tx_cec = clock_oddr3;
	//assign hdmi_tx_cec = 0;
	//assign hdmi_rx_cec = clock_oddr3;
//	wire sysclk_raw;
//	BUFG bufg_sysclk (.I(sysclk_raw), .O(sysclk));
	//localparam DIVIDE_RATIO =  2.40; // 100.0 * 6.0 / 1 / DIVIDE_RATIO = 250
	//localparam DIVIDE_RATIO =  4.80; // 100.0 * 6.0 / 1 / DIVIDE_RATIO = 125
	//localparam DIVIDE_RATIO =  7.06; // 100.0 * 6.0 / 1 / DIVIDE_RATIO =  85
	//localparam DIVIDE_RATIO =  7.50; // 100.0 * 6.0 / 1 / DIVIDE_RATIO =  80 never
	//localparam DIVIDE_RATIO =  8.00; // 100.0 * 6.0 / 1 / DIVIDE_RATIO =  75 never
	//localparam DIVIDE_RATIO =  8.57; // 100.0 * 6.0 / 1 / DIVIDE_RATIO =  70 rarely
	//localparam DIVIDE_RATIO =  9.23; // 100.0 * 6.0 / 1 / DIVIDE_RATIO =  65 very rarely
	//localparam DIVIDE_RATIO = 13.33; // 100.0 * 6.0 / 1 / DIVIDE_RATIO =  45 rarely
	//localparam DIVIDE_RATIO = 15.00; // 100.0 * 6.0 / 1 / DIVIDE_RATIO =  40 rarely
	//localparam DIVIDE_RATIO = 20.00; // 100.0 * 6.0 / 1 / DIVIDE_RATIO =  30 sometimes
	//localparam DIVIDE_RATIO = 10.5; // 127.22 * 6.0 / 1 / 10.5 = 80
	// 600 - 1200 MHz range VCO frequency
	wire c0, c1, c2, c3, c4, c5, c6, c7;
	wire c8, c9, ca, cb, cc, cd, ce, cf, cg, ch;
//	assign ca = 0;
//	assign cb = 0;
//	assign cc = 0;
//	assign cd = 0;
//	assign ce = 0;
//	assign cf = 0;
	if (0) begin
		wire mmcm_locked0, mmcm_locked1;
		MMCM_advanced #(
			.CLOCK1_PERIOD_NS(10.0), .D(1), .M(10.24),
			.CLKOUT0_DIVIDE(12), //  85 MHz
			.CLKOUT1_DIVIDE(11), //  93
			.CLKOUT2_DIVIDE(10), // 102
			.CLKOUT3_DIVIDE(9),  // 114
			.CLKOUT4_DIVIDE(8),  // 128
			.CLKOUT5_DIVIDE(1), // 1024
			.CLKOUT6_DIVIDE(1)  // 1024
				) mymmcm0 (
			.clock1_in(clock), .reset(reset), .locked(mmcm_locked0),
			.clock0_out_p(c0), .clock0_out_n(), .clock1_out_p(c1), .clock1_out_n(),
			.clock2_out_p(c2), .clock2_out_n(), .clock3_out_p(c3), .clock3_out_n(),
			.clock4_out(c4), .clock5_out(), .clock6_out());
		MMCM_advanced #(
			.CLOCK1_PERIOD_NS(10.0), .D(1), .M(10.24),
			.CLKOUT0_DIVIDE(7), // 146 MHz
			.CLKOUT1_DIVIDE(6), // 171
			.CLKOUT2_DIVIDE(5), // 205
			.CLKOUT3_DIVIDE(4), // 256
			.CLKOUT4_DIVIDE(4), // 256
			.CLKOUT5_DIVIDE(1), // 1024
			.CLKOUT6_DIVIDE(1)  // 1024
				) mymmcm1 (
			.clock1_in(clock), .reset(reset), .locked(mmcm_locked1),
			.clock0_out_p(c5), .clock0_out_n(), .clock1_out_p(c6), .clock1_out_n(),
			.clock2_out_p(c7), .clock2_out_n(), .clock3_out_p(c8), .clock3_out_n(),
			.clock4_out(c9), .clock5_out(), .clock6_out());
		reg [15:0] select = 0;
		reg [15:0] select_buffered = 0;
		always @(posedge clock) begin
			select <= 0;
			if (reset) begin
			end else begin
				select[rot] <= 1'b1;
			end
			select_buffered <= select;
		end
		// as recommended by https://docs.xilinx.com/r/en-US/ug949-vivado-design-methodology/Clock-Multiplexing
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_a (.I0(c0), .I1(c1), .S(select_buffered[0]), .O(ca));
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_b (.I0(ca), .I1(c2), .S(select_buffered[1]), .O(cb));
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_c (.I0(cb), .I1(c3), .S(select_buffered[2]), .O(cc));
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_d (.I0(cc), .I1(c4), .S(select_buffered[3]), .O(cd));
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_e (.I0(cd), .I1(c5), .S(select_buffered[4]), .O(ce));
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_f (.I0(ce), .I1(c6), .S(select_buffered[5]), .O(cf));
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_g (.I0(cf), .I1(c7), .S(select_buffered[6]), .O(cg));
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel_h (.I0(cg), .I1(c8), .S(select_buffered[7]), .O(ch));
		BUFGMUX #(.CLK_SEL_TYPE("SYNC")) clock_sel   (.I0(ch), .I1(c9), .S(select_buffered[8]), .O(sysclk));
	end else if (1) begin // useful for pcb1 that can only do single-ended sysclk (up to ~30 MHz)
		wire mmcm_locked0;
		MMCM_advanced #(
			.CLOCK1_PERIOD_NS(10.0), .D(1), .M(10.0),
			.CLKOUT0_DIVIDE(24.0), // 41.667 MHz
			.CLKOUT1_DIVIDE(24*4), // 10.416 MHz
			.CLKOUT2_DIVIDE(10), // 100.0 MHz (for sstclk)
			.CLKOUT3_DIVIDE(1), // 1024
			.CLKOUT4_DIVIDE(1), // 1024
			.CLKOUT5_DIVIDE(1), // 1024
			.CLKOUT6_DIVIDE(1)  // 1024
				) mymmcm0 (
			.clock1_in(clock), .reset(reset), .locked(mmcm_locked0),
			.clock0_out_p(c0), .clock0_out_n(), .clock1_out_p(c1), .clock1_out_n(),
			.clock2_out_p(c2), .clock2_out_n(), .clock3_out_p(c3), .clock3_out_n(),
			.clock4_out(c4), .clock5_out(), .clock6_out());
		assign sysclk = c0;
		assign sstclk = c2;
		assign led4_g = mmcm_locked0;
		assign nclk = c1;
	end else begin
		assign sysclk = clock;
	end
	reg [3:0] rot_buffered = 0;
	always @(posedge clock) begin
		rot_buffered <= rot;
	end
	wire header;
	wire [3:0] nybble;
	wire [1:0] nybble_counter;
	wire [15:0] data_word;
	wire msn; // most significant nybble
	alpha_readout alpha_readout (.clock(sysclk), .reset(reset), .dat_a_t2f(dat_a_t2f), .header(header), .msn(msn), .nybble(nybble), .nybble_counter(nybble_counter), .data_word(data_word));
	assign jb[3:0] = nybble;
	assign jb[4] = msn;
	assign jb[5] = 0;
	assign jb[6] = header;
	assign jb[7] = 0;
	wire [3:0] CMPbias_MSN = 4'h8;
	wire [3:0] ISEL_MSN    = rot_buffered;
	wire [3:0] SBbias_MSN  = 4'h8;
	wire [3:0] DBbias_MSN  = 4'h8;
	wire [11:0] CMPbias = {CMPbias_MSN, 8'h44};
	wire [11:0] ISEL    = {ISEL_MSN,    8'h44};
	wire [11:0] SBbias  = {SBbias_MSN,  8'h44};
	wire [11:0] DBbias  = {DBbias_MSN,  8'h44};
	assign led[3] = rot_buffered[3];
	assign led[2] = rot_buffered[2];
	assign led[1] = rot_buffered[1];
	assign led[0] = rot_buffered[0];
//	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_sysclk0 (.C(sysclk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(jc[0]));
//	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_sysclk1 (.C(sysclk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(jc[1]));
//	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_sysclk2 (.C(sysclk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(jc[2]));
//	ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_sysclk3 (.C(sysclk), .CE(1'b1), .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0), .Q(jc[3]));
	localparam BUTTON_PICKOFF = 6;
	reg [BUTTON_PICKOFF:0] button1_pipeline = 0;
	reg [BUTTON_PICKOFF:0] button2_pipeline = 0;
	reg [BUTTON_PICKOFF:0] button3_pipeline = 0;
	reg startup_sequence_1 = 0;
	reg startup_sequence_2 = 0;
	reg startup_sequence_3 = 0;
	always @(posedge sysclk) begin
		if (reset) begin
			button1_pipeline <= 0;
			button2_pipeline <= 0;
			button3_pipeline <= 0;
			startup_sequence_1 <= 0;
			startup_sequence_2 <= 0;
			startup_sequence_3 <= 0;
		end else begin
			startup_sequence_1 <= 0;
			startup_sequence_2 <= 0;
			startup_sequence_3 <= 0;
			if (button1_pipeline[BUTTON_PICKOFF:BUTTON_PICKOFF-1]==2'b01) begin
				startup_sequence_1 <= 1;
			end
			if (button2_pipeline[BUTTON_PICKOFF:BUTTON_PICKOFF-1]==2'b01) begin
				startup_sequence_2 <= 1;
			end
			if (button3_pipeline[BUTTON_PICKOFF:BUTTON_PICKOFF-1]==2'b01) begin
				startup_sequence_3 <= 1;
			end
			button1_pipeline <= { button1_pipeline[BUTTON_PICKOFF-1:0], btn[1] };
			button2_pipeline <= { button2_pipeline[BUTTON_PICKOFF-1:0], btn[2] };
			button3_pipeline <= { button3_pipeline[BUTTON_PICKOFF-1:0], btn[3] };
		end
	end
	wire trig;
	alpha_control alpha_control (.clock(sysclk), .reset(reset), .startup_sequence_1(startup_sequence_1), .startup_sequence_2(startup_sequence_2), .startup_sequence_3(startup_sequence_3), .sync(sync), .dreset(dreset), .tok_a_f2t(tok_a_f2t), .scl(scl), .sda_in(sda_in), .sda_out(sda_out), .sin(sin), .pclk(pclk), .sclk(sclk), .trig_top(trig), .CMPbias(CMPbias), .ISEL(ISEL), .SBbias(SBbias), .DBbias(DBbias));
	assign trig_top = trig;
	//assign trig_mid = sw[0] ? trig : 1'b0; // trig_mid is on a 3.3V bank but only ever reaches 200mV
	assign trig_mid = 1'b0;
	assign trig_bot = sw[1] ? trig : 1'b0;
endmodule

module alpha_control_tb;
	localparam half_clock_period = 4;
	localparam clock_period = 2*half_clock_period;
	reg clock = 0;
	reg reset = 1;
	reg startup_sequence_1 = 0;
	reg startup_sequence_2 = 0;
	reg startup_sequence_3 = 0;
	wire sync, dreset, tok_a_f2t;
	wire scl, sda_in, sda_out, sin, pclk, sclk, trig_top;
	initial begin
		reset <= 1; #101; reset <= 0;
		#100;
		startup_sequence_3 <= 1; #half_clock_period; startup_sequence_3 <= 0;
		#100;
		startup_sequence_2 <= 1; #half_clock_period; startup_sequence_2 <= 0;
		#5000;
		startup_sequence_1 <= 1; #half_clock_period; startup_sequence_1 <= 0;
		#400;
	end
	always begin
		clock <= ~clock;
		#half_clock_period;
	end
	alpha_control alpha_control (.clock(clock), .reset(reset), .startup_sequence_1(startup_sequence_1), .startup_sequence_2(startup_sequence_2), .startup_sequence_3(startup_sequence_3), .sync(sync), .dreset(dreset), .tok_a_f2t(tok_a_f2t), .scl(scl), .sda_in(sda_in), .sda_out(sda_out), .sin(sin), .pclk(pclk), .sclk(sclk), .trig_top(trig_top));
endmodule

module alpha_control (
	input clock, reset, startup_sequence_1, startup_sequence_2, startup_sequence_3,
	input sda_in,
	input [11:0] CMPbias, ISEL, SBbias, DBbias,
	output reg sync, dreset, tok_a_f2t, scl, sda_out, sin, pclk, sclk, trig_top
);
	reg [31:0] counter1 = 0;
	reg [31:0] counter2 = 0;
	reg [31:0] counter3 = 0;
	reg mode3 = 0;
	reg mode2 = 0;
	reg mode1 = 0;
	localparam TIMING_CONSTANT = 100; // 20=bad; 70=bad; 100=good; 150=bad; 200=worse
	localparam ADC_CONVERSION_TIME = 2*4096;
	always @(posedge clock) begin
		if (reset) begin
			counter3 <= 0;
			sync <= 0;
			dreset <= 0;
			mode3 <= 0;
		end else begin
			counter3 <= counter3 + 1'b1;
			if (mode3==1'b1) begin
				if (1*TIMING_CONSTANT==counter3) begin
					dreset <= 1'b1;
				end else if (2*TIMING_CONSTANT==counter3) begin
					dreset <= 0;
				end else if (3*TIMING_CONSTANT==counter3) begin
					sync <= 1'b1;
				end else if (4*TIMING_CONSTANT==counter3) begin
					sync <= 0;
				end else if (5*TIMING_CONSTANT==counter3) begin
					mode3 <= 1'b0;
				end else begin
				end
			end
			if (startup_sequence_3) begin
				counter3 <= 0;
				sync <= 0;
				dreset <= 0;
				mode3 <= 1'b1;
			end
		end
	end
	always @(posedge clock) begin
		if (reset) begin
			counter1 <= 0;
			tok_a_f2t <= 0;
			trig_top <= 0;
			mode1 <= 0;
		end else begin
			counter1 <= counter1 + 1'b1;
			if (mode1==1'b1) begin
				if (1*TIMING_CONSTANT==counter1) begin
					trig_top <= 1'b1;
				end else if (2*TIMING_CONSTANT==counter1) begin
					trig_top <= 0;
				end else if (3*TIMING_CONSTANT+ADC_CONVERSION_TIME==counter1) begin
					tok_a_f2t <= 1'b1;
				end else if (4*TIMING_CONSTANT+ADC_CONVERSION_TIME==counter1) begin
					tok_a_f2t <= 0;
				end else if (5*TIMING_CONSTANT+ADC_CONVERSION_TIME==counter1) begin
					mode1 <= 1'b0;
				end else begin
				end
			end
			if (startup_sequence_1) begin
				counter1 <= 0;
				tok_a_f2t <= 0;
				trig_top <= 0;
				mode1 <= 1'b1;
			end
		end
	end
	localparam LEGACY_SERIAL_CONSTANT = 50;
	wire [1:0] CMPbias_address = 2'b00;
	wire [1:0] ISEL_address    = 2'b01;
	wire [1:0] SBbias_address  = 2'b10;
	wire [1:0] DBbias_address  = 2'b11;
	wire [15:0] data_word [3:0];
	assign data_word[0] = { 2'b00, CMPbias_address, CMPbias };
	assign data_word[1] = { 2'b00, ISEL_address,    ISEL };
	assign data_word[2] = { 2'b00, SBbias_address,  SBbias };
	assign data_word[3] = { 2'b00, DBbias_address,  DBbias };
	reg [3:0] bit_counter = 0;
	reg [1:0] word_counter = 0;
	always @(posedge clock) begin
		if (reset) begin
			counter2 <= 0;
			sin <= 0;
			sclk <= 0;
			pclk <= 0;
			bit_counter <= 15;
			word_counter <= 0;
			mode2 <= 0;
		end else begin
			counter2 <= counter2 + 1'b1;
			if (mode2==1'b1) begin
				if          (1*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (2*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (3*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (4*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (5*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (6*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (7*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (8*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (9*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (10*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (11*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (12*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (13*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (14*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (15*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (16*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (17*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (18*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (19*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (20*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (21*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (22*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (23*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (24*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (25*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (26*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (27*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (28*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (29*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (30*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (31*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (32*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (33*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (34*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (35*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (36*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (37*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (38*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (39*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (40*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (41*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (42*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (43*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (44*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (45*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
					bit_counter <= bit_counter - 1'b1;
				end else if (46*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= data_word[word_counter][bit_counter];
				end else if (47*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b1;
				end else if (48*LEGACY_SERIAL_CONSTANT==counter2) begin
					sclk <= 1'b0;
				end else if (49*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= 1'b0;
				end else if (50*LEGACY_SERIAL_CONSTANT==counter2) begin
					pclk <= 1'b1;
				end else if (63*LEGACY_SERIAL_CONSTANT==counter2) begin
					pclk <= 1'b0;
				end else if (64*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= 1'b1;
				end else if (65*LEGACY_SERIAL_CONSTANT==counter2) begin
					pclk <= 1'b1;
				end else if (78*LEGACY_SERIAL_CONSTANT==counter2) begin
					pclk <= 1'b0;
				end else if (79*LEGACY_SERIAL_CONSTANT==counter2) begin
					sin <= 1'b0;
				end else if (81*LEGACY_SERIAL_CONSTANT==counter2) begin
					if (word_counter==2'b11) begin
						mode2 <= 1'b0;
					end else begin
						counter2 <= 0;
						sin <= 0;
						sclk <= 0;
						pclk <= 0;
						bit_counter <= 15;
						word_counter <= word_counter + 1'b1;
					end
				end else begin
					// no operation
				end
			end
			if (startup_sequence_2) begin
				counter2 <= 0;
				sin <= 0;
				sclk <= 0;
				pclk <= 0;
				bit_counter <= 15;
				word_counter <= 0;
				mode2 <= 1'b1;
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

module alpha_readout_tb;
	localparam half_clock_period = 16;
	localparam clock_period = 2*half_clock_period;
	reg clock = 0;
	reg reset = 1;
	reg dat_a_t2f = 0;
	wire header;
	wire [3:0] nybble;
	wire [1:0] nybble_counter;
	wire [15:0] data_word;
	wire msn; // most significant nybble
	initial begin
		reset <= 1;
		#100;
		reset <= 0;
		#100;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period;
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period;
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		// 0xa
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		// 0x1
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period;
		// 0xf
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period;
		// 0xa
		dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// 0x3
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period;
		// 0x4
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
		// 0x5
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period;
		// 0x6
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 1; #clock_period; dat_a_t2f <= 0; #clock_period;
		// blah
		dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period; dat_a_t2f <= 0; #clock_period;
	end
	alpha_readout alpha_readout (.clock(clock), .reset(reset), .dat_a_t2f(dat_a_t2f), .header(header), .msn(msn), .nybble(nybble), .nybble_counter(nybble_counter), .data_word(data_word));
	always begin
		clock <= ~clock;
		#half_clock_period;
	end
endmodule

module alpha_readout (
	input clock, reset, dat_a_t2f,
	output [3:0] nybble,
	output reg header = 0,
	output msn,
	output [1:0] nybble_counter,
	output reg [15:0] data_word = 0
);
	localparam DATA_WIDTH = 16;
	localparam METASTABILITY_BUFFER_SIZE = 3;
	localparam EXTRA_WIDTH = 4;
	localparam SR_HIGH_BIT = DATA_WIDTH + METASTABILITY_BUFFER_SIZE + EXTRA_WIDTH;
	localparam SR_PICKOFF = SR_HIGH_BIT - 4;
	reg [SR_HIGH_BIT:0] data_sr = 0;
	reg [3:0] data_bit_counter = 0;
	reg [12:0] data_word_counter = 15;
	wire [15:0] ALFA = 16'ha1fa;
	always @(posedge clock) begin
		if (reset) begin
			data_bit_counter <= 15;
			data_word_counter <= 0;
			data_word <= 0;
			header <= 0;
		end else begin
			data_sr <= { data_sr[SR_HIGH_BIT-1:0], dat_a_t2f };
			if (data_bit_counter==0) begin
				data_bit_counter <= 15;
				data_word <= data_sr[SR_PICKOFF-1-:16];
				data_word_counter <= data_word_counter + 1'b1;
				header <= 0;
			end else begin
				data_bit_counter <= data_bit_counter - 1'b1;
			end
			if (data_sr[SR_PICKOFF-1-:16]==ALFA) begin // WARNING: this might accidentally re-bitslip align on data 0x1fa from channel 0xa
				data_bit_counter <= 15;
				data_word_counter <= 0;
				header <= 1;
				data_word <= data_sr[SR_PICKOFF-1-:16];
			end
		end
	end
	assign msn = nybble_counter==3 ? 1'b1 : 1'b0;
	assign nybble_counter = data_bit_counter[3:2];
	wire [3:0] nyb [3:0];
	assign nyb[0] = data_word[3:0];
	assign nyb[1] = data_word[7:4];
	assign nyb[2] = data_word[11:8];
	assign nyb[3] = data_word[15:12];
	assign nybble = nyb[nybble_counter];
endmodule

