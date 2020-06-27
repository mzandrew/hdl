# written 2018-09-19 by mza
# ise_clean section written 2020-06-26 by mza
# last updated 2020-06-26 by mza

SOURCE="/home/mza/build/hdl/verilog/src/"
DEST="/home/mza/build/hdl/ise-projects/mza-test019.serdes/"
NAME1="mza_test019_serdes"
NAME2="mza-test019.serdes"

ise_clean :
	@find -depth -mindepth 2 -type d -name "ipcore_dir" -prune -o -type d -exec rm -rf "{}" \;
	@find -mindepth 2 -type d -name "ipcore_dir" -prune -o -type f \( -name "*.xise" -o -name "*.wcfg" -o -name ".gitconfig" -o -name "*.openocd-cfg" -o -name "*.sh" -o -name "*.bit" -o -name "*.bin" -o -name "*.xco" -o -iname "makefile" \) -prune -o -exec rm "{}" \;

clean :
	$(MAKE) ise_clean

default :
	cd $(DEST)
	xst -intstyle ise -ifn $(DEST)/$(NAME1).xst" -ofn "$(DEST)/$(NAME1).syr"
	ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc $(SOURCE)/$(NAME2).ucf -p xc6slx150t-fgg676-3 $(NAME1).ngc $(NAME1).ngd
	map -intstyle ise -p xc6slx150t-fgg676-3 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o $(NAME1)_map.ncd $(NAME1).ngd $(NAME1).pcf
	par -w -intstyle ise -ol high -mt off $(NAME1)_map.ncd $(NAME1).ncd $(NAME1).pcf
	trce -intstyle ise -v 3 -s 3 -n 3 -fastpaths -xml $(NAME1).twx $(NAME1).ncd -o $(NAME1).twr $(NAME1).pcf
	bitgen -intstyle ise -f $(NAME1).ut $(NAME1).ncd

