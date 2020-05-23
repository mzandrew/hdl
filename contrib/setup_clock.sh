#!/bin/bash -e

declare localdir=$(cd $(dirname $(readlink -f $0)); pwd)
cd $localdir
declare url=""

url="https://raw.githubusercontent.com/mgrau/ad9959/master/minimal_clk.c"
if [ ! -e minimal_clk.c ]; then
	wget $url
fi
if [ ! -e minimal_clk ]; then
	gcc minimal_clk.c -o minimal_clk
fi

#sudo ./minimal_clk -c1 10.0M -q # gp_clk0
sudo ./minimal_clk -c2 10.0M -q # gp_clk2

