#!/usr/bin/env python3

# written 2023-08-23 by mza
# based on alpha_readout.py
# based on protodune_LBLS_readout.py
# with help from https://realpython.com/pygame-a-primer/#displays-and-surfaces
# last updated 2024-11-22 by mza

# todo:
# plot thresholds (pull from protodune_readout.py)
# plot waveforms (pull from alpha_readout.py)
# plot trigger memory

from generic import * # hex, eng
import althea
import sys
sys.path.append("../../bin/embedded/sensors")
import board, generic, ina260_adafruit, stts751
BANK_ADDRESS_DEPTH = 13

NUMBER_OF_CHANNELS_PER_ASIC = 8
gui_update_period = 0.2 # in seconds
cliff = "upper"
step_size_for_threshold_scan = 4
pedestal_dac_12bit_2v5 = int(4096*1.21/2.5)
#print(hex(pedestal_dac_12bit_2v5,3))
Trig4xVofs = pedestal_dac_12bit_2v5
Trig16xVofs = pedestal_dac_12bit_2v5
# for a trigger capture bit clock of 1017 MHz:
#wbias_odd  = 1590 #  3.9 ns
#wbias_even = 1250 #  7.8 ns
#wbias_dual = 1130 # 12.4 to 15.4 ns (depending on timing of stimuli); but depends on above...
# for a trigger capture bit clock of 1017/3 = 339 MHz
#wbias_odd  = 1250 # 12 ns
#wbias_even = 1050 # 24 ns
#wbias_dual = 1130 # ???
# for a trigger capture bit clock of 1017/3 = 339 MHz
#wbias_odd  = 1340 #  8.9 ns
#wbias_even = 1110 # 17.8 ns
#wbias_dual = 1010 # 35.6 ns
# for a trigger capture bit clock of 1017/12 = 84.8 MHz
wbias_odd  =  970 #  35.4 ns
wbias_even =  860 #  68.8 ns
wbias_dual =  750 #  119-138 ns
wbias_bump_amount = 10
MIN_TRIGGER_WIDTH_TO_EXPECT = 1
MAX_TRIGGER_WIDTH_TO_EXPECT = 31
default_expected_dual_channel_trigger_width = 8
default_expected_even_channel_trigger_width = 5
default_hs_data_ss_incr = 4
default_hs_data_capture = default_hs_data_ss_incr - 2
default_spgin = 0 # default state of hs_data stream (page 40 of schematics)
default_scaler_timeout = 127.22e6 * gui_update_period
default_hs_data_offset = 4 # input capture is 128 bits, but we need 12*4 bits to get a value, so it is only meaningful to set this between 0 and 79 (128-48=80)
default_hs_data_ratio = 3 # this is currently hardcoded in the firmware as a parameter
default_tpg = 0xb05 # only accepts the lsb=1 after having written a 1 in that position already

NUMBER_OF_STORAGE_WINDOWS_ON_ASIC = 256
RATIO_OF_TRG_CLOCK_TO_SST_CLOCK = 4
TRIGGER_MEMORY_READOUT_SIZE = NUMBER_OF_STORAGE_WINDOWS_ON_ASIC * RATIO_OF_TRG_CLOCK_TO_SST_CLOCK
TRIGGER_MEMORY_PLOT_WIDTH = NUMBER_OF_STORAGE_WINDOWS_ON_ASIC * RATIO_OF_TRG_CLOCK_TO_SST_CLOCK + 6
TRIGGER_MEMORY_PLOT_HEIGHT = 64 + 6

MIDRANGE = 0xd55
EXTRA_OFFSET = 500
CHANNEL_OFFSET = 50
QUAD_CHANNEL_OFFSET = 300

# the following lists of values are for the trigger_gain x1, x4 and x16 settings:
#default_number_of_steps_for_threshold_scan = [ 64, 128, 512 ]
default_number_of_steps_for_threshold_scan = [ 128, 256, 1024 ]
#default_number_of_steps_for_threshold_scan_when_valid_threshold_file_exists = [ 32, 64, 256 ]
default_number_of_steps_for_threshold_scan_when_valid_threshold_file_exists = [ 64, 128, 512 ]
basename = "irsx.thresholds-for-lower-null-scalers"
thresholds_for_lower_null_scalers_filename = [ basename + ".x1", basename + ".x4", basename + ".x16" ]
basename = "irsx.thresholds-for-upper-null-scalers"
thresholds_for_upper_null_scalers_filename = [ basename + ".x1", basename + ".x4", basename + ".x16" ]
#thresholds_for_peak_scalers_filename = "irsx.thresholds-for-peak-scalers"
extra_for_threshold_scan = [ 1, 8, 4 ]
extra_for_setting_thresholds = [ 3, 14, 99 ]
bump_threshold_amount = [ 1, 4, 16 ]
trigger_gain_x1_upper = [ 0x7e0, 0x870, 0x9a0 ]
trigger_gain_x1_lower = [ 0x77f, 0xa00, 0xba0 ]

other_helpful_text = [ "bump wbias even (e/E)", "bump wbias odd (o/O)" ]
bank0_register_names = [ "clk_div", "max_retries", "verify_with_shout", "spgin", "trg_inversion_mask", "dual_channel_trigger_width (t/T)", "even_channel_trigger_width (y/Y)", "hs_data_ss_incr", "hs_data_capture", "scaler timeout", "hs_data_offset", "hs_data_ratio", "regen", "min_tries", "start_wr_address", "end_wr_address" ]
bank1_register_names = [ "hdrb errors, status8", "reg transactions", "readback errors", "last_erroneous_readback", "buffered_hs_data_stream_high", "buffered_hs_data_stream_middle1", "buffered_hs_data_stream_middle0", "buffered_hs_data_stream_low", "hs_data_word_decimated", "convert_counter", "done_out_counter", "wr_address", "f_montiming1", "f_montiming2" ]
bank4_register_names = [ "CMPbias", "ISEL", "SBbias", "DBbias" ]
bank5_register_names = [ "ch0", "ch1", "ch2", "ch3", "ch4", "ch5", "ch6", "ch7" ]
bank6_register_names = [ "bank0 read strobe count", "bank1 read strobe count", "bank2 read strobe count", "bank3 read strobe count", "bank4 read strobe count", "bank5 read strobe count", "bank6 read strobe count", "bank7 read strobe count", "bank0 write strobe count", "bank1 write strobe count", "bank2 write strobe count", "bank3 write strobe count", "bank4 write strobe count", "bank5 write strobe count", "bank6 write strobe count", "bank7 write strobe count" ]
other_stuff_names = [ "current (mA)", "voltage (V)", "temp (C)" ]
#header_description_bytes = [ "AL", "FA", "ASICID", "finetime", "coarse4", "coarse3", "coarse2", "coarse1", "trigger2", "trigger1", "aftertrigger", "lookback", "samplestoread", "startingsample", "missedtriggers", "status" ]
#header_decode_descriptions = [ "ASICID", "bank", "fine time", "coarse time", "trigger#", "samples after trigger", "lookback samples", "samples to read", "starting sample", "missed triggers", "status" ]
CMPbias = 0x1e8
ISEL    = 0xa80
SBbias  = 0xdff
DBbias  = 0x7ff
DAC_values = [CMPbias, ISEL, SBbias, DBbias]
datafile_name = "alpha.data"
number_of_words_to_read_from_the_fifo = 4106
ALFA = 0xa1fa
OMGA = 0x0e6a
LOG2_OF_NUMBER_OF_PEDESTALS_TO_ACQUIRE = 8
enabled_channels = [ 1, 1, 1, 1,  1, 1, 1, 1 ] # all channels
I2CupAddr = 0x0
LVDSA_pwr = 0 # 0 is high power mode
LVDSB_pwr = 0 # 0 is high power mode
SRCsel = 0 # 0 means data path A which is probably what you want while testing
TMReg_Reset = 0 # not currently implemented; breaks ls_i2c somehow
samples_after_trigger = 0x80
lookback_windows = 0x80
number_of_samples = 0x00 # 0 means 256 here
previous_number_of_samples = 0x00 # 0 means 256 here

number_of_pin_diode_boxes = 1
MAX_SAMPLES_PER_WAVEFORM = 64
timestep = 1

MAX_ADC = 4095
display_precision_of_hex_counter_counts = 8
display_precision_of_hex_scaler_counts = 4

GAP_X_BETWEEN_PLOTS = 10
GAP_Y_BETWEEN_PLOTS = 33
GAP_X_LEFT = 14
GAP_X_RIGHT = 205
GAP_Y_TOP = 24
GAP_Y_BOTTOM = 24

FONT_SIZE_PLOT_CAPTION = 18
FONT_SIZE_FEED_NAME = 15
FONT_SIZE_FEED_NAME_EXTRA_GAP = 6
ICON_SIZE = 32
ICON_BORDER = 2
ICON_SQUARE_LENGTH = ICON_SIZE//2 - 3*ICON_BORDER
NUMBER_OF_HOURS_TO_PLOT = 48
should_use_touchscreen = False
FONT_SIZE_BANKS = 15
BANKS_X_GAP = 10
#X_POSITION_OF_TOT = 450
X_POSITION_OF_BANK0_REGISTERS = 85
X_POSITION_OF_BANK1_REGISTERS = X_POSITION_OF_BANK0_REGISTERS + 375
X_POSITION_OF_CHANNEL_NAMES = X_POSITION_OF_BANK1_REGISTERS + 295
X_POSITION_OF_COUNTERS = X_POSITION_OF_CHANNEL_NAMES + 117
X_POSITION_OF_SCALERS = X_POSITION_OF_COUNTERS + 40
#X_POSITION_OF_BANK4_REGISTERS = 100
#X_POSITION_OF_BANK5_REGISTERS = 300
#X_POSITION_OF_BANK6_REGISTERS = 400
X_POSITION_OF_OTHER_STUFF = X_POSITION_OF_CHANNEL_NAMES
X_POSITION_OF_OTHER_STUFF_LABELS = X_POSITION_OF_OTHER_STUFF + 45

box_dimension_x_in = 3.0
box_dimension_y_in = 2.0
scale_pixels_per_in = 80

#channel_range = range(1, NUMBER_OF_CHANNELS_PER_ASIC+1)

channel_names = []
channel_names.extend(["ch" + str(i) for i in range(NUMBER_OF_CHANNELS_PER_ASIC)])
#channel_names.extend([ "trigger_count", "suggested_inversion_map", "hit_counter" ])
#print(str(channel_names))
bank1_register_values = [ i for i in range(len(channel_names)) ]

black = (0, 0, 0)
white = (255, 255, 255)
grey = (127, 127, 127)
red = (255, 0, 0)
green = (0, 255, 0)
blue = (75, 75, 255)
yellow = (255, 255, 0)
brown = (127, 127, 0)
teal = (0, 255, 255)
pink = (255, 63, 63)
maroon = (255, 0, 127)
dark_green = (0, 127, 0)
light_blue = (200, 200, 255)
orange = (255, 127, 0)
purple = (255, 0, 255)
grid_color_bright = (63, 63, 63)
grid_color_faint = (15, 15, 15)
grey = (127, 127, 127 )
dark_teal = (0, 127, 127)
dark_red = (127, 0, 0)
dark_blue = (0, 0, 127)
dark_purple = (127, 0, 127)

import colorsys
waveform_colors = [ tuple(255*x for x in colorsys.hsv_to_rgb(k/(NUMBER_OF_CHANNELS_PER_ASIC+2), 1.0, 1.0)) for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
#print(str(waveform_colors))
color = [ black, white ]
color.extend(waveform_colors)

selection = 0
coax_mux = [ 0 for i in range(4) ]

should_show_bank0_registers = True
should_show_bank1_registers = True
should_show_channel_names = True
should_show_counters = True
should_show_scalers = True
should_show_bank4_registers = False
should_show_bank5_registers = False
should_show_bank6_registers = False
should_show_other_stuff = True
scaler_values_seen = set()
pedestal_mode = False
DAC_to_control = 0

buffer_new = [ 0 for z in range(number_of_words_to_read_from_the_fifo) ]
buffer_old = [ 0 for z in range(number_of_words_to_read_from_the_fifo) ]
ALFA_OMGA_counter = 0
NUMBER_OF_WORDS_PER_HEADER = 8
NUMBER_OF_WORDS_PER_FOOTER = 2
NUMBER_OF_EXTRA_WORDS_PER_ALFA_OMGA_READOUT = NUMBER_OF_WORDS_PER_HEADER + NUMBER_OF_WORDS_PER_FOOTER
starting_sample = 0
pedestals_have_been_taken = False

# when run as a systemd service, it gets sent a SIGHUP upon pygame.init(), hence this dummy signal handler
# see https://stackoverflow.com/questions/39198961/pygame-init-fails-when-run-with-systemd
import signal
def signal_handler(signum, frame):
	print("signal handler: got signal " + str(signum))
	sys.stdout.flush()
	if 15==signum or 2==signum:
		pygame.quit()
		sys.exit(signum)
# from https://stackoverflow.com/a/34568177/5728815
for mysignal in set(signal.Signals)-{signal.SIGKILL, signal.SIGSTOP}:
	signal.signal(mysignal, signal_handler)

import sys
sys.path.append("../../bin/embedded")
import time
import random
import os
import datetime
import re

current_mA = 0.0
voltage_V = 0.0
temp_C = 0.0

def setup_pygame_sdl():
	os.environ['SDL_AUDIODRIVER'] = 'dsp'
	os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
	# from https://learn.adafruit.com/pi-video-output-using-pygame/pointing-pygame-to-the-framebuffer?view=all#pointing-pygame-to-the-framebuffer
	#disp_no = os.getenv("DISPLAY")
	#if disp_no:
	#	print("I'm running under X display = {0}".format(disp_no))
	#drivers = ['fbcon', 'directfb', 'svgalib']
	#for driver in drivers:
	#driver = 'fbcon' # unable to open a console terminal # fbcon not available
	#driver = 'directfb' # No available video device # directfb not available
	#driver = 'svgalib' # No available video device # svgalib not available
	#os.putenv('SDL_VIDEODRIVER', driver)
	# from https://github.com/project-owner/Peppy/blob/d9eb701c1f66be2ef5bccc8457bb96ece0f46f79/util/config.py#L1291
	#if os.path.exists("/dev/fb1"):
	#	os.environ["SDL_FBDEV"] = "/dev/fb1"
	#elif os.path.exists("/dev/fb0"):
	#	os.environ["SDL_FBDEV"] = "/dev/fb0"
	os.environ["SDL_FBDEV"] = "/dev/fb0"
	if should_use_touchscreen:
		if os.path.exists("/dev/input/touchscreen"):
			os.environ["SDL_MOUSEDEV"] = "/dev/input/touchscreen"
		else:
			os.environ["SDL_MOUSEDEV"] = "/dev/input/event0"
			#os.environ["SDL_MOUSEDEV"] = "/dev/input/mouse0"
			os.environ["SDL_MOUSEDRV"] = "TSLIB"
	global pygame
	import pygame # sudo apt install -y python3-pygame # gets 1.9.6 as of early 2023
	# pip3 install pygame # gets 2.1.2 as of early 2023
	# sudo apt install -y libmad0 libmikmod3 libportmidi0 libsdl-image1.2 libsdl-mixer1.2 libsdl-ttf2.0 libsdl1.2debian
	pygame.display.init()
	pygame.font.init()
	print("done setting up pygame/sdl")

def update_plot(which_plot):
	global plots_were_updated
	pygame.event.pump()
	formatted_data = [ [ 0 for x in range(plot_width[which_plot]) ] for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
	min_data_value_seen = MAX_ADC
	max_data_value_seen = 0
	#print_waveform_data(0)
	for n in range(len(waveform_data[which_plot][0])):
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			if not enabled_channels[k]:
				continue
			if max_data_value_seen<waveform_data[which_plot][k][n]:
				max_data_value_seen = waveform_data[which_plot][k][n]
			if waveform_data[which_plot][k][n]<min_data_value_seen:
				min_data_value_seen = waveform_data[which_plot][k][n]
#			formatted_data[k][n] = data_and_pedestal_coefficients[which_plot] * waveform_data[which_plot][k][n]
#			value = data_and_pedestal_coefficients[which_plot] * waveform_data[which_plot][k][n]
			#if 15==k and 0==n:
			#	value = MAX_ADC
			# when the TDC should be pegged near ~4095 for large input values, the decoded gcc_counter rolls over to a low number
#			if pedestals_have_been_taken:
#				if 0==i:
#					value += data_and_pedestal_coefficients[which_plot] * pedestal_data[i][j][k][n]
#				else:
#					#value += data_and_pedestal_coefficients[which_plot] * (pedestal_data[i][j][k][n] - average_pedestal[j][k])
#					value += data_and_pedestal_coefficients[which_plot] * (pedestal_data[j][j][k][n] - MIDRANGE + (k-NUMBER_OF_CHANNELS_PER_ASIC//2) * CHANNEL_OFFSET + QUAD_CHANNEL_OFFSET * (k//4))
#			else:
#				value -= EXTRA_OFFSET + (k-NUMBER_OF_CHANNELS_PER_ASIC//2) * CHANNEL_OFFSET + QUAD_CHANNEL_OFFSET * (k//4)
#			time = timestep*n
#			x = int(time)
#			formatted_data[k][x] = value * scale
			#if 0==n%40:
			#	print(str(time) + "," + str(value) + ":" + str(x) + ":" + str(formatted_data[k][x]))
	#print("min_data_value_seen: 0x" + hex(min_data_value_seen, 3))
	#print("max_data_value_seen: 0x" + hex(max_data_value_seen, 3))
	if which_plot == "trigger_memory":
		for n in range(len(waveform_data[which_plot][0])):
			for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
				formatted_data[k][n] = k * waveform_data[which_plot][k][n] / NUMBER_OF_CHANNELS_PER_ASIC
	else:
		for n in range(len(waveform_data[which_plot][0])):
			for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
				formatted_data[k][n] = k / NUMBER_OF_CHANNELS_PER_ASIC + scale[which_plot] * waveform_data[which_plot][k][n]
	pygame.event.pump()
	print("plotting data [" + str(which_plot) + "]...")
	plot[which_plot].fill(black)
	how_many_times_we_did_not_plot = 0
	offscale_count = 0
	number_of_enabled_channels = sum(enabled_channels)
	#print("plot_height: " + str(plot_height[which_plot]))
	#print("extra_gap_y: " + str(extra_gap_y))
	first_y = extra_gap_y
	last_y = plot_height[which_plot] - extra_gap_y
	scale_y = last_y - first_y
	for x in range(extra_gap_x, plot_width[which_plot]-extra_gap_x):
		pygame.event.pump()
		how_many_things_were_plotted_at_this_x_value = 0
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			if not enabled_channels[k]:
				continue
			yn = int(last_y - scale_y*formatted_data[k][x-extra_gap_x] + 0.5)
			#if 15==k:
			#	print("yn: " + str(yn) + " " + str(formatted_data[k][x-extra_gap_x] ))
			for y in range(first_y, last_y+1):
				doit = False
				if first_y==y:
					if yn<=first_y:
						doit = True
						offscale_count += 1
						#if 15==k:
						#	print("first case")
				elif last_y==y:
					if last_y<=yn:
						if which_plot != "trigger_memory":
							doit = True
						offscale_count += 1
						#if 15==k:
						#	print("second case")
				elif yn==y:
					doit = True
					#if 15==k:
					#	print("exact")
				if doit:
					how_many_things_were_plotted_at_this_x_value += 1
					plot[which_plot].set_at((x, y), color[k+2]) # first two indices are black and white
		if how_many_things_were_plotted_at_this_x_value<number_of_enabled_channels:
			#print(str(x) + ":" + str(how_many_things_were_plotted_at_this_x_value) + "/" + str(number_of_enabled_channels))
			how_many_times_we_did_not_plot += number_of_enabled_channels - how_many_things_were_plotted_at_this_x_value
		if 0:
			if extra_gap_x==x:
				string = ""
				for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
					if not enabled_channels[k]:
						continue
					string += str(formatted_data[k][x-extra_gap_x]) + " " + str(int(plot_height[which_plot]-extra_gap_y-1 - (plot_height[which_plot]-2*extra_gap_y)*formatted_data[k][x-extra_gap_x] + 0.5)) + ", "
				print(string)
	#print("how_many_times_we_did_not_plot: " + str(how_many_times_we_did_not_plot))
	print("offscale_count: " + str(offscale_count))
	plots_were_updated[which_plot] = True
	print("done")

def draw_plot_border(which_plot):
	#print("drawing plot border...")
	pygame.draw.rect(screen, white, pygame.Rect(coordinates[which_plot][0]-1, coordinates[which_plot][1]-1, plot_width[which_plot]+2, plot_height[which_plot]+2), 1)

def setup_sensors():
	global i2c
	i2c = board.I2C()
	setup_ammeter(i2c)
	setup_temperature_sensor(i2c)

def setup_ammeter(i2c):
	default_address = 0x40
	try:
		ina260_adafruit.setup(i2c, 32, default_address)
	except:
		print("ERROR: ina260 not present at address 0x" + generic.hex(default_address))
		raise

def setup_temperature_sensor(i2c):
	default_address = 0x4a
	try:
		#stts751.setup(i2c, 32, default_address)
		stts751.setup(i2c, default_address)
	except:
		print("ERROR: stts751 not present at address 0x" + generic.hex(default_address))
		raise

def read_ammeter():
	global current_mA, voltage_V
	current_mA, voltage_V = ina260_adafruit.get_values()[0:2]
	#print(str(fround(current_mA, 0.1)) + ", " + str(fround(voltage_V, 0.001)))
	#print(sround(current_mA, 1) + ", " + sround(voltage_V, 3))
	return current_mA, voltage_V

def read_temperature_sensor():
	global temp_C
	#temp_C = stts751.get_values()[0]
	temp_C = stts751.get_temperature_from_sensor()
	return temp_C

def setup():
	global screen, something_was_updated
	something_was_updated = False
	#print("screen_width: " + str(SCREEN_WIDTH))
	#usable_width = int(SCREEN_WIDTH - GAP_X_LEFT - GAP_X_RIGHT - (COLUMNS-1)*GAP_X_BETWEEN_PLOTS)
	#print("usable_width: " + str(usable_width))
	#usable_height = int(SCREEN_HEIGHT - GAP_Y_TOP - GAP_Y_BOTTOM - (ROWS-1)*GAP_Y_BETWEEN_PLOTS)
	#print("usable_height: " + str(usable_height))
	global extra_gap_x, extra_gap_y
	extra_gap_x = 4
	extra_gap_y = 4
	gap = 20
	setup_pygame_sdl()
	#pygame.mixer.quit()
	global game_clock
	game_clock = pygame.time.Clock()
#	if not should_use_touchscreen:
#		pygame.mouse.set_cursor((8,8),(0,0),(0,0,0,0,0,0,0,0),(0,0,0,0,0,0,0,0))
	pygame.display.set_caption("irsx readout")
	plot_caption_font = pygame.font.SysFont("monospace", FONT_SIZE_PLOT_CAPTION)
	feed_name_font = pygame.font.SysFont("monospace", FONT_SIZE_FEED_NAME)
#	icon = pygame.Surface((ICON_SIZE, ICON_SIZE))
#	for i in range(COLUMNS):
#		for j in range(ROWS):
#			pass
#			#pygame.draw.rect(icon, (random.randrange(0, 255), random.randrange(0, 255), random.randrange(0, 255)), pygame.Rect(ICON_BORDER+i*(ICON_SQUARE_LENGTH+ICON_BORDER), ICON_BORDER+j*(ICON_SQUARE_LENGTH+ICON_BORDER), ICON_SQUARE_LENGTH, ICON_SQUARE_LENGTH))
#	icon.fill(yellow)
#	pygame.display.set_icon(icon)
	screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
	screen.fill(black)
	pygame.event.pump()
	# -----------------------------------------------------------------------------------
	waveform_plot_width = MAX_SAMPLES_PER_WAVEFORM + 2*extra_gap_x
	waveform_plot_height = CHANNEL_OFFSET * (NUMBER_OF_CHANNELS_PER_ASIC+1) + 2*extra_gap_y
	global plot, have_just_gathered_waveform_data, coordinates, plot_width, plot_height, waveform_data, scale, plots_were_updated
	plot = {}
	plot["raw_waveform"] = pygame.Surface((waveform_plot_width, waveform_plot_height))
#	plot["pedestal_waveform"] = pygame.Surface((waveform_plot_width, waveform_plot_height))
#	plot["pedestal_subtracted_waveform"] = pygame.Surface((waveform_plot_width, waveform_plot_height))
	plot["trigger_memory"] = pygame.Surface((TRIGGER_MEMORY_PLOT_WIDTH, TRIGGER_MEMORY_PLOT_HEIGHT))
	coordinates = {}
	coordinates["raw_waveform"] = [ GAP_X_LEFT+0*(waveform_plot_width+GAP_X_BETWEEN_PLOTS)-1, GAP_Y_TOP ]
#	coordinates["pedestal_waveform"] = [ GAP_X_LEFT+1*(waveform_plot_width+GAP_X_BETWEEN_PLOTS)-1, GAP_Y_TOP ]
#	coordinates["pedestal_subtracted_waveform"] = [ GAP_X_LEFT+2*(waveform_plot_width+GAP_X_BETWEEN_PLOTS)-1, GAP_Y_TOP ]
	coordinates["trigger_memory"] = [ GAP_X_LEFT, GAP_Y_TOP+1*(waveform_plot_height+GAP_Y_BETWEEN_PLOTS)-1 ]
	plot_width = {}
	plot_height = {}
	waveform_data = {}
	scale = {}
	have_just_gathered_waveform_data = {}
	plots_were_updated = {}
	for which_plot in plot.keys():
		plot_width[which_plot] = waveform_plot_width
		plot_height[which_plot] = waveform_plot_height
		waveform_data[which_plot] = [ [ 0 for n in range(MAX_SAMPLES_PER_WAVEFORM) ] for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
		scale[which_plot] = 1/MAX_ADC/NUMBER_OF_CHANNELS_PER_ASIC
		have_just_gathered_waveform_data[which_plot] = False
		plots_were_updated[which_plot] = False
	# -----------------------------------------------------------------------------------
	# special case the trigger memory stuff:
	plot_width["trigger_memory"] = TRIGGER_MEMORY_PLOT_WIDTH
	plot_height["trigger_memory"] = TRIGGER_MEMORY_PLOT_HEIGHT
	waveform_data["trigger_memory"] = [ [ 0 for n in range(TRIGGER_MEMORY_READOUT_SIZE) ] for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
	scale["trigger_memory"] = CHANNEL_OFFSET
	# -----------------------------------------------------------------------------------
	global Y_POSITION_OF_CHANNEL_NAMES
	global Y_POSITION_OF_COUNTERS
	global Y_POSITION_OF_SCALERS
	#global Y_POSITION_OF_TOT
	global Y_POSITION_OF_BANK0_REGISTERS
	global Y_POSITION_OF_BANK1_REGISTERS
	global Y_POSITION_OF_BANK4_REGISTERS
	global Y_POSITION_OF_BANK5_REGISTERS
	global Y_POSITION_OF_BANK6_REGISTERS
	global Y_POSITION_OF_OTHER_STUFF
	TEXT_OFFSET = waveform_plot_height + 4*gap + plot_height["trigger_memory"]
	Y_POSITION_OF_CHANNEL_NAMES = TEXT_OFFSET
	Y_POSITION_OF_COUNTERS      = TEXT_OFFSET
	Y_POSITION_OF_SCALERS       = TEXT_OFFSET
	#Y_POSITION_OF_TOT = waveform_plot_height + gap + FONT_SIZE_BANKS
	Y_POSITION_OF_BANK0_REGISTERS = TEXT_OFFSET
	Y_POSITION_OF_BANK1_REGISTERS = TEXT_OFFSET
	#Y_POSITION_OF_BANK4_REGISTERS = TEXT_OFFSET + 170
	#Y_POSITION_OF_BANK5_REGISTERS = TEXT_OFFSET + FONT_SIZE_BANKS + 75
	#Y_POSITION_OF_BANK6_REGISTERS = TEXT_OFFSET
	Y_POSITION_OF_OTHER_STUFF = TEXT_OFFSET + 195
	# -----------------------------------------------------------------------------------
	width = int(box_dimension_x_in * scale_pixels_per_in)
	height = int(box_dimension_y_in * scale_pixels_per_in)
	#global flarb
	#flarb = [ [ pygame.Surface((width, height)) for j in range(ROWS) ] for i in range(COLUMNS) ]
	#plot_rect = [ [ plot[i][j].get_rect() for j in range(ROWS) ] for i in range(COLUMNS) ]
	#clear_plots()
	global banks_font
	banks_font = pygame.font.SysFont("monospace", FONT_SIZE_BANKS)
	if should_show_bank0_registers:
		for i in range(len(bank0_register_names)):
			register_name = banks_font.render(bank0_register_names[i], 1, white)
			screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK0_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK0_REGISTERS+FONT_SIZE_BANKS*i)))
	if should_show_bank1_registers:
		for i in range(len(bank1_register_names)):
			register_name = banks_font.render(bank1_register_names[i], 1, white)
			screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK1_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))
	if should_show_bank4_registers:
		for i in range(len(bank4_register_names)):
			register_name = banks_font.render(bank4_register_names[i], 1, white)
			screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK4_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK4_REGISTERS+FONT_SIZE_BANKS*i)))
#	if should_show_bank5_registers:
#		for i in range(len(bank5_register_names)):
#			register_name = banks_font.render(bank5_register_names[i], 1, white)
#			screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK5_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK5_REGISTERS+FONT_SIZE_BANKS*i)))
	if should_show_bank6_registers:
		for i in range(len(bank6_register_names)):
			register_name = banks_font.render(bank6_register_names[i], 1, white)
			screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK6_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK6_REGISTERS+FONT_SIZE_BANKS*i)))
	if should_show_other_stuff:
		for i in range(len(other_stuff_names)):
			register_name = banks_font.render(other_stuff_names[i], 1, white)
			screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_OTHER_STUFF_LABELS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_OTHER_STUFF+FONT_SIZE_BANKS*i)))
	#for i in range(NUMBER_OF_CHANNELS_PER_ASIC):
	if should_show_channel_names:
		for i in range(len(channel_names)):
			register_name = banks_font.render(channel_names[i], 1, white)
			screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_CHANNEL_NAMES+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_CHANNEL_NAMES+FONT_SIZE_BANKS*i)))
	#for i in range(NUMBER_OF_CHANNELS_PER_ASIC):
	#	channel_name = banks_font.render(channel_names[i], 1, white)
	#	screen.blit(channel_name, channel_name.get_rect(center=(X_POSITION_OF_BANK6_COUNTERS+BANKS_X_GAP+channel_name.get_width()//2,Y_POSITION_OF_BANK6_COUNTERS+FONT_SIZE_BANKS*i)))
#	for i in range(COLUMNS):
	if 0:
	#for which_plot in []:
		for j in range(ROWS):
			pygame.event.pump()
			plot_caption = plot_caption_font.render(plot_name[i][j], 1, white)
			screen.blit(plot_caption, plot_caption.get_rect(center=(GAP_X_LEFT+i*(plot_width+GAP_X_BETWEEN_PLOTS)+plot_width//2 , GAP_Y_TOP+j*(plot_height+GAP_Y_BETWEEN_PLOTS)-FONT_SIZE_PLOT_CAPTION//2-4)))
			feed_caption = []
			width = 0
			for k in range(len(short_feed_name[i][j])):
				feed_caption.append(feed_name_font.render(short_feed_name[i][j][k], 1, color[k+2]))
				width += feed_caption[k].get_width() + FONT_SIZE_FEED_NAME_EXTRA_GAP
			#print("width: " + str(width))
			for k in range(len(short_feed_name[i][j])):
				screen.blit(feed_caption[k], feed_caption[k].get_rect(center=(GAP_X_LEFT+i*(plot_width+GAP_X_BETWEEN_PLOTS)+plot_width//2-width//2+feed_caption[k].get_width()//2, GAP_Y_TOP+j*(plot_height+GAP_Y_BETWEEN_PLOTS)+plot_height+FONT_SIZE_FEED_NAME//2+4)))
				width -= 2*(feed_caption[k].get_width() + FONT_SIZE_FEED_NAME_EXTRA_GAP)
			#print("width: " + str(width))
	for which_plot in plot.keys():
		pygame.event.pump()
		draw_plot_border(which_plot)
#		update_plot(which_plot)
#		blit(which_plot)
	flip()
	sys.stdout.flush()
	althea.setup_half_duplex_bus("test058")
	global should_check_for_new_data
	should_check_for_new_data = pygame.USEREVENT + 1
	print("gui_update_period: " + str(gui_update_period))
	pygame.time.set_timer(should_check_for_new_data, int(gui_update_period*1000/3/2))
	setup_sensors()
	write_bootup_values()

def write_bootup_values():
	print("writing bootup values...")
	control_regulator(1)
	write_value_to_clock_divider_for_register_transactions(0) # this must be at least 5 unless min_tries is at least 2
	set_min_tries(2) # this must be at least 2 if clock_divider is less than 5
	set_max_retries_for_register_transactions(5)
	set_whether_to_verify_with_shout(0)
	set_trg_inversion_mask(0b1100)
	set_trigger_gain(1) # 0="x1", 1="x4", 2="x16"
	if "upper"==cliff:
		load_thresholds_corresponding_to_upper_null_scaler()
	else:
		load_thresholds_corresponding_to_lower_null_scaler()
	#read_modify_write_speed_test()
	set_expected_trigger_widths(default_expected_dual_channel_trigger_width, default_expected_even_channel_trigger_width)
	set_hs_data_values(default_hs_data_ss_incr, default_hs_data_capture)
	set_spgin(default_spgin)
	set_scaler_timeout(default_scaler_timeout)
	set_hs_data_offset_and_ratio(default_hs_data_offset, default_hs_data_ratio)
	set_start_wr_address(0x00)
	set_end_wr_address(0xff)

import subprocess
def reprogram_fpga():
	print("reprogramming fpga...")
	subprocess.run(["/bin/bash", "-i", "-c", "fpga"])
	time.sleep(0.2)
	write_bootup_values()

timing_register_to_control = 1
def loop():
	#pygame.time.wait(10)
	game_clock.tick(100)
	global running, something_was_updated, DAC_to_control, timing_register_to_control
	something_was_updated = True
	#pressed_keys = pygame.key.get_pressed()
	#pygame.event.wait()
	import pygame.locals
	mouse = pygame.mouse.get_pos()
	for event in pygame.event.get():
		if event.type == pygame.KEYDOWN:
#				initiate_trigger()
				#gather_pedestals(1)
			if pygame.K_ESCAPE==event.key:
				running = False
			# --------------------------
			elif pygame.K_F1==event.key:
				reprogram_fpga()
			elif pygame.K_F2==event.key:
				run_threshold_scan()
			elif pygame.K_F3==event.key:
				#write_nominal_register_values()
				write_nominal_register_values_using_read_modify_write()
			elif pygame.K_F4==event.key:
				clear_all_registers_quickly()
				#clear_all_registers_slowly()
			elif pygame.K_p==event.key:
				if pygame.key.get_mods() & pygame.KMOD_SHIFT:
					control_regulator(1)
				else:
					control_regulator(0)
			elif pygame.K_F5==event.key:
				cycle_reg179()
			elif pygame.K_F6==event.key:
				#initiate_trigger()
				#drain_fifo()
				pass
			elif pygame.K_F7==event.key:
				send_unique_test_pattern(0)
			elif pygame.K_F8==event.key:
				send_unique_test_pattern(1)
			elif pygame.K_F9==event.key:
				digitize_some_windows_and_read_them_out()
			elif pygame.K_F10==event.key:
				readback_asic_register_values()
			elif pygame.K_F11==event.key:
				pass
				#DAC_to_control = 2
				#print("now controlling SBbias")
			elif pygame.K_F12==event.key:
				pass
				#DAC_to_control = 3
				#print("now controlling DBbias")
			# --------------------------
			elif pygame.K_1==event.key:
				timing_register_to_control = 1
				print("now controlling WR_SYNC")
			elif pygame.K_2==event.key:
				timing_register_to_control = 2
				print("now controlling SSP_in")
			elif pygame.K_3==event.key:
				timing_register_to_control = 3
				print("now controlling S1")
			elif pygame.K_4==event.key:
				timing_register_to_control = 4
				print("now controlling S2")
			elif pygame.K_5==event.key:
				timing_register_to_control = 5
				print("now controlling PHASE")
			elif pygame.K_6==event.key:
				timing_register_to_control = 6
				print("now controlling WR_STRB")
			# --------------------------
			elif pygame.K_q==event.key:
				change_timing_register_LE_value(-2)
			elif pygame.K_w==event.key:
				change_timing_register_LE_value(+2)
			elif pygame.K_e==event.key:
				if pygame.key.get_mods() & pygame.KMOD_SHIFT:
					bump_wbias_even(-wbias_bump_amount)
				else:
					bump_wbias_even(+wbias_bump_amount)
			elif pygame.K_r==event.key:
				if pygame.key.get_mods() & pygame.KMOD_SHIFT:
					bump_hs_data_offset(+1)
				else:
					bump_hs_data_offset(-1)
			elif pygame.K_t==event.key:
				if pygame.key.get_mods() & pygame.KMOD_SHIFT:
					bump_expected_trigger_width(+1, 0)
				else:
					bump_expected_trigger_width(-1, 0)
			elif pygame.K_y==event.key:
				if pygame.key.get_mods() & pygame.KMOD_SHIFT:
					bump_expected_trigger_width(0, +1)
				else:
					bump_expected_trigger_width(0, -1)
			elif pygame.K_u==event.key:
				plot_trigger_memory()
			elif pygame.K_i==event.key:
				if pygame.key.get_mods() & pygame.KMOD_SHIFT:
					bump_hs_data_capture(+1)
				else:
					bump_hs_data_capture(-1)
			elif pygame.K_o==event.key:
				if pygame.key.get_mods() & pygame.KMOD_SHIFT:
					bump_wbias_odd(-wbias_bump_amount)
				else:
					bump_wbias_odd(+wbias_bump_amount)
			# --------------------------
			elif pygame.K_a==event.key:
				read_bank5_data()
			elif pygame.K_s==event.key:
				toggle_trigger_sign_bit()
			elif pygame.K_d==event.key:
				if pygame.key.get_mods() & pygame.KMOD_SHIFT:
					bump_wbias_dual(-wbias_bump_amount)
				else:
					bump_wbias_dual(+wbias_bump_amount)
			elif pygame.K_f==event.key:
				force_register_rewrite()
			elif pygame.K_g==event.key:
				cycle_through_x1_x4_x16_trigger_gains()
			elif pygame.K_j==event.key:
				send_signal_to_start_wilkinson_conversion()
			# --------------------------
			elif pygame.K_z==event.key:
				load_thresholds_corresponding_to_null_scaler()
			elif pygame.K_c==event.key:
				clear_channel_counters()
			elif pygame.K_b==event.key:
				write_bootup_values()
			elif pygame.K_m==event.key:
				test_tpg_as_a_pollable_memory()
			# --------------------------
			elif pygame.K_LEFTBRACKET==event.key:
				change_timing_register_TE_value(-2)
			elif pygame.K_RIGHTBRACKET==event.key:
				change_timing_register_TE_value(+2)
			elif pygame.K_COMMA==event.key:
				bump_thresholds(-bump_threshold_amount[trigger_gain])
			elif pygame.K_PERIOD==event.key:
				bump_thresholds(+bump_threshold_amount[trigger_gain])
			# --------------------------
		elif event.type == pygame.QUIT:
			running = False
		elif event.type == should_check_for_new_data:
			readout_counters_and_scalers()
			update_scalers()
			update_counters()
			update_bank0_registers()
			update_bank1_registers()
			update_bank4_registers()
			update_bank6_registers()
			show_other_stuff()
#			update_bank1_bank2_scalers()
#			update_counters()
	if not pedestal_mode:
		global have_just_gathered_waveform_data
#		for i in range(COLUMNS):
#			for j in range(ROWS):
		for which_plot in plot.keys():
			if have_just_gathered_waveform_data[which_plot]:
				have_just_gathered_waveform_data[which_plot] = False
				update_plot(which_plot)
				blit(which_plot)
	flip()

def blit(which_plot):
	global something_was_updated
	if plots_were_updated[which_plot]:
		#print("blitting...")
		screen.blit(plot[which_plot], (coordinates[which_plot][0], coordinates[which_plot][1]))
		#pygame.image.save(plot[which_plot], "alpha.data." + str(i) + ".png")
		pygame.event.pump()
		plots_were_updated[which_plot] = False
		something_was_updated = True

def flip():
	global something_was_updated
	if something_was_updated:
		#print("flipping...")
		pygame.display.flip()
		pygame.event.pump()
		something_was_updated = False

def write_to_pollable_memory_value():
	bank = 0
	value = 0xa5
	address = 11
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value], False)
	readback_value, = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 11, 1, False)
	print(hex(value) + ":" + hex(readback_value))
	value = 0x5a
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value], False)
	readback_value, = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 11, 1, False)
	print(hex(value) + ":" + hex(readback_value))

def read_bank0_registers():
	global bank0_register_values
	bank = 0
	bank0_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, len(bank0_register_names), False)

def read_bank1_registers():
	global bank1_register_values
	bank = 1
	bank1_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, len(bank1_register_names), False)

def read_bank4_registers():
	global bank4_register_values
	bank = 4
	bank4_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, len(bank4_register_names), False)

def readout_trigger_memory():
	bank = 4
	trigger_memory = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, TRIGGER_MEMORY_READOUT_SIZE, False)
	if 0:
		print("trigger memory:")
		i = 0
		string = ""
		for n in range(len(trigger_memory)):
			j = n%(16*RATIO_OF_TRG_CLOCK_TO_SST_CLOCK)
			if j==0:
				i = n//(16*RATIO_OF_TRG_CLOCK_TO_SST_CLOCK)
				#print(hex(i,1) + ": " + string)
				if n!=0:
					print(string)
				string = hex(i,1) + ": "
			string += " " + hex(trigger_memory[n], 2)
		print(string)
#	global waveform_data
	for n in range(len(trigger_memory)):
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			waveform_data["trigger_memory"][k][n] = ((trigger_memory[n] & (1<<k))>>k) & 1
	have_just_gathered_waveform_data["trigger_memory"] = True

def plot_trigger_memory():
	readout_trigger_memory()
	#plot[which_plot].fill(black)

def print_waveform_data(k):
	string = ""
	for n in range(MAX_SAMPLES_PER_WAVEFORM):
		string += hex(waveform_data["raw_waveform"][k][n]) + ","
	print(string)

def read_bank5_data():
	bank = 5
	bank5_data = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, 512, False)
	#print(str(bank5_data))
	#global waveform_data
	for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
		for n in range(MAX_SAMPLES_PER_WAVEFORM):
			waveform_data["raw_waveform"][k][n] = bank5_data[k*64+n] & 0xfff
	for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
		print_waveform_data(k)
	global have_just_gathered_waveform_data
	have_just_gathered_waveform_data["raw_waveform"] = True

def read_bank6_registers():
	global bank6_register_values
	bank = 6
	bank6_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, len(bank6_register_names), False)

bank0_register_object = [ 0 for i in range(len(bank0_register_names)) ]
bank1_register_object = [ 0 for i in range(len(bank1_register_names)) ]
bank4_register_object = [ 0 for i in range(len(bank1_register_names)) ]
bank5_register_object = [ 0 for i in range(len(bank5_register_names)) ]
bank6_register_object = [ 0 for i in range(len(bank6_register_names)) ]
other_stuff_object    = [ 0 for i in range(len(other_stuff_names)) ]

def update_bank0_registers():
	global bank0_register_object
	read_bank0_registers()
	if should_show_bank0_registers:
		for i in range(len(bank0_register_names)):
			try:
				temp_surface = pygame.Surface(bank0_register_object[i].get_size())
				temp_surface.fill(dark_green)
				screen.blit(temp_surface, bank0_register_object[i].get_rect(center=(X_POSITION_OF_BANK0_REGISTERS-bank0_register_object[i].get_width()//2,Y_POSITION_OF_BANK0_REGISTERS+FONT_SIZE_BANKS*i)))
			except Exception as e:
				#print(str(e))
				pass
			bank0_register_object[i] = banks_font.render(hex(bank0_register_values[i], 8, True), False, white)
			screen.blit(bank0_register_object[i], bank0_register_object[i].get_rect(center=(X_POSITION_OF_BANK0_REGISTERS-bank0_register_object[i].get_width()//2,Y_POSITION_OF_BANK0_REGISTERS+FONT_SIZE_BANKS*i)))

def update_bank1_registers():
	global bank1_register_object
	read_bank1_registers()
	if should_show_bank1_registers:
		for i in range(len(bank1_register_names)):
			try:
				temp_surface = pygame.Surface(bank1_register_object[i].get_size())
				temp_surface.fill(purple)
				screen.blit(temp_surface, bank1_register_object[i].get_rect(center=(X_POSITION_OF_BANK1_REGISTERS-bank1_register_object[i].get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))
			except Exception as e:
				#print(str(e))
				pass
			bank1_register_object[i] = banks_font.render(hex(bank1_register_values[i], 8, True), False, white)
			screen.blit(bank1_register_object[i], bank1_register_object[i].get_rect(center=(X_POSITION_OF_BANK1_REGISTERS-bank1_register_object[i].get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))

def update_bank4_registers():
	global bank4_register_object
	read_bank4_registers()
	if should_show_bank4_registers:
		for i in range(len(bank4_register_names)):
			try:
				temp_surface = pygame.Surface(bank4_register_object[i].get_size())
				temp_surface.fill(blue)
				screen.blit(temp_surface, bank4_register_object[i].get_rect(center=(X_POSITION_OF_BANK4_REGISTERS-bank4_register_object[i].get_width()//2,Y_POSITION_OF_BANK4_REGISTERS+FONT_SIZE_BANKS*i)))
			except Exception as e:
				#print(str(e))
				pass
			bank4_register_object[i] = banks_font.render(hex(bank4_register_values[i], 8, True), False, white)
			screen.blit(bank4_register_object[i], bank4_register_object[i].get_rect(center=(X_POSITION_OF_BANK4_REGISTERS-bank4_register_object[i].get_width()//2,Y_POSITION_OF_BANK4_REGISTERS+FONT_SIZE_BANKS*i)))

def update_bank6_registers():
	global bank6_register_object
	read_bank6_registers()
	if should_show_bank6_registers:
		for i in range(len(bank6_register_names)):
			try:
				temp_surface = pygame.Surface(bank6_register_object[i].get_size())
				temp_surface.fill(brown)
				screen.blit(temp_surface, bank6_register_object[i].get_rect(center=(X_POSITION_OF_BANK6_REGISTERS-bank6_register_object[i].get_width()//2,Y_POSITION_OF_BANK6_REGISTERS+FONT_SIZE_BANKS*i)))
			except Exception as e:
				#print(str(e))
				pass
			bank6_register_object[i] = banks_font.render(hex(bank6_register_values[i], 8, True), False, white)
			screen.blit(bank6_register_object[i], bank6_register_object[i].get_rect(center=(X_POSITION_OF_BANK6_REGISTERS-bank6_register_object[i].get_width()//2,Y_POSITION_OF_BANK6_REGISTERS+FONT_SIZE_BANKS*i)))

def show_other_stuff():
	read_ammeter()
	read_temperature_sensor()
	other_stuff_values = [ current_mA, voltage_V, temp_C ]
	other_stuff_decimal_places = [ 1, 3, 1 ]
	if should_show_other_stuff:
		for i in range(len(other_stuff_names)):
			try:
				temp_surface = pygame.Surface(other_stuff_object[i].get_size())
				temp_surface.fill(dark_teal)
				screen.blit(temp_surface, other_stuff_object[i].get_rect(center=(X_POSITION_OF_OTHER_STUFF+other_stuff_object[i].get_width()//2,Y_POSITION_OF_OTHER_STUFF+FONT_SIZE_BANKS*i)))
			except Exception as e:
				#print(str(e))
				pass
			other_stuff_object[i] = banks_font.render(sround(other_stuff_values[i], other_stuff_decimal_places[i]), False, white)
			screen.blit(other_stuff_object[i], other_stuff_object[i].get_rect(center=(X_POSITION_OF_OTHER_STUFF+other_stuff_object[i].get_width()//2,Y_POSITION_OF_OTHER_STUFF+FONT_SIZE_BANKS*i)))

def write_value_to_clock_divider_for_register_transactions(value=127):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, [value])

def set_max_retries_for_register_transactions(quantity):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 1, [quantity])

def set_whether_to_verify_with_shout(whether_or_not):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 2, [whether_or_not])

def set_spgin(spgin):
	bank = 0
	spgin &= 1
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 3, [spgin])

def set_trg_inversion_mask(mask):
	bank = 0
	mask &= 0xf
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 4, [mask])

def set_expected_trigger_widths(dual, even):
	bank = 0
	if dual<MIN_TRIGGER_WIDTH_TO_EXPECT:
		dual = MIN_TRIGGER_WIDTH_TO_EXPECT
	elif MAX_TRIGGER_WIDTH_TO_EXPECT<dual:
		dual = MAX_TRIGGER_WIDTH_TO_EXPECT
	if even<MIN_TRIGGER_WIDTH_TO_EXPECT:
		even = MIN_TRIGGER_WIDTH_TO_EXPECT
	elif MAX_TRIGGER_WIDTH_TO_EXPECT<even:
		even = MAX_TRIGGER_WIDTH_TO_EXPECT
	print("expected trigger widths: " + str(dual) + " (dual), " + str(even) + " (even)")
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [dual, even])

def bump_expected_trigger_width(dual, even):
	bank = 0
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 5, 2, False)
	readback[0] &= 0xff
	readback[1] &= 0xff
	dual += int(readback[0])
	even += int(readback[1])
	if dual<MIN_TRIGGER_WIDTH_TO_EXPECT:
		dual = MIN_TRIGGER_WIDTH_TO_EXPECT
	elif MAX_TRIGGER_WIDTH_TO_EXPECT<dual:
		dual = MAX_TRIGGER_WIDTH_TO_EXPECT
	if even<MIN_TRIGGER_WIDTH_TO_EXPECT:
		even = MIN_TRIGGER_WIDTH_TO_EXPECT
	elif MAX_TRIGGER_WIDTH_TO_EXPECT<even:
		even = MAX_TRIGGER_WIDTH_TO_EXPECT
	print("expected trigger widths: " + str(dual) + " (dual), " + str(even) + " (even)")
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [dual, even])

HS_MAX = 31
def set_hs_data_values(ss_incr, capture):
	bank = 0
	if ss_incr<0:
		ss_incr = 0
	elif HS_MAX<ss_incr:
		ss_incr = HS_MAX
	if capture<0:
		capture = 0
	elif HS_MAX<capture:
		capture = HS_MAX
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 7, [ss_incr, capture])

def bump_hs_data_capture(amount):
	bank = 0
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 8, 1, False)
	capture = readback[0] + amount
	if capture<0:
		capture = HS_MAX
	if HS_MAX<capture:
		capture = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 8, [capture])

def set_scaler_timeout(timeout):
	bank = 0
	timeout = int(timeout)
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 9, [timeout])

def set_hs_data_offset_and_ratio(offset, ratio):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 10, [offset, ratio])

OFFSET_MAX = 7
def bump_hs_data_offset(amount):
	bank = 0
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 10, 1, False)
	offset = readback[0] + amount
	if offset<0:
		offset = OFFSET_MAX
	if OFFSET_MAX<offset:
		offset = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 10, [offset])

def control_regulator(value=1):
	bank = 0
	value &= 1
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 12, [value])

def set_min_tries(value):
	if 255<value:
		value = 255
	if value<0:
		value = 0
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 13, [value])

def set_start_wr_address(value):
	bank = 0
	value &= 0xff
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 14, [value])

def set_end_wr_address(value):
	bank = 0
	value &= 0xff
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 15, [value])

def clear_channel_counters():
	print("clearing channel counters")
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, [1])

def force_register_rewrite():
	print("forcing register rewrite")
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 1, [1])

def send_signal_to_start_wilkinson_conversion():
	print("sending signal to start wilkinson conversion")
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 2, [1])

def read_modify_write_speed_test():
	print("starting speed test...")
	bank = 7
	starting_address = 0
	block_length = 128
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + starting_address, block_length, False)
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		readback[channel*4] += 6
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + starting_address, readback)
	print("finished speed test")

def write_trigger_thresholds_read_modify_write_style(threshold):
	bank = 7
	starting_address = 128
	spacing = 4
	block_length = spacing * NUMBER_OF_CHANNELS_PER_ASIC
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + starting_address, block_length, False)
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		readback[channel*spacing] = threshold[channel]
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + starting_address, readback)

nominal_register_values = [ [] for i in range(255) ]
# these values are cribbed from asic_configuration.c which has values borrowed from config1asic_trueROI.py; enabling the DLL requires more effort
nominal_register_values[128] = ("TRGthresh0", 0, "threshold voltage for trigger output for ch0")
nominal_register_values[132] = ("TRGthresh1", 0, "threshold voltage for trigger output for ch1")
nominal_register_values[136] = ("TRGthresh2", 0, "threshold voltage for trigger output for ch2")
nominal_register_values[140] = ("TRGthresh3", 0, "threshold voltage for trigger output for ch3")
nominal_register_values[144] = ("TRGthresh4", 0, "threshold voltage for trigger output for ch4")
nominal_register_values[148] = ("TRGthresh5", 0, "threshold voltage for trigger output for ch5")
nominal_register_values[152] = ("TRGthresh6", 0, "threshold voltage for trigger output for ch6")
nominal_register_values[156] = ("TRGthresh7", 0, "threshold voltage for trigger output for ch7")
nominal_register_values[129] = ("Trig4xVofs0", Trig4xVofs, "voltage offset for x4 trigger path for ch0")
nominal_register_values[133] = ("Trig4xVofs1", Trig4xVofs, "voltage offset for x4 trigger path for ch1")
nominal_register_values[137] = ("Trig4xVofs2", Trig4xVofs, "voltage offset for x4 trigger path for ch2")
nominal_register_values[141] = ("Trig4xVofs3", Trig4xVofs, "voltage offset for x4 trigger path for ch3")
nominal_register_values[145] = ("Trig4xVofs4", Trig4xVofs, "voltage offset for x4 trigger path for ch4")
nominal_register_values[149] = ("Trig4xVofs5", Trig4xVofs, "voltage offset for x4 trigger path for ch5")
nominal_register_values[153] = ("Trig4xVofs6", Trig4xVofs, "voltage offset for x4 trigger path for ch6")
nominal_register_values[157] = ("Trig4xVofs7", Trig4xVofs, "voltage offset for x4 trigger path for ch7")
nominal_register_values[130] = ("Trig16xVofs0", Trig16xVofs, "voltage offset for x16 trigger path for ch0 (warning: affects x4 trigger path)")
nominal_register_values[134] = ("Trig16xVofs1", Trig16xVofs, "voltage offset for x16 trigger path for ch1 (warning: affects x4 trigger path)")
nominal_register_values[138] = ("Trig16xVofs2", Trig16xVofs, "voltage offset for x16 trigger path for ch2 (warning: affects x4 trigger path)")
nominal_register_values[142] = ("Trig16xVofs3", Trig16xVofs, "voltage offset for x16 trigger path for ch3 (warning: affects x4 trigger path)")
nominal_register_values[146] = ("Trig16xVofs4", Trig16xVofs, "voltage offset for x16 trigger path for ch4 (warning: affects x4 trigger path)")
nominal_register_values[150] = ("Trig16xVofs5", Trig16xVofs, "voltage offset for x16 trigger path for ch5 (warning: affects x4 trigger path)")
nominal_register_values[154] = ("Trig16xVofs6", Trig16xVofs, "voltage offset for x16 trigger path for ch6 (warning: affects x4 trigger path)")
nominal_register_values[158] = ("Trig16xVofs7", Trig16xVofs, "voltage offset for x16 trigger path for ch7 (warning: affects x4 trigger path)")
nominal_register_values[131] = ("Wbias0", wbias_even, "width of trigger output for ch0; needs TBbias")
nominal_register_values[135] = ("Wbias1", wbias_odd,  "width of trigger output for ch1; needs TBbias")
nominal_register_values[139] = ("Wbias2", wbias_even, "width of trigger output for ch2; needs TBbias")
nominal_register_values[143] = ("Wbias3", wbias_odd,  "width of trigger output for ch3; needs TBbias")
nominal_register_values[147] = ("Wbias4", wbias_even, "width of trigger output for ch4; needs TBbias")
nominal_register_values[151] = ("Wbias5", wbias_odd,  "width of trigger output for ch5; needs TBbias")
nominal_register_values[155] = ("Wbias6", wbias_even, "width of trigger output for ch6; needs TBbias")
nominal_register_values[159] = ("Wbias7", wbias_odd,  "width of trigger output for ch7; needs TBbias")
nominal_register_values[160] = ("TBbias", 1000) # needs ITbias - above 1100 doesn't allow for short (7.8ns)) trigger pulses
nominal_register_values[161] = ("Vbias", 1100) # needs ITbias - this alone draws 200mA extra
nominal_register_values[162] = ("Vbias2", 950) # needs ITbias - this also draws an extra ~200mA
nominal_register_values[163] = ("ITbias", 1000)
nominal_register_values[164] = ("dualWbias01", wbias_dual) # needs TBbias and ITbias
nominal_register_values[165] = ("dualWbias23", wbias_dual) # needs TBbias and ITbias
nominal_register_values[166] = ("dualWbias45", wbias_dual) # needs TBbias and ITbias
nominal_register_values[167] = ("dualWbias67", wbias_dual) # needs TBbias and ITbias
nominal_register_values[168] = ("reg168", (0<<9) | (0<<7) | (0<<6) | (0<<5) | (0<<4) | (1<<3) | (1<<2) | (0<<1) | 1, "spy_s2, spy_s1, spy_s0, -, OSH, spy_vs_spy, SSHSH, WR_SSEL, done_mask, trg_x1/x4, trg_x4/x16, trg_sgn")
nominal_register_values[169] = ("CMPbias2", 737) # needs SBbias and DBbias
nominal_register_values[170] = ("PUbias", 3112) # needs SBbias and DBbias
nominal_register_values[171] = ("CMPbias", 1000) # needs SBbias and DBbias
nominal_register_values[172] = ("SBbias", 1300) # needs DBbias
nominal_register_values[173] = ("Vdischarge", 0) # needs DBbias
nominal_register_values[174] = ("ISEL", 2200) # needs DBbias
nominal_register_values[175] = ("DBbias", 1300)
nominal_register_values[176] = ("VtrimT", 4090) # needs VQbuff
#nominal_register_values[177] = ("Qbias", 1300, "set to 0 until DLL set"]) # needs VQbuff
nominal_register_values[177] = ("Qbias", 0, "set to 0 until DLL set") # needs VQbuff
nominal_register_values[178] = ("VQbuff", 1300)
nominal_register_values[179] = ("reg179", (0<<7) | (0<<6) | (0<<5) | 0, "nCLR_PHASE, nTime1Time2 (for swapping montiming1 and montiming2), SSTSEL, -, -, montiming select (3bit): A1, B1, A2, B2, PHASE, PHAB, SSPin, WR_STRB")
nominal_register_values[180] = ("VadjP", 2700) # needs VAPbuff
nominal_register_values[181] = ("VAPbuff", 3500, "set to 0 for DLL mode")
nominal_register_values[182] = ("VadjN", 1530) # needs VANbuff
nominal_register_values[183] = ("VANbuff", 3500, "set to 0 for DLL mode")
nominal_register_values[184] = ("WR_SYNC_LE", 0, "leading edge") # this drives the wr_syncmon pin
nominal_register_values[185] = ("WR_SYNC_TE", 30, "trailing edge") # this drives the wr_syncmon pin
nominal_register_values[186] = ("SSPin_LE", 92, "leading edge")
nominal_register_values[187] = ("SSPin_TE", 10, "trailing edge")
nominal_register_values[188] = ("S1_LE", 38, "leading edge")
nominal_register_values[189] = ("S1_TE", 86, "trailing edge")
nominal_register_values[190] = ("S2_LE", 120, "leading edge")
nominal_register_values[191] = ("S2_TE", 20, "trailing edge")
nominal_register_values[192] = ("PHASE_LE", 45, "leading edge")
nominal_register_values[193] = ("PHASE_TE", 85, "trailing edge")
nominal_register_values[194] = ("WR_STRB_LE", 95, "leading edge")
nominal_register_values[195] = ("WR_STRB_TE", 17, "trailing edge")
nominal_register_values[196] = ("SSToutFB", 110, "")
#nominal_register_values[197] = ("spare1", )
#nominal_register_values[198] = ("spare2", )
#nominal_register_values[199] = ("TPG", 0x402, "test pattern generator (12bit)")
nominal_register_values[199] = ("TPG", default_tpg, "test pattern generator (12bit); page 40 of schematics")
nominal_register_values[200] = ("LD_RD_ADDR", (1<<9) | 0, "rd_ena, RD_ADDR read address (9bit)")
nominal_register_values[201] = ("LOAD_SS", (1<<11) | (0<<6) | 0, "ss_dir, -, -, channel (3bit), sample select (6bit); set ss_dir=0 to load from here; then set ss_dir to 1 to have it increment from there; page 46 of schematics")
nominal_register_values[202] = ("Jam_SS", (0<<1) | 1, "Nib ADDR (3bit), SS_ENA (must be a one to enable channel select decoder); pages 41 and 46 of schematics")
nominal_register_values[252] = ("CLR_Sync", 1, "WR_ADDR addr mode (no data)")
nominal_register_values[253] = ("CatchSpy", 1, "WR_ADDR addr mode (no data)")

def change_timing_register_LE_value(increment):
	bank = 7
	offset = 182
	address = offset + 2*timing_register_to_control
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + address, 1, False)
	value = (readback[0]&0xfff) + increment
	if 255<value:
		value = 0
	if value<0:
		value = 255
	print(str(address) + " " + str(value))
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value])

def change_timing_register_TE_value(increment):
	bank = 7
	offset = 183
	address = offset + 2*timing_register_to_control
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + address, 1, False)
	value = (readback[0]&0xfff) + increment
	if 255<value:
		value = 0
	if value<0:
		value = 255
	print(str(address) + " " + str(value))
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value])

def clear_all_registers_quickly():
	print("clearing all registers quickly...")
	bank = 7
	values = [ 0 for i in range(256) ]
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH, values)

def clear_all_registers_slowly():
	print("clearing all registers slowly...")
	bank = 7
	values = [ 0 for address in range(256) ]
	for address in range(256):
		print(str(address) + " " + str(values[address]))
		althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [values[address]])
		time.sleep(0.1)

def bump_wbias_even(amount):
	global wbias_even
	wbias_even += amount
	if wbias_even<MIN_DAC_VALUE:
		wbias_even = MIN_DAC_VALUE
	elif MAX_DAC_VALUE<wbias_even:
		wbias_even = MAX_DAC_VALUE
	write_wbias_block_using_read_modify_write()

def bump_wbias_odd(amount):
	global wbias_odd
	wbias_odd += amount
	if wbias_odd<MIN_DAC_VALUE:
		wbias_odd = MIN_DAC_VALUE
	elif MAX_DAC_VALUE<wbias_odd:
		wbias_odd = MAX_DAC_VALUE
	write_wbias_block_using_read_modify_write()

def bump_wbias_dual(amount):
	global wbias_dual
	wbias_dual += amount
	if wbias_dual<MIN_DAC_VALUE:
		wbias_dual = MIN_DAC_VALUE
	elif MAX_DAC_VALUE<wbias_dual:
		wbias_dual = MAX_DAC_VALUE
	write_wbias_block_using_read_modify_write()

def write_wbias_block_using_read_modify_write():
	bank = 7
	starting_address = 131
	ending_address = 167
	block_length = ending_address - starting_address + 1
	#print("starting_address: " + str(starting_address))
	#print("ending_address: " + str(ending_address))
	#print("block_length: " + str(block_length))
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + starting_address, block_length, False)
	for i in range(len(readback)):
		readback[i] &= 0xfff
	#print(str(readback))
	for i in range(4):
		additional_address = 8 * i
		value = wbias_even
		readback[additional_address] = value
		additional_address = 8 * i + 4
		value = wbias_odd
		readback[additional_address] = value
		additional_address = 164 - 131 + i
		value = wbias_dual
		readback[additional_address] = value
	print(str(readback))
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + starting_address, readback)

def readback_asic_register_values():
	bank = 7
	starting_address = 0
	ending_address = 255
	block_length = ending_address - starting_address + 1
	#print("starting_address: " + str(starting_address))
	#print("ending_address: " + str(ending_address))
	#print("block_length: " + str(block_length))
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + starting_address, block_length, False)
	print("reg val name+description")
	for i in range(128, 255):
		if len(nominal_register_values[i]):
			readback[i] &= 0xfff
			string = nominal_register_values[i][0]
			if 2<len(nominal_register_values[i]):
				string += " " + nominal_register_values[i][2]
			print(str(i) + " " + hex(readback[i], 3) + " " + string)

def write_nominal_register_values_using_read_modify_write():
	bank = 7
	starting_address = 0
	ending_address = 255
	block_length = ending_address - starting_address + 1
	#print("starting_address: " + str(starting_address))
	#print("ending_address: " + str(ending_address))
	#print("block_length: " + str(block_length))
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + starting_address, block_length, False)
	for i in range(len(readback)):
		readback[i] &= 0xfff
	for i in range(len(nominal_register_values)):
		if len(nominal_register_values[i]):
			string = nominal_register_values[i][0]
			value = nominal_register_values[i][1]
			print(str(i) + " " + string + " " + str(value))
			readback[i] = value
	#print(str(readback))
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + starting_address, readback)

#def write_nominal_register_values():
#	bank = 7
#	for i in range(len(nominal_register_values)):
#		value = nominal_register_values[i][1]
#		print(str(address) + " " + nominal_register_values[i][0] + " " + str(value))
#	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH, values)
#	time.sleep(0.01)

#def write_some_nominal_register_values(string, value):
#	bank = 7
#	for i in range(len(nominal_register_values)):
#		match = re.search(string, nominal_register_values[i][1])
#		if match:
#			address = nominal_register_values[i][0]
#			value = nominal_register_values[i][2]
#			print(str(address) + " " + nominal_register_values[i][1] + " " + str(value))
#			althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value])
#			time.sleep(0.1)

#def clear_vbiases():
#	write_some_updated_register_values("vbias", 0)

def write_new_read_address(new_read_address):
	if new_read_address<0:
		new_read_address = 0
	if 255<new_read_address:
		new_read_address = 255
	value = (1<<9) | new_read_address
	#print(hex(new_read_address) + ", " + hex(value))
	bank = 7
	i = 200
	print(str(i) + " " + hex(value, 3) + " " + nominal_register_values[i][0])
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + i, [value])
	time.sleep(0.1)

def digitize_a_range_of_windows_and_read_them_out(first, last):
	for i in range(first, last+1):
		write_new_read_address(i)
		send_signal_to_start_wilkinson_conversion()
		time.sleep(0.2)
		read_bank5_data()

def digitize_some_windows_and_read_them_out():
	#digitize_a_range_of_windows_and_read_them_out(0, 15)
	digitize_a_range_of_windows_and_read_them_out(0, 1)

reg179_names = [ "A1", "B1", "A2", "B2", "PHASE", "PHAB", "SSPin", "WR_STRB" ]
def write_reg179(value):
	bank = 7
	address = 179
	print(str(address) + " reg179 " + str(value) + " " + reg179_names[value])
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value])

montiming_sel = 0
def cycle_reg179():
	global montiming_sel
	montiming_sel += 1
	if 7<montiming_sel:
		montiming_sel = 0
	if montiming_sel<0:
		montiming_sel = 7
	write_reg179(montiming_sel)

def write_pseudorandom_values_to_a_few_trimdacs_for_fun():
	quantity = 4
	bank = 7
	values = [ random.randint(0, 2**12-1) for a in range(quantity) ]
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH, values)
	time.sleep(0.001)
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, quantity)
	for i in range(quantity):
		print(hex(readback[i], 6))

scalers =  [ 0 for i in range(8) ]
counters = [ 0 for i in range(8) ]
def readout_counters_and_scalers():
	bank = 6
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, 16, False)
	global scalers, counters
	counters[0] = readback[0]
	counters[1] = readback[1]
	counters[2] = readback[2]
	counters[3] = readback[3]
	counters[4] = readback[4]
	counters[5] = readback[5]
	counters[6] = readback[6]
	counters[7] = readback[7]
	scalers[0] = readback[8]
	scalers[1] = readback[9]
	scalers[2] = readback[10]
	scalers[3] = readback[11]
	scalers[4] = readback[12]
	scalers[5] = readback[13]
	scalers[6] = readback[14]
	scalers[7] = readback[15]

def print_scalers(prefix=""):
	string = prefix
	for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
		string += " " + hex(scalers[k], display_precision_of_hex_scaler_counts)
	print(string)

def update_scalers():
	global bank_scalers_object
	try:
		bank_scalers_object[0].get_size()
	except:
		bank_scalers_object = [ 0 for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
	if should_show_scalers:
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			try:
				temp_surface = pygame.Surface(bank_scalers_object[k].get_size())
				temp_surface.fill(purple)
				screen.blit(temp_surface, bank_scalers_object[k].get_rect(center=(X_POSITION_OF_SCALERS-bank_scalers_object[k].get_width()//2,Y_POSITION_OF_SCALERS+FONT_SIZE_BANKS*k)))
			except Exception as e:
				#print(str(e))
				pass
			bank_scalers_object[k] = banks_font.render(hex(scalers[k], display_precision_of_hex_scaler_counts, True), False, white)
			screen.blit(bank_scalers_object[k], bank_scalers_object[k].get_rect(center=(X_POSITION_OF_SCALERS-bank_scalers_object[k].get_width()//2,Y_POSITION_OF_SCALERS+FONT_SIZE_BANKS*k)))

def update_counters():
	global bank_counters_object
	try:
		bank_counters_object[0].get_size()
	except:
		bank_counters_object = [ 0 for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
	if should_show_counters:
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			try:
				temp_surface = pygame.Surface(bank_counters_object[k].get_size())
				temp_surface.fill(red)
				screen.blit(temp_surface, bank_counters_object[k].get_rect(center=(X_POSITION_OF_COUNTERS-bank_counters_object[k].get_width()//2,Y_POSITION_OF_COUNTERS+FONT_SIZE_BANKS*k)))
			except Exception as e:
				#print(str(e))
				pass
			bank_counters_object[k] = banks_font.render(hex(counters[k], display_precision_of_hex_counter_counts, True), False, white)
			screen.blit(bank_counters_object[k], bank_counters_object[k].get_rect(center=(X_POSITION_OF_COUNTERS-bank_counters_object[k].get_width()//2,Y_POSITION_OF_COUNTERS+FONT_SIZE_BANKS*k)))

MIN_DAC_VALUE =    1
MAX_DAC_VALUE = 4094
threshold_for_peak_scaler       = [ MIN_DAC_VALUE for i in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
threshold_for_upper_null_scaler = [ MAX_DAC_VALUE for i in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
threshold_for_lower_null_scaler = [ MIN_DAC_VALUE for i in range(NUMBER_OF_CHANNELS_PER_ASIC) ]

def run_threshold_scan():
	# 400mV sine wave gives a threshold scan from 0x200 to 0xaf0
	if "upper"==cliff:
		threshold = load_thresholds_corresponding_to_upper_null_scaler()
		threshold = [ threshold[channel] + extra_for_threshold_scan[trigger_gain] for channel in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
		step_size = -step_size_for_threshold_scan
	else:
		threshold = load_thresholds_corresponding_to_lower_null_scaler()
		threshold = [ threshold[channel] - extra_for_threshold_scan[trigger_gain] for channel in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
		step_size = +step_size_for_threshold_scan
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		if threshold[channel]<MIN_DAC_VALUE:
			threshold[channel] = MIN_DAC_VALUE
		elif MAX_DAC_VALUE<threshold[channel]:
			threshold[channel] = MAX_DAC_VALUE
	number_of_steps = number_of_steps_for_threshold_scan // step_size_for_threshold_scan
	print("number_of_steps: " + str(number_of_steps))
	string = ""
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		string += "  " + hex(threshold[channel], 3)
	print(string)
	bank = 7
	global threshold_for_upper_null_scaler, threshold_for_lower_null_scaler
	anything_seen_yet = [ False for channel in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
	still_running = True
	step_number = 0
	while still_running:
		#print(hex(threshold[channel], 3), end="  ")
		write_trigger_thresholds_read_modify_write_style(threshold)
		time.sleep(0.01)
		readout_counters_and_scalers()
		print_scalers(dec(step_number, 3))
		for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
			if threshold_for_peak_scaler[channel]<scalers[channel]:
				threshold_for_peak_scaler[channel] = threshold[channel]
			if scalers[channel]:
				anything_seen_yet[channel] = True
			if not anything_seen_yet[channel]:
				if "upper"==cliff:
					threshold_for_upper_null_scaler[channel] = threshold[channel]
				else:
					threshold_for_lower_null_scaler[channel] = threshold[channel]
			elif scalers[channel]:
				if "upper"==cliff:
					threshold_for_lower_null_scaler[channel] = threshold[channel]
				else:
					threshold_for_upper_null_scaler[channel] = threshold[channel]
		for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
			threshold[channel] += step_size
			if threshold[channel]<MIN_DAC_VALUE:
				threshold[channel] = MIN_DAC_VALUE
			elif MAX_DAC_VALUE<threshold[channel]:
				threshold[channel] = MAX_DAC_VALUE
		step_number += 1
		if number_of_steps<=step_number:
			still_running = False
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		#threshold_for_lower_null_scaler[channel] -= 1
		threshold_for_upper_null_scaler[channel] += 1
		if MAX_DAC_VALUE<threshold_for_upper_null_scaler[channel]:
			threshold_for_upper_null_scaler[channel] = MAX_DAC_VALUE
		if threshold_for_lower_null_scaler[channel]<MIN_DAC_VALUE:
			threshold_for_lower_null_scaler[channel] = MIN_DAC_VALUE
	with open(thresholds_for_lower_null_scalers_filename[trigger_gain], "w") as thresholds_for_lower_null_scalers_file:
		string = ""
		for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
			string += " " + hex(threshold_for_lower_null_scaler[channel], 3)
		thresholds_for_lower_null_scalers_file.write(string + "\n")
	with open(thresholds_for_upper_null_scalers_filename[trigger_gain], "w") as thresholds_for_upper_null_scalers_file:
		string = ""
		for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
			string += " " + hex(threshold_for_upper_null_scaler[channel], 3)
		thresholds_for_upper_null_scalers_file.write(string + "\n")
	print("ch#  low peak   up")
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		print("ch" + str(channel) + "  " + hex(threshold_for_lower_null_scaler[channel], 3) + "  " + hex(threshold_for_peak_scaler[channel], 3) + "  " + hex(threshold_for_upper_null_scaler[channel], 3))
	if "upper"==cliff:
		load_thresholds_corresponding_to_upper_null_scaler()
	else:
		load_thresholds_corresponding_to_lower_null_scaler()

def read_file_containing_thresholds_corresponding_to_lower_null_scaler():
	global number_of_steps_for_threshold_scan
	number_of_steps_for_threshold_scan = default_number_of_steps_for_threshold_scan[trigger_gain]
	start_value = trigger_gain_x1_lower[trigger_gain]
	default_threshold_for_lower_null_scaler = [ start_value for i in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
	if not os.path.exists(thresholds_for_lower_null_scalers_filename[trigger_gain]):
		print("thresholds for null scalers file not found")
		return default_threshold_for_lower_null_scaler
	try:
		with open(thresholds_for_lower_null_scalers_filename[trigger_gain], "r") as thresholds_for_lower_null_scalers_file:
			string = thresholds_for_lower_null_scalers_file.read(256)
			threshold_for_lower_null_scaler = string.split(" ")
			threshold_for_lower_null_scaler = [ i for i in threshold_for_lower_null_scaler if i!='' ]
			#threshold_for_lower_null_scaler.remove('\n')
			threshold_for_lower_null_scaler = [ int(threshold_for_lower_null_scaler[k], 16) for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
			for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
				if threshold_for_lower_null_scaler[channel]<MIN_DAC_VALUE:
					threshold_for_lower_null_scaler[channel] = MIN_DAC_VALUE
			#print(prepare_string_with_thresholds(threshold_for_lower_null_scaler))
			#print("null: " + str(threshold_for_lower_null_scaler))
			number_of_steps_for_threshold_scan = default_number_of_steps_for_threshold_scan_when_valid_threshold_file_exists[trigger_gain]
			return threshold_for_lower_null_scaler
	except:
		print("threshold for null scalers file exists but is corrupted")
		# maybe delete the file here?
		return default_threshold_for_lower_null_scaler

def read_file_containing_thresholds_corresponding_to_upper_null_scaler():
	global number_of_steps_for_threshold_scan
	number_of_steps_for_threshold_scan = default_number_of_steps_for_threshold_scan[trigger_gain]
	start_value = trigger_gain_x1_upper[trigger_gain]
	default_threshold_for_upper_null_scaler = [ start_value for i in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
	if not os.path.exists(thresholds_for_upper_null_scalers_filename[trigger_gain]):
		print("thresholds for null scalers file not found")
		return default_threshold_for_upper_null_scaler
	try:
		with open(thresholds_for_upper_null_scalers_filename[trigger_gain], "r") as thresholds_for_upper_null_scalers_file:
			string = thresholds_for_upper_null_scalers_file.read(256)
			threshold_for_upper_null_scaler = string.split(" ")
			threshold_for_upper_null_scaler = [ i for i in threshold_for_upper_null_scaler if i!='' ]
			#threshold_for_upper_null_scaler.remove('\n')
			threshold_for_upper_null_scaler = [ int(threshold_for_upper_null_scaler[k], 16) for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
			for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
				if MAX_DAC_VALUE<threshold_for_upper_null_scaler[channel]:
					threshold_for_upper_null_scaler[channel] = MAX_DAC_VALUE
			#print(prepare_string_with_thresholds(threshold_for_upper_null_scaler))
			#print("null: " + str(threshold_for_upper_null_scaler))
			number_of_steps_for_threshold_scan = default_number_of_steps_for_threshold_scan_when_valid_threshold_file_exists[trigger_gain]
			return threshold_for_upper_null_scaler
	except:
		raise
		print("threshold for null scalers file exists but is corrupted")
		# maybe delete the file here?
		return default_threshold_for_upper_null_scaler

def load_thresholds_corresponding_to_lower_null_scaler():
	threshold_for_lower_null_scaler = read_file_containing_thresholds_corresponding_to_lower_null_scaler()
	bank = 7
	string = ""
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		address = 128 + 4 * channel
		threshold = threshold_for_lower_null_scaler[channel] - extra_for_setting_thresholds[trigger_gain]
		if threshold<MIN_DAC_VALUE:
			threshold = MIN_DAC_VALUE
		string += "  " + hex(threshold, 3)
		althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [threshold], False)
	print(string)
	return threshold_for_lower_null_scaler

def load_thresholds_corresponding_to_upper_null_scaler():
	threshold_for_upper_null_scaler = read_file_containing_thresholds_corresponding_to_upper_null_scaler()
	bank = 7
	string = ""
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		address = 128 + 4 * channel
		threshold = threshold_for_upper_null_scaler[channel] + extra_for_setting_thresholds[trigger_gain]
		if MAX_DAC_VALUE<threshold:
			threshold = MAX_DAC_VALUE
		string += "  " + hex(threshold, 3)
		althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [threshold], False)
	print(string)
	return threshold_for_upper_null_scaler

def load_thresholds_corresponding_to_null_scaler():
	if "upper"==cliff:
		load_thresholds_corresponding_to_upper_null_scaler()
	else:
		load_thresholds_corresponding_to_lower_null_scaler()

def bump_thresholds(amount):
	bank = 7
	string = ""
	for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
		address = 128 + 4 * channel
		threshold = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + address, 1, False)[0]
		threshold &= 0xfff
		threshold += amount
		if threshold<MIN_DAC_VALUE:
			threshold = MIN_DAC_VALUE
		elif MAX_DAC_VALUE<threshold:
			threshold = MAX_DAC_VALUE
		string += "  " + hex(threshold, 3)
		althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [threshold], False)
	print(string)

def toggle_trigger_sign_bit():
	bank = 7
	address = 168
	reg168_value = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + address, 1, False)[0]
	reg168_value ^= 1
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [reg168_value])
	print("toggled trigger sign bit: " + str(reg168_value & 1))

def set_trigger_gain(value):
	global trigger_gain
	trigger_gain = value # 0="x1", 1="x4", 2="x16"
	bank = 7
	address = 168
	mask = 0b110
	reg168_value = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + address, 1, False)[0]
	reg168_value &= 0xfff
	reg168_value = reg168_value & ~mask
	if 0==trigger_gain:
		new_trig_gain = 0b00 # x1
		trigger_gain = 0
	elif 1==trigger_gain:
		new_trig_gain = 0b10 # x4
		trigger_gain = 1
	else:
		new_trig_gain = 0b11 # x16
		trigger_gain = 2
	reg168_value |= new_trig_gain<<1
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [reg168_value])

def cycle_through_x1_x4_x16_trigger_gains():
	global trigger_gain
	bank = 7
	address = 168
	mask = 0b110
	reg168_value = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + address, 1, False)[0]
	reg168_value &= 0xfff
	#print("reg168 before: " + hex(reg168_value, 3))
	new_trig_gain = (reg168_value & mask)>>1
	#print("trig_gain before: " + hex(new_trig_gain, 1))
	if 0b10==new_trig_gain: # was x4
		new_trig_gain = 0b11 # x16
		trigger_gain = 2
	elif 0b11==new_trig_gain: # was x16
		new_trig_gain = 0b00 # x1
		trigger_gain = 0
	else:
		new_trig_gain = 0b10 # x4
		trigger_gain = 1
	print("trig gain = " + str(trigger_gain))
	#print("trig_gain after: " + hex(new_trig_gain, 1))
	reg168_value = reg168_value & ~mask
	reg168_value |= new_trig_gain<<1
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [reg168_value])
	#print("reg168 after: " + hex(reg168_value, 3))
	if "upper"==cliff:
		load_thresholds_corresponding_to_upper_null_scaler()
	else:
		load_thresholds_corresponding_to_lower_null_scaler()

def write_new_tpg_value(tpg):
	bank = 7
	tpg &= 0xfff
	#althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 199, [tpg])
	althea.write_to_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 199, [tpg])

def send_unique_test_pattern(value):
	if 0==value:
		write_new_tpg_value(0xaf5)
	elif 1==value:
		write_new_tpg_value(0x5fa)
	else:
		print("WARNING: no value set up for this input")
		write_new_tpg_value(0)

def test_tpg_as_a_pollable_memory():
	address = [ random.randint(0, 2**12-1) for a in range(2**12) ]
	value = [ i for i in range(2**12) ]
	random.shuffle(value)
	count = 0
	total = 2**12
	for i in range(total):
		if i%58==0:
			print("")
			print("#" + hex(i,3) + "  ", end=" ")
		write_new_tpg_value(value[i])
		time.sleep(0.000001)
		readback = read_hs_data()
		if not value[i]==readback[0]&0xfff:
			print(hex(value[i], 3) + ":" + hex(readback[0]&0xfff, 3), end=" ")
			count += 1
	print("")
	print("there were " + str(count) + " errors out of " + str(total) + " (" + str(int(100*count/total)) + "%)")

def read_hs_data():
	bank = 1
	readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 8, 1, False)
	return readback

def gather_pedestals(i):
	global pedestal_mode, pedestal_data, pedestals_have_been_taken
	pedestal_mode = True
	number_of_acquisitions_so_far = [ [ 0 for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ] for j in range(ROWS) ]
	for j in range(ROWS):
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			for n in range(MAX_SAMPLES_PER_WAVEFORM):
				pedestal_data[i][j][k][n] = 0
	not_done = True
	while not_done:
		for j in range(ROWS):
			have_just_gathered_waveform_data[which_plot] = False
		initiate_trigger()
		readout_some_data_from_the_fifo(number_of_words_to_read_from_the_fifo)
		for j in range(ROWS):
			if have_just_gathered_waveform_data[which_plot]:
				for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
					if not enabled_channels[k]:
						continue
					if number_of_acquisitions_so_far[j][k]<2**LOG2_OF_NUMBER_OF_PEDESTALS_TO_ACQUIRE:
						number_of_acquisitions_so_far[j][k] += 1
						#if 15==k:
						#	print("waveform_data[" + str(j) + "][" + str(k) + "]: " + str(waveform_data[i][j][k]))
						for n in range(MAX_SAMPLES_PER_WAVEFORM):
							pedestal_data[i][j][k][n] += waveform_data[i][j][k][n]
						#if 15==k:
						#	print("pedestal_data[" + str(j) + "][" + str(k) + "]: " + str(pedestal_data[i][j][k]))
			print("number_of_acquisitions_so_far[" + str(j) + "]: " + str(number_of_acquisitions_so_far[j]))
		not_done = False
		for j in range(ROWS):
			for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
				if not enabled_channels[k]:
					continue
				if number_of_acquisitions_so_far[j][k]<2**LOG2_OF_NUMBER_OF_PEDESTALS_TO_ACQUIRE:
					not_done = True
	global average_pedestal
	for j in range(ROWS):
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			if not enabled_channels[k]:
				continue
			average_pedestal[j][k] = 0.0
			for n in range(MAX_SAMPLES_PER_WAVEFORM):
				pedestal_data[i][j][k][n] >>= LOG2_OF_NUMBER_OF_PEDESTALS_TO_ACQUIRE
				average_pedestal[j][k] += pedestal_data[i][j][k][n]
			average_pedestal[j][k] /= MAX_SAMPLES_PER_WAVEFORM
			print("average_pedestal for ch" + str(k) + " bank" + str(j) + ": " + str(average_pedestal[j][k]))
	for j in range(ROWS):
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			for n in range(MAX_SAMPLES_PER_WAVEFORM):
				pedestal_data[0][j][k][n] = pedestal_data[i][j][k][n]
				pedestal_data[1][j][k][n] = pedestal_data[i][j][k][n]
				pedestal_data[2][j][k][n] = pedestal_data[i][j][k][n]
			#if 15==k:
			#	print("pedestal_data[" + str(j) + "][" + str(k) + "]: " + str(pedestal_data[i][j][k]))
	print("pedestals acquired")
	pedestals_have_been_taken = True
	pedestal_mode = False
	for j in range(ROWS):
		have_just_gathered_waveform_data[0][j] = True
		have_just_gathered_waveform_data[1][j] = False
		have_just_gathered_waveform_data[2][j] = False
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			if not enabled_channels[k]:
				continue
			#print("peds for ch" + str(k) + " bank" + str(j) + ": " + str(pedestal_data[i][j][k]))

if __name__ == "__main__":
	datafile = open(datafile_name, "a")
	#ROWS = 2
	#COLUMNS = 3
	#wasted_width = int(GAP_X_LEFT + GAP_X_RIGHT + (COLUMNS-1)*GAP_X_BETWEEN_PLOTS)
	#desired_window_width = int(COLUMNS * box_dimension_x_in * scale_pixels_per_in + wasted_width)
	SCREEN_WIDTH = 1100
	SCREEN_HEIGHT = 900
	#plots_were_updated = [ [ False for j in range(ROWS) ] for i in range(COLUMNS) ]
	#plot_name = [ [ "alpha" for j in range(ROWS) ] for i in range(COLUMNS) ]
	#plot_name = [ ["pedestals(bankA)","pedestals(bankB)"], ["RAW(bankA)","RAW(bankB)"], ["pedestal subtracted(bankA)","pedestal subtracted(bankB)"] ]
	#data_and_pedestal_coefficients = [ [0,1], [1,0], [1,-1] ]
	#short_feed_name = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
	#minimum = [ [ 0 for j in range(ROWS) ] for i in range(COLUMNS) ]
	#maximum = [ [ 100 for j in range(ROWS) ] for i in range(COLUMNS) ]
	#waveform_data = [ [ [ [ 0 for n in range(MAX_SAMPLES_PER_WAVEFORM) ] for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ] for j in range(ROWS) ] for i in range(COLUMNS) ]
	#pedestal_data = [ [ [ [ 0 for n in range(MAX_SAMPLES_PER_WAVEFORM) ] for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ] for j in range(ROWS) ] for i in range(COLUMNS) ]
	#average_pedestal = [ [ 2047.0 for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ] for j in range(ROWS) ]
	setup()
	#write_to_pollable_memory_value()
	running = True
	while running:
		loop()
		sys.stdout.flush()
	pygame.quit()

