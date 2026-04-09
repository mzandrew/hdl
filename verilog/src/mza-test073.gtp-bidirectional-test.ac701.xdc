# modified from xilinx original 2025-03-06 by mza
# last modified 2025-03-24 by mza

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.config.SPI_opcode 0x6B [current_design ]
set_property INTERNAL_VREF 0.9 [get_iobanks 13]

create_clock -period 5.000 -name sysclk_p -waveform {0.000 2.500} -add [get_ports SYSCLK_P]

set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets mymmcm0/clock0_out_p];

# 200 MHz sysclk: pdf page 3, 8
set_property PACKAGE_PIN R3 [get_ports SYSCLK_P]
set_property PACKAGE_PIN P3 [get_ports SYSCLK_N]
set_property IOSTANDARD LVDS_25 [get_ports SYSCLK_P]
set_property IOSTANDARD LVDS_25 [get_ports SYSCLK_N]
set_property DIFF_TERM TRUE [get_ports SYSCLK_P]

# LEDs: pdf page 14, 21
set_property PACKAGE_PIN M26 [get_ports GPIO_LED_0]
set_property PACKAGE_PIN T24 [get_ports GPIO_LED_1]
set_property PACKAGE_PIN T25 [get_ports GPIO_LED_2]
set_property PACKAGE_PIN R26 [get_ports GPIO_LED_3]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_0]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_1]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_2]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_3]

# user_gpio sma connectors (1.5V bank): pdf page 3, 8
set_property PACKAGE_PIN T8 [get_ports USER_SMA_GPIO_P]
set_property PACKAGE_PIN T7 [get_ports USER_SMA_GPIO_N]
set_property IOSTANDARD LVCMOS25 [get_ports USER_SMA_GPIO_P]
set_property IOSTANDARD LVCMOS25 [get_ports USER_SMA_GPIO_N]
set_property DRIVE 24 [get_ports USER_SMA_GPIO_P]
set_property DRIVE 24 [get_ports USER_SMA_GPIO_N]
set_property SLEW FAST [get_ports USER_SMA_GPIO_P]
set_property SLEW FAST [get_ports USER_SMA_GPIO_N]

# user_clk (vcco_vadj=1.8, 2.5, 3.3, controllable by PMBus addr 102): pdf page 3, 22
set_property PACKAGE_PIN J23 [get_ports USER_SMA_CLOCK_P]
set_property PACKAGE_PIN H23 [get_ports USER_SMA_CLOCK_N]
set_property IOSTANDARD LVDS_25 [get_ports USER_SMA_CLOCK_P]
set_property IOSTANDARD LVDS_25 [get_ports USER_SMA_CLOCK_N]
set_property DRIVE 24 [get_ports USER_SMA_CLOCK_P]
set_property DRIVE 24 [get_ports USER_SMA_CLOCK_N]
set_property SLEW FAST [get_ports USER_SMA_CLOCK_P]
set_property SLEW FAST [get_ports USER_SMA_CLOCK_N]

# bank_213 gtp quad:
set_property PACKAGE_PIN AE7 [get_ports SMA_MGT_TX_P]
set_property PACKAGE_PIN AF7 [get_ports SMA_MGT_TX_N]
set_property PACKAGE_PIN AC10 [get_ports SFP_MGT_TX_P]
set_property PACKAGE_PIN AD10 [get_ports SFP_MGT_TX_N]
set_property PACKAGE_PIN AE11 [get_ports SMA_MGT_RX_P]
set_property PACKAGE_PIN AF11 [get_ports SMA_MGT_RX_N]
set_property PACKAGE_PIN AC12 [get_ports SFP_MGT_RX_P]
set_property PACKAGE_PIN AD12 [get_ports SFP_MGT_RX_N]
#set_property PACKAGE_PIN AA13 [get_ports SFP_MGT_CLK0_P]
#set_property PACKAGE_PIN AB13 [get_ports SFP_MGT_CLK0_N]
#set_property PACKAGE_PIN AA11 [get_ports SFP_MGT_CLK1_P]
#set_property PACKAGE_PIN AB11 [get_ports SFP_MGT_CLK1_N]
#set_property PACKAGE_PIN AF15 [get_ports MGTRREF_213]
#set_property IOSTANDARD LVDS_25 [get_ports SFP_MGT_CLK0_P]
#set_property IOSTANDARD LVDS_25 [get_ports SFP_MGT_CLK0_N]
#set_property IOSTANDARD LVDS_25 [get_ports SFP_MGT_CLK1_P]
#set_property IOSTANDARD LVDS_25 [get_ports SFP_MGT_CLK1_N]
#set_property IOSTANDARD LVDS_25 [get_ports MGTRREF_213]

# bank_216 gtp quad:
#set_property PACKAGE_PIN F11 [get_ports PCIE_CLK_QO_P]
#set_property PACKAGE_PIN E11 [get_ports PCIE_CLK_QO_N]
#set_property PACKAGE_PIN F13 [get_ports No]
#set_property PACKAGE_PIN E13 [get_ports No]
#set_property PACKAGE_PIN A15 [get_ports MGTRREF_216]
#set_property IOSTANDARD LVDS_25 [get_ports PCIE_CLK_QO_P]
#set_property IOSTANDARD LVDS_25 [get_ports PCIE_CLK_QO_N]
#set_property IOSTANDARD LVDS_25 [get_ports No]
#set_property IOSTANDARD LVDS_25 [get_ports No]
#set_property IOSTANDARD LVDS_25 [get_ports MGTRREF_216]

#[Route 35-468] The router encountered 4 pins that are both setup-critical and hold-critical and tried to fix hold violations at the expense of setup slack. Such pins are:
set_false_path -to [ get_pins reset2_copy1_on_raw_bit_clock_reg/D ];
set_false_path -to [ get_pins reset3_copy1_on_raw_bit_clock_reg/D ];
set_false_path -to [ get_pins reset4_copy1_on_other_word_clock_reg/D ];
set_false_path -to [ get_pins o7s/reset_copy1_on_word_clock_reg/D ];

# no_output_delay:
set_false_path -to [ get_ports GPIO_LED_0 ];
set_false_path -to [ get_ports GPIO_LED_1 ];
set_false_path -to [ get_ports GPIO_LED_2 ];
set_false_path -to [ get_ports GPIO_LED_3 ];

