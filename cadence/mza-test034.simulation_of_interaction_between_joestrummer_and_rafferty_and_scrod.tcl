clear -all
analyze -v2k verilog/src/mza-test034.simulation_of_interaction_between_joestrummer_and_rafferty_and_scrod.v ; # for verilog-2001
elaborate -top {joestrummer_and_rafferty_and_scrod_tb} -bbox_m OBUFDS -bbox_m BUFGDS -bbox_m BUFIO2 -bbox_m BUFG -bbox_m BUFGMUX -bbox_m BUFPLL -bbox_m PLL_ADV -bbox_m PLL_BASE -bbox_m OSERDESE2 -bbox_m OSERDES2 -bbox_m ISERDES2 -bbox_m ODDR -bbox_m IDDR -bbox_m ODDR2 -bbox_m IDDR2 -bbox_m IBUFDS -bbox_m IBUFGDS -bbox_m BUFR
get_design_info -list multiple_driven

