#!/bin/bash -e

declare number_of_transfers_per_data_word=0
if [ ! -z "$1" ]; then
	number_of_transfers_per_data_word=$1
fi
declare dir="../ise-projects"
if [ $number_of_transfers_per_data_word -eq 1 ]; then
	filename="mza_test044_simple_parallel_interface_and_pollable_memory_althea/myalthea.1-byte-data-mode.bit"
elif [ $number_of_transfers_per_data_word -eq 2 ]; then
	filename="mza_test044_simple_parallel_interface_and_pollable_memory_althea/myalthea.2-byte-data-mode.bit"
elif [ $number_of_transfers_per_data_word -eq 3 ]; then
	filename="mza_test044_simple_parallel_interface_and_pollable_memory_althea/myalthea.3-byte-data-mode.bit"
elif [ $number_of_transfers_per_data_word -eq 4 ]; then
	filename="mza_test044_simple_parallel_interface_and_pollable_memory_althea/myalthea.4-byte-data-mode.bit"
else
	filename="mza_test044_simple_parallel_interface_and_pollable_memory_althea/myalthea.bit"
fi
declare string="adapter driver bcm2835gpio; bcm2835gpio_peripheral_base 0x3F000000; adapter speed 1000; bcm2835gpio_jtag_nums 18 25 17 27; transport select jtag; source [find cpld/xilinx-xc6s.cfg]; init; xc6s_program xc6s.tap; pld load 0 ${dir}/${filename}; exit"
echo $string

#sudo openocd -f mza_test044_simple_parallel_interface_and_pollable_memory_althea.openocd-cfg
sudo openocd --command "$string"

