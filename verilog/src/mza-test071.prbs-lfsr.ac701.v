`timescale 1ns / 1ps

// written 2025-03-04 by mza
// last updated 2025-03-06 by mza

// cd /opt/Xilinx/Vivado/2023.2/data/xicom/cable_drivers/lin64/install_script/install_drivers; sudo ./install_drivers

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

module PRBS_LFSR #(
	parameter OUTPUT_WIDTH = 8
) (
	input SYSCLK_P, SYSCLK_N, // 200 MHz
	output USER_SMA_CLOCK_P, USER_SMA_CLOCK_N,
	output USER_SMA_GPIO_P, USER_SMA_GPIO_N,
	output GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0
);
	wire sysclk;
	IBUFDS iclk (.I(SYSCLK_P), .IB(SYSCLK_N), .O(sysclk));
	wire clock, reset, sysclk_pll_locked;
	assign reset = 0;
	MMCM_advanced #(
		.CLOCK1_PERIOD_NS(5.0), .D(1), .M(5), // Fvco = [600, 1440] MHz
		.CLKOUT0_DIVIDE(128.0), // 7.8 MHz
		.CLKOUT1_DIVIDE(1), //
		.CLKOUT2_DIVIDE(1), //
		.CLKOUT3_DIVIDE(1), //
		.CLKOUT4_DIVIDE(1), //
		.CLKOUT5_DIVIDE(1), //
		.CLKOUT6_DIVIDE(1)  //
			) mymmcm0 (
		.clock1_in(sysclk), .reset(reset), .locked(sysclk_pll_locked),
		.clock0_out_p(clock), .clock0_out_n(), .clock1_out_p(), .clock1_out_n(),
		.clock2_out_p(), .clock2_out_n(), .clock3_out_p(), .clock3_out_n(),
		.clock4_out(), .clock5_out(), .clock6_out());
	//OBUF oclk1 (.I(sysclk), .O(USER_SMA_CLOCK_P));
	//OBUF oclk2 (.I(clock), .O(USER_SMA_CLOCK_N));
	if (0) begin
		reg [26:0] counter = 0;
		always @(posedge clock) begin
			counter <= counter + 1'b1;
		end
		OBUF blah_6 (.I(counter[0]), .O(USER_SMA_CLOCK_P));
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = counter[26:23];
		OBUF blah_p (.I(counter[2]), .O(USER_SMA_GPIO_P));
		OBUF blah_n (.I(counter[1]), .O(USER_SMA_GPIO_N));
	end else if (1) begin
		wire [OUTPUT_WIDTH-1:0] rand;
		prbs_wide #(.OUTPUT_WIDTH(OUTPUT_WIDTH)) pw (.clock(clock), .reset(reset), .rand(rand));
		//prbs_wide #(.OUTPUT_WIDTH(OUTPUT_WIDTH)) pw (.clock(sysclk), .reset(reset), .rand(rand));
		OBUF blah_7 (.I(rand[7]), .O(USER_SMA_GPIO_P));
		OBUF blah_6 (.I(rand[6]), .O(USER_SMA_GPIO_N));
		OBUF blah_5 (.I(rand[5]), .O(USER_SMA_CLOCK_P));
		OBUF blah_4 (.I(rand[4]), .O(USER_SMA_CLOCK_N));
		assign { GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = rand[3:0];
	end else begin
		wire [31:0] rand32;
		prbs #(.WIDTH(32), .TAPA(28), .TAPB(31)) lfsr32 (.clock(clock), .reset(reset), .word(rand32));
		assign { USER_SMA_GPIO_P, USER_SMA_GPIO_N, USER_SMA_CLOCK_P, USER_SMA_CLOCK_N, GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = rand32[7:0];
	end
endmodule

