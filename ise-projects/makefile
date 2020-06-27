
ise_clean :
	@find -depth -mindepth 2 -type d -name "ipcore_dir" -prune -o -type d -exec rm -rf "{}" \;
	@find -mindepth 2 -type d -name "ipcore_dir" -prune -o -type f \( -name "*.xise" -o -name "*.wcfg" -o -name ".gitconfig" -o -name "*.openocd-cfg" -o -name "*.sh" -o -name "*.bit" -o -name "*.bin" -o -name "*.xco" \) -prune -o -exec rm "{}" \;

clean :
	$(MAKE) ise_clean

default :

