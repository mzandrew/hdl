#!/usr/bin/env python3

# written 2023-08-23 by mza
# based on alpha_readout.py
# based on protodune_LBLS_readout.py
# with help from https://realpython.com/pygame-a-primer/#displays-and-surfaces
# last updated 2024-05-22 by mza

bank0_register_names = [ "clk_div", "max_retries", "verify_with_shout", "clear_channel_counters", "trg_inversion_mask" ]
bank1_register_names = [ "hdrb errors, status8", "reg transactions", "readback errors", "last_erroneous_readback" ]
bank4_register_names = [ "CMPbias", "ISEL", "SBbias", "DBbias" ]
bank6_register_names = [ "bank0 read strobe count", "bank1 read strobe count", "bank2 read strobe count", "bank3 read strobe count", "bank4 read strobe count", "bank5 read strobe count", "bank6 read strobe count", "bank7 read strobe count", "bank0 write strobe count", "bank1 write strobe count", "bank2 write strobe count", "bank3 write strobe count", "bank4 write strobe count", "bank5 write strobe count", "bank6 write strobe count", "bank7 write strobe count" ]
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
enabled_channels = [ 0, 0, 0, 0,  0, 1, 0, 0,  0, 0, 0, 0,  0, 0, 1, 0 ] # two good channels
#enabled_channels = [ 1, 0, 0, 0,  0, 1, 1, 0,  0, 0, 0, 0,  0, 0, 0, 1 ] # how the board is wired
#enabled_channels = [ 1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1,  1, 1, 1, 1 ] # all channels
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
MAX_SAMPLES_PER_WAVEFORM = 256
timestep = 1

NUMBER_OF_CHANNELS_PER_ASIC = 8
gui_update_period = 0.2 # in seconds

MAX_ADC = 4095
display_precision_of_hex_counter_counts = 6
display_precision_of_hex_scaler_counts = 4

GAP_X_BETWEEN_PLOTS = 20
GAP_Y_BETWEEN_PLOTS = 44
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
X_POSITION_OF_CHANNEL_NAMES = 15
X_POSITION_OF_COUNTERS = 140
X_POSITION_OF_SCALERS = 190
#X_POSITION_OF_TOT = 450
X_POSITION_OF_BANK0_REGISTERS = 100
X_POSITION_OF_BANK1_REGISTERS = 100
X_POSITION_OF_BANK4_REGISTERS = 100
X_POSITION_OF_BANK6_REGISTERS = 400

box_dimension_x_in = 3.0
box_dimension_y_in = 2.0
scale_pixels_per_in = 80

#channel_range = range(1, NUMBER_OF_CHANNELS_PER_ASIC+1)

channel_names = [ "" ]
channel_names.extend(["ch" + str(i+1) for i in range(NUMBER_OF_CHANNELS_PER_ASIC)])
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

# grey
color = [ black, white, yellow, red, dark_red, pink, maroon, purple, orange, dark_purple, green, light_blue, dark_teal, dark_green, blue, dark_blue, teal, grey, brown ]

selection = 0
coax_mux = [ 0 for i in range(4) ]

should_show_counters = True
should_show_scalers = True
should_show_bank0_registers = False
should_show_bank1_registers = True
should_show_bank4_registers = False
should_show_bank6_registers = False
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

from generic import * # hex, eng
import althea
BANK_ADDRESS_DEPTH = 13

def update_plot(i, j):
	global plots_were_updated
	pygame.event.pump()
	formatted_data = [ [ 0 for x in range(plot_width) ] for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ]
	scale = 1.0 / MAX_ADC
	#print(str(scale))
	max_data_value_seen = 0
	for n in range(len(waveform_data[i][j][0])):
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			if not enabled_channels[k]:
				continue
			if max_data_value_seen<waveform_data[i][j][k][n]:
				max_data_value_seen = waveform_data[i][j][k][n]
			voltage = data_and_pedestal_coefficients[i][0] * waveform_data[i][j][k][n]
			#if 15==k and 0==n:
			#	voltage = MAX_ADC
			# when the TDC should be pegged near ~4095 for large input voltages, the decoded gcc_counter rolls over to a low number
			if pedestals_have_been_taken:
				if 0==i:
					voltage += data_and_pedestal_coefficients[i][1] * pedestal_data[i][j][k][n]
				else:
					voltage += data_and_pedestal_coefficients[i][1] * (pedestal_data[i][j][k][n] - average_pedestal[j][k])
			time = timestep*n
			x = int(time)
			formatted_data[k][x] = voltage * scale
			#if 0==n%40:
			#	print(str(time) + "," + str(voltage) + ":" + str(x) + ":" + str(formatted_data[k][x]))
	print("max_data_value_seen: 0x" + hex(max_data_value_seen, 3))
	pygame.event.pump()
	print("plotting data...")
	# fill with colors for now:
	#plot[i][j].fill((random.randrange(0, 255), random.randrange(0, 255), random.randrange(0, 255)))
	print("[" + str(i) + "][" + str(j) + "]")
	plot[i][j].fill(black)
	how_many_times_we_did_not_plot = 0
	offscale_count = 0
	number_of_enabled_channels = sum(enabled_channels)
	#print("plot_height: " + str(plot_height))
	#print("extra_gap_y: " + str(extra_gap_y))
	first_y = extra_gap_y
	last_y = plot_height - extra_gap_y
	scale_y = last_y - first_y
	for x in range(extra_gap_x, plot_width-extra_gap_x):
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
					plot[i][j].set_at((x, y), color[k+2]) # first two indices are black and white
		if how_many_things_were_plotted_at_this_x_value<number_of_enabled_channels:
			#print(str(x) + ":" + str(how_many_things_were_plotted_at_this_x_value) + "/" + str(number_of_enabled_channels))
			how_many_times_we_did_not_plot += number_of_enabled_channels - how_many_things_were_plotted_at_this_x_value
		if 0:
			if extra_gap_x==x:
				string = ""
				for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
					if not enabled_channels[k]:
						continue
					string += str(formatted_data[k][x-extra_gap_x]) + " " + str(int(plot_height-extra_gap_y-1 - (plot_height-2*extra_gap_y)*formatted_data[k][x-extra_gap_x] + 0.5)) + ", "
				print(string)
	#print("how_many_times_we_did_not_plot: " + str(how_many_times_we_did_not_plot))
	print("offscale_count: " + str(offscale_count))
	plots_were_updated[i][j] = True
	print("done")

def draw_plot_border(i, j):
	#print("drawing plot border...")
	pygame.draw.rect(screen, white, pygame.Rect(GAP_X_LEFT+i*(plot_width+GAP_X_BETWEEN_PLOTS)-1, GAP_Y_TOP+j*(plot_height+GAP_Y_BETWEEN_PLOTS)-1, plot_width+2, plot_height+2), 1)

def setup():
	global plot_width, plot_height, screen, plot, something_was_updated
	something_was_updated = False
	print("screen_width: " + str(SCREEN_WIDTH))
	usable_width = int(SCREEN_WIDTH - GAP_X_LEFT - GAP_X_RIGHT - (COLUMNS-1)*GAP_X_BETWEEN_PLOTS)
	print("usable_width: " + str(usable_width))
	usable_height = int(SCREEN_HEIGHT - GAP_Y_TOP - GAP_Y_BOTTOM - (ROWS-1)*GAP_Y_BETWEEN_PLOTS)
	print("usable_height: " + str(usable_height))
	global extra_gap_x, extra_gap_y
	extra_gap_x = 4
	extra_gap_y = 4
	plot_width = MAX_SAMPLES_PER_WAVEFORM + 2*extra_gap_x
	plot_height = int(0.7 * usable_height / ROWS) + 2*extra_gap_y
	print("plot_width: " + str(plot_width))
	print("plot_height: " + str(plot_height))
	global Y_POSITION_OF_CHANNEL_NAMES
	global Y_POSITION_OF_COUNTERS
	global Y_POSITION_OF_SCALERS
	#global Y_POSITION_OF_TOT
	global Y_POSITION_OF_BANK0_REGISTERS
	global Y_POSITION_OF_BANK1_REGISTERS
	global Y_POSITION_OF_BANK4_REGISTERS
	global Y_POSITION_OF_BANK6_REGISTERS
	gap = 20
	Y_POSITION_OF_CHANNEL_NAMES = ROWS * (plot_height + 2*gap) + FONT_SIZE_BANKS + 75
	Y_POSITION_OF_COUNTERS      = ROWS * (plot_height + 2*gap) + FONT_SIZE_BANKS + 75
	Y_POSITION_OF_SCALERS       = ROWS * (plot_height + 2*gap) + FONT_SIZE_BANKS + 75
	#Y_POSITION_OF_TOT = plot_height + gap + FONT_SIZE_BANKS
	Y_POSITION_OF_BANK0_REGISTERS = ROWS * (plot_height + 2*gap)
	Y_POSITION_OF_BANK1_REGISTERS = ROWS * (plot_height + 2*gap) + 25
	Y_POSITION_OF_BANK4_REGISTERS = ROWS * (plot_height + 2*gap) + 170
	Y_POSITION_OF_BANK6_REGISTERS = ROWS * (plot_height + 2*gap)
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
	plot = [ [ pygame.Surface((plot_width, plot_height)) for j in range(ROWS) ] for i in range(COLUMNS) ]
	width = int(box_dimension_x_in * scale_pixels_per_in)
	height = int(box_dimension_y_in * scale_pixels_per_in)
	global flarb
	flarb = [ [ pygame.Surface((width, height)) for j in range(ROWS) ] for i in range(COLUMNS) ]
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
	if should_show_bank6_registers:
		for i in range(len(bank6_register_names)):
			register_name = banks_font.render(bank6_register_names[i], 1, white)
			screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK6_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK6_REGISTERS+FONT_SIZE_BANKS*i)))
	#for i in range(NUMBER_OF_CHANNELS_PER_ASIC):
#	for i in range(len(channel_names)):
#		register_name = banks_font.render(channel_names[i], 1, white)
#		screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_CHANNEL_NAMES+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_CHANNEL_NAMES+FONT_SIZE_BANKS*i)))
	#for i in range(NUMBER_OF_CHANNELS_PER_ASIC):
	#	channel_name = banks_font.render(channel_names[i], 1, white)
	#	screen.blit(channel_name, channel_name.get_rect(center=(X_POSITION_OF_BANK6_COUNTERS+BANKS_X_GAP+channel_name.get_width()//2,Y_POSITION_OF_BANK6_COUNTERS+FONT_SIZE_BANKS*i)))
	for i in range(COLUMNS):
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
			pygame.event.pump()
			draw_plot_border(i, j)
#			update_plot(i, j)
#			blit(i, j)
			#draw_photodiode_box(i, j)
			flip()
			sys.stdout.flush()
	althea.setup_half_duplex_bus("test058")
	global should_check_for_new_data
	should_check_for_new_data = pygame.USEREVENT + 1
	print("gui_update_period: " + str(gui_update_period))
	pygame.time.set_timer(should_check_for_new_data, int(gui_update_period*1000/COLUMNS/ROWS))
	write_bootup_values()

def write_bootup_values():
	#set_ls_i2c_mode(1) # ls_i2c: 0=i2c; 1=LS
	#write_DAC_values()
	#write_I2C_register_values()
	write_value_to_clock_divider_for_register_transactions(3)
	set_max_retries_for_register_transactions(5)
	set_whether_to_verify_with_shout(0)
	set_trg_inversion_mask(0b1100)

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
	mouse = pygame.mouse.get_pos()
	from pygame.locals import K_UP, K_DOWN, K_LEFT, K_RIGHT, K_ESCAPE, KEYDOWN, QUIT, K_BREAK, K_SPACE, K_F1, K_F2, K_F3, K_F4, K_F5, K_F6, K_F7, K_F8, K_F9, K_F10, K_F11, K_F12, K_c, K_d, K_p, K_s, K_z, K_q, K_w, K_1, K_2, K_3, K_4, K_5, K_6, K_RIGHTBRACKET, K_LEFTBRACKET
	for event in pygame.event.get():
		if event.type == KEYDOWN:
			if K_ESCAPE==event.key:
				running = False
			elif K_1==event.key:
				timing_register_to_control = 1
				print("now controlling WR_SYNC")
			elif K_2==event.key:
				timing_register_to_control = 2
				print("now controlling SSP_in")
			elif K_3==event.key:
				timing_register_to_control = 3
				print("now controlling S1")
			elif K_4==event.key:
				timing_register_to_control = 4
				print("now controlling S2")
			elif K_5==event.key:
				timing_register_to_control = 5
				print("now controlling PHASE")
			elif K_6==event.key:
				timing_register_to_control = 6
				print("now controlling WR_STRB")
			elif K_F1==event.key:
				reprogram_fpga()
			elif K_F2==event.key:
				run_threshold_scan()
			elif K_F3==event.key:
				write_nominal_register_values()
			elif K_F4==event.key:
				clear_all_registers_quickly()
				#clear_all_registers_slowly()
			elif K_p==event.key:
#				initiate_trigger()
				gather_pedestals(1)
			elif K_F5==event.key:
				#readout_some_data_from_the_fifo(number_of_words_to_read_from_the_fifo)
				cycle_reg179()
			elif K_F6==event.key:
				initiate_trigger()
				readout_some_data_from_the_fifo(number_of_words_to_read_from_the_fifo)
				#drain_fifo()
			elif K_F9==event.key:
				DAC_to_control = 0
				print("now controlling CMPbias")
			elif K_F10==event.key:
				DAC_to_control = 1
				print("now controlling ISEL")
			elif K_F11==event.key:
				DAC_to_control = 2
				print("now controlling SBbias")
			elif K_F12==event.key:
				DAC_to_control = 3
				print("now controlling DBbias")
			elif K_c==event.key:
				clear_channel_counters()
			elif K_q==event.key:
				change_timing_register_LE_value(-2)
			elif K_w==event.key:
				change_timing_register_LE_value(+2)
			elif K_LEFTBRACKET==event.key:
				change_timing_register_TE_value(-2)
			elif K_RIGHTBRACKET==event.key:
				change_timing_register_TE_value(+2)
		elif event.type == QUIT:
			running = False
		elif event.type == should_check_for_new_data:
			readout_counters_and_scalers()
			update_scalers()
			update_counters()
			update_bank0_registers()
			update_bank1_registers()
			update_bank4_registers()
			update_bank6_registers()
#			update_bank1_bank2_scalers()
#			update_counters()
	if not pedestal_mode:
		global have_just_gathered_waveform_data
		for i in range(COLUMNS):
			for j in range(ROWS):
				if have_just_gathered_waveform_data[i][j]:
					have_just_gathered_waveform_data[i][j] = False
					update_plot(i, j)
					blit(i, j)
#	draw_photodiode_box(i, j)
	flip()

def blit(i, j):
	global something_was_updated
	if plots_were_updated[i][j]:
		#print("blitting...")
		screen.blit(plot[i][j], (GAP_X_LEFT+i*(plot_width+GAP_X_BETWEEN_PLOTS), GAP_Y_TOP+j*(plot_height+GAP_Y_BETWEEN_PLOTS)))
		pygame.image.save(plot[i][j], "alpha.data." + str(i) + ".png")
		pygame.event.pump()
		plots_were_updated[i][j] = False
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

def read_bank6_registers():
	global bank6_register_values
	bank = 6
	bank6_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, len(bank6_register_names), False)

bank0_register_object = [ 0 for i in range(len(bank0_register_names)) ]
bank1_register_object = [ 0 for i in range(len(bank1_register_names)) ]
bank4_register_object = [ 0 for i in range(len(bank1_register_names)) ]
bank6_register_object = [ 0 for i in range(len(bank6_register_names)) ]

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

def set_ls_i2c_mode(mode):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, [mode], False)

def write_DAC_values():
	bank = 4
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, DAC_values, False)

def change_number_of_samples(value):
	global previous_number_of_samples, number_of_samples
	previous_number_of_samples = number_of_samples
	print("previous_number_of_samples: " + str(previous_number_of_samples))
	print("current number_of_samples: " + str(number_of_samples))
	print("desired number_of_samples: " + str(value))
	number_of_samples = value
	if number_of_samples<0:
		number_of_samples = 0 # 0 means 256 here
	elif 255<number_of_samples:
		number_of_samples = 0 # 0 means 256 here
	write_I2C_register_values()
	initiate_i2c_transfer()
	return previous_number_of_samples

def write_I2C_register_values():
	SRC = I2CupAddr<<3 | LVDSB_pwr<<2 | LVDSA_pwr<<1 | SRCsel
	I2C_register_values = [ 0, SRC, TMReg_Reset, samples_after_trigger, lookback_windows, number_of_samples ]
	bank = 3
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, I2C_register_values, False)

def change_DAC_value(delta):
	global DAC_values
	DAC_values[DAC_to_control] += delta
	if DAC_values[DAC_to_control]<0:
		DAC_values[DAC_to_control] = 0
	elif 4095<DAC_values[DAC_to_control]:
		DAC_values[DAC_to_control] = 4095
	write_DAC_values()

def initiate_dreset_sequence():
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, [1], False)
	print("dreset")

def write_value_to_clock_divider_for_register_transactions(value=127):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, [value])

def set_max_retries_for_register_transactions(quantity):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 1, [quantity])

def set_whether_to_verify_with_shout(whether_or_not):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 2, [whether_or_not])

def clear_channel_counters():
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 3, [1])

def set_trg_inversion_mask(mask):
	bank = 0
	mask &= 0xf
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 4, [mask])

nominal_register_values = []
# these values are cribbed from asic_configuration.c which has values borrowed from config1asic_trueROI.py; enabling the DLL requires more effort
nominal_register_values.append([128, "TRGthresh0", 0, "threshold voltage for trigger output for ch0"])
nominal_register_values.append([132, "TRGthresh1", 0, "threshold voltage for trigger output for ch1"])
nominal_register_values.append([136, "TRGthresh2", 0, "threshold voltage for trigger output for ch2"])
nominal_register_values.append([140, "TRGthresh3", 0, "threshold voltage for trigger output for ch3"])
nominal_register_values.append([144, "TRGthresh4", 0, "threshold voltage for trigger output for ch4"])
nominal_register_values.append([148, "TRGthresh5", 0, "threshold voltage for trigger output for ch5"])
nominal_register_values.append([152, "TRGthresh6", 0, "threshold voltage for trigger output for ch6"])
nominal_register_values.append([156, "TRGthresh7", 0, "threshold voltage for trigger output for ch7"])
nominal_register_values.append([129, "Trig4xVofs0", 1500, "voltage offset for x4 trigger path for ch0"])
nominal_register_values.append([133, "Trig4xVofs1", 1500, "voltage offset for x4 trigger path for ch1"])
nominal_register_values.append([137, "Trig4xVofs2", 1500, "voltage offset for x4 trigger path for ch2"])
nominal_register_values.append([141, "Trig4xVofs3", 1500, "voltage offset for x4 trigger path for ch3"])
nominal_register_values.append([145, "Trig4xVofs4", 1500, "voltage offset for x4 trigger path for ch4"])
nominal_register_values.append([149, "Trig4xVofs5", 1500, "voltage offset for x4 trigger path for ch5"])
nominal_register_values.append([153, "Trig4xVofs6", 1500, "voltage offset for x4 trigger path for ch6"])
nominal_register_values.append([157, "Trig4xVofs7", 1500, "voltage offset for x4 trigger path for ch7"])
nominal_register_values.append([130, "Trig16xVofs0", 2000, "voltage offset for x16 trigger path for ch0 (warning: affects x4 trigger path)"])
nominal_register_values.append([134, "Trig16xVofs1", 2000, "voltage offset for x16 trigger path for ch1 (warning: affects x4 trigger path)"])
nominal_register_values.append([138, "Trig16xVofs2", 2000, "voltage offset for x16 trigger path for ch2 (warning: affects x4 trigger path)"])
nominal_register_values.append([142, "Trig16xVofs3", 2000, "voltage offset for x16 trigger path for ch3 (warning: affects x4 trigger path)"])
nominal_register_values.append([146, "Trig16xVofs4", 2000, "voltage offset for x16 trigger path for ch4 (warning: affects x4 trigger path)"])
nominal_register_values.append([150, "Trig16xVofs5", 2000, "voltage offset for x16 trigger path for ch5 (warning: affects x4 trigger path)"])
nominal_register_values.append([154, "Trig16xVofs6", 2000, "voltage offset for x16 trigger path for ch6 (warning: affects x4 trigger path)"])
nominal_register_values.append([158, "Trig16xVofs7", 2000, "voltage offset for x16 trigger path for ch7 (warning: affects x4 trigger path)"])
nominal_register_values.append([131, "Wbias0", 1100, "width of trigger output for ch0"])
nominal_register_values.append([135, "Wbias1", 1100, "width of trigger output for ch1"])
nominal_register_values.append([139, "Wbias2", 1100, "width of trigger output for ch2"])
nominal_register_values.append([143, "Wbias3", 1100, "width of trigger output for ch3"])
nominal_register_values.append([147, "Wbias4", 1100, "width of trigger output for ch4"])
nominal_register_values.append([151, "Wbias5", 1100, "width of trigger output for ch5"])
nominal_register_values.append([155, "Wbias6", 1100, "width of trigger output for ch6"])
nominal_register_values.append([159, "Wbias7", 1100, "width of trigger output for ch7"])
nominal_register_values.append([160, "TBbias", 1300]) # needs ITbias
#nominal_register_values.append([161, "Vbias", 1100]) # needs ITbias
#nominal_register_values.append([162, "Vbias2", 950]) # needs ITbias
nominal_register_values.append([163, "ITbias", 1300])
nominal_register_values.append([164, "dualWbias01", 900]) # needs TBbias and ITbias
nominal_register_values.append([165, "dualWbias23", 900]) # needs TBbias and ITbias
nominal_register_values.append([166, "dualWbias45", 900]) # needs TBbias and ITbias
nominal_register_values.append([167, "dualWbias67", 900]) # needs TBbias and ITbias
nominal_register_values.append([168, "reg168", 5, "trg_sgn, trig_path"])
nominal_register_values.append([169, "CMPbias2", 737]) # needs SBbias and DBbias
nominal_register_values.append([170, "PUbias", 3112]) # needs SBbias and DBbias
nominal_register_values.append([171, "CMPbias", 1000]) # needs SBbias and DBbias
nominal_register_values.append([172, "SBbias", 1300]) # needs DBbias
nominal_register_values.append([173, "Vdischarge", 0]) # needs DBbias
nominal_register_values.append([174, "ISEL", 2200]) # needs DBbias
nominal_register_values.append([175, "DBbias", 1300])
nominal_register_values.append([176, "VtrimT", 4090]) # needs VQbuff
#nominal_register_values.append([177, "Qbias", 1300, "set to 0 until DLL set"]) # needs VQbuff
nominal_register_values.append([177, "Qbias", 0, "set to 0 until DLL set"]) # needs VQbuff
nominal_register_values.append([178, "VQbuff", 1300])
nominal_register_values.append([179, "reg179", 0, "montiming select (3bit): A1, B1, A2, B2, PHASE, PHAB, SSPin, WR_STRB"])
nominal_register_values.append([180, "VadjP", 2700]) # needs VAPbuff
nominal_register_values.append([181, "VAPbuff", 3500, "set to 0 for DLL mode"])
nominal_register_values.append([182, "VadjN", 1530]) # needs VANbuff
nominal_register_values.append([183, "VANbuff", 3500, "set to 0 for DLL mode"])
nominal_register_values.append([184, "WR_SYNC_LE", 0, "leading edge"])
nominal_register_values.append([185, "WR_SYNC_TE", 30, "trailing edge"])
nominal_register_values.append([186, "SSPin_LE", 92, "leading edge"])
nominal_register_values.append([187, "SSPin_TE", 10, "trailing edge"])
nominal_register_values.append([188, "S1_LE", 38, "leading edge"])
nominal_register_values.append([189, "S1_TE", 86, "trailing edge"])
nominal_register_values.append([190, "S2_LE", 120, "leading edge"])
nominal_register_values.append([191, "S2_TE", 20, "trailing edge"])
nominal_register_values.append([192, "PHASE_LE", 45, "leading edge"])
nominal_register_values.append([193, "PHASE_TE", 85, "trailing edge"])
nominal_register_values.append([194, "WR_STRB_LE", 95, "leading edge"])
nominal_register_values.append([195, "WR_STRB_TE", 17, "trailing edge"])
nominal_register_values.append([196, "SSToutFB", 110, ""])
#nominal_register_values.append([197, "spare1", ])
#nominal_register_values.append([198, "spart2", ])
nominal_register_values.append([199, "TPG", 1026, "test pattern generator (12bit)"])
nominal_register_values.append([200, "LD_RD_ADDR", 2048, "read address (10bit)"])
nominal_register_values.append([201, "LOAD_SS", 0, "sample select (9bit) + channel (3bit)"])
nominal_register_values.append([202, "Jam_SS", 1, "set Nib ADDR"])
nominal_register_values.append([252, "CLR_Sync", 1, "WR_ADDR addr mode (no data)"])
nominal_register_values.append([253, "CatchSpy", 1, "WR_ADDR addr mode (no data)"])

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

def write_nominal_register_values():
	bank = 7
	for i in range(len(nominal_register_values)):
		address = nominal_register_values[i][0]
		value = nominal_register_values[i][2]
		print(str(address) + " " + nominal_register_values[i][1] + " " + str(value))
		althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value])
		time.sleep(0.01)

def write_some_nominal_register_values(string):
	bank = 7
	for i in range(len(nominal_register_values)):
		match = re.search(string, nominal_register_values[i][1])
		if match:
			address = nominal_register_values[i][0]
			value = nominal_register_values[i][2]
			print(str(address) + " " + nominal_register_values[i][1] + " " + str(value))
			althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value])
			time.sleep(0.1)

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

def print_scalers():
	string = ""
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

def run_threshold_scan():
	# 400mV sine wave gives a threshold scan from 0x200 to 0xaf0
	start_value = 0x1c0
	step_size = 1
	end_value = 0x230
	bank = 7
	for value in range(start_value, end_value+1, step_size):
		print(hex(value, 3), end="  ")
		for channel in range(NUMBER_OF_CHANNELS_PER_ASIC):
			address = 128 + 4 * channel
			#print(str(address) + " " + str(value))
			althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + address, [value], False)
		time.sleep(0.01)
		readout_counters_and_scalers()
		print_scalers()

def initiate_legacy_serial_sequence():
	set_ls_i2c_mode(1) # ls_i2c: 0=i2c; 1=LS
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 1, [1], False)
	print("legacy serial transfer")

def initiate_i2c_transfer():
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 2, [1], False)
	print("i2c transfer")

software_trigger_number = 0
def initiate_trigger():
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 3, [1], False)
	global software_trigger_number
	software_trigger_number += 1
	print("trigger " + str(software_trigger_number))

def get_fifo_empty():
	bank = 1
	fifo_empty, = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 2, 1, False)
	return fifo_empty

def gulp(word):
	global buffer_new, buffer_old, waveform_data, ALFA_OMGA_counter, have_just_gathered_waveform_data
	if ALFA==word:
		if not buffer_new[0]==ALFA:
			print("first word of previous buffer: " + hex(buffer_new[0], 4))
		if not buffer_new[-1]==OMGA:
			print("last word of previous buffer: " + hex(buffer_new[-1], 4))
		buffer_new = []
		ALFA_OMGA_counter = 0
	buffer_new.append(word)
	ALFA_OMGA_counter += 1
	if OMGA==word:
		buffer_old = buffer_new
		#print("len(buffer_old): " + str(len(buffer_old)))
		if len(buffer_old)<7:
			return
		number_of_samples_per_waveform_from_header = (buffer_old[6]>>8) & 0xff
		if 0==number_of_samples_per_waveform_from_header:
			number_of_samples_per_waveform_from_header = 256
		number_of_samples_per_waveform = (ALFA_OMGA_counter-NUMBER_OF_EXTRA_WORDS_PER_ALFA_OMGA_READOUT)/NUMBER_OF_CHANNELS_PER_ASIC
		if not number_of_samples_per_waveform==number_of_samples_per_waveform_from_header:
			print("number_of_samples_per_waveform (from packet length): " + str(number_of_samples_per_waveform))
			print("number_of_samples_per_waveform (from header): " + str(number_of_samples_per_waveform_from_header))
			#print("corrupt packet")
			return
		parse_packet()

def parse_packet():
	global sampling_bank, ASICID, fine_time, coarse_time, asic_trigger_number, samples_after_trigger, lookback_samples, samples_to_read, starting_sample, missed_triggers, asic_status
	#header_description_bytes = [ "AL", "FA", "ASICID", "finetime", "coarse4", "coarse3", "coarse2", "coarse1", "trigger2", "trigger1", "aftertrigger", "lookback", "samplestoread", "startingsample", "missedtriggers", "status" ]
	#header_description_words = [ "ALFA", "IdFi", "cs43", "cs21", "tg21", "AfLo", "ReSt", "MiSt" ]
	#header_decode_descriptions
	sampling_bank = 0
	if (buffer_old[1]>>8)&1:
		sampling_bank = 1
	ASICID =                (buffer_old[1]>>8) & 0xfe
	fine_time =              buffer_old[1]     & 0xff
	coarse_time =           (buffer_old[2]<<16)     | buffer_old[3]
	asic_trigger_number =    buffer_old[4]
	samples_after_trigger = (buffer_old[5]>>8) & 0xff
	lookback_samples =       buffer_old[5]     & 0xff
	samples_to_read =       (buffer_old[6]>>8) & 0xff
	starting_sample =        buffer_old[6]     & 0xff
	missed_triggers =       (buffer_old[7]>>8) & 0xff
	asic_status =            buffer_old[7]     & 0xff
	print("sampling_bank: " + str(sampling_bank))
	print("ASICID: " + str(ASICID))
	print("fine_time: " + str(fine_time))
	print("coarse_time: " + str(coarse_time))
	print("asic_trigger_number: " + str(asic_trigger_number))
	print("samples_after_trigger: 0x" + hex(samples_after_trigger, 2))
	print("lookback_samples: 0x" + hex(lookback_samples, 2))
	if 0==samples_to_read:
		samples_to_read = 0x100
	print("samples_to_read: 0x" + hex(samples_to_read, 3))
	print("starting_sample: " + str(starting_sample))
	print("missed_triggers: " + str(missed_triggers))
	print("asic_status: " + str(asic_status))
	index = NUMBER_OF_WORDS_PER_HEADER
#	index = 0
#	datafile.write(hex(buffer_old[index], 4)); index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
	for n in range(MAX_SAMPLES_PER_WAVEFORM):
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			waveform_data[0][sampling_bank][k][n] = 0
			waveform_data[1][sampling_bank][k][n] = 0
			waveform_data[2][sampling_bank][k][n] = 0
	for n in range(starting_sample, MAX_SAMPLES_PER_WAVEFORM):
		#print("n:" + str(n) + " index:" + str(index) + " starting_sample: " + str(starting_sample))
		if len(buffer_old)-NUMBER_OF_CHANNELS_PER_ASIC-NUMBER_OF_WORDS_PER_FOOTER<index:
			break
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			waveform_data[0][sampling_bank][k][n] = buffer_old[index] & 0xfff
			waveform_data[1][sampling_bank][k][n] = buffer_old[index] & 0xfff
			waveform_data[2][sampling_bank][k][n] = buffer_old[index] & 0xfff
#			datafile.write(hex(buffer_old[index], 4))
			index += 1
	for n in range(starting_sample):
		if len(buffer_old)-NUMBER_OF_CHANNELS_PER_ASIC-NUMBER_OF_WORDS_PER_FOOTER<index:
			break
		for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
			waveform_data[0][sampling_bank][k][n] = buffer_old[index] & 0xfff
			waveform_data[1][sampling_bank][k][n] = buffer_old[index] & 0xfff
			waveform_data[2][sampling_bank][k][n] = buffer_old[index] & 0xfff
#			datafile.write(hex(buffer_old[index], 4))
			index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
#	datafile.write(hex(buffer_old[index], 4)); index += 1
	#print(str(waveform_data[0][0][0]))
	string = ""
	for word in buffer_old:
		string += hex(word, 4)
	datafile.write(string)
	datafile.write("\n")
	datafile.flush()
	print("wrote " + str(len(buffer_old)) + " words to file " + datafile_name)
	have_just_gathered_waveform_data[1][sampling_bank] = True
	if pedestals_have_been_taken:
		have_just_gathered_waveform_data[2][sampling_bank] = True

def readout_some_data_from_the_fifo(number_of_words):
	bank = 5
	count = 0
	for i in range(number_of_words):
		fifo_empty = get_fifo_empty()
		if fifo_empty:
			break
		fifo_data, = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, 1, False)
		gulp(fifo_data)
		count += 1
	return count

def drain_fifo():
	count = 1
	while count:
		count = readout_some_data_from_the_fifo(number_of_words_to_read_from_the_fifo)

def gather_pedestals(i):
	#previous_number_of_samples = change_number_of_samples(256)
	#initiate_legacy_serial_sequence()
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
			have_just_gathered_waveform_data[i][j] = False
		initiate_trigger()
		readout_some_data_from_the_fifo(number_of_words_to_read_from_the_fifo)
		for j in range(ROWS):
			if have_just_gathered_waveform_data[i][j]:
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
	#change_number_of_samples(previous_number_of_samples)
	#initiate_legacy_serial_sequence()

if __name__ == "__main__":
	datafile = open(datafile_name, "a")
	ROWS = 2
	COLUMNS = 3
	wasted_width = int(GAP_X_LEFT + GAP_X_RIGHT + (COLUMNS-1)*GAP_X_BETWEEN_PLOTS)
	desired_window_width = int(COLUMNS * box_dimension_x_in * scale_pixels_per_in + wasted_width)
	SCREEN_WIDTH = desired_window_width
	SCREEN_HEIGHT = 892
	plots_were_updated = [ [ False for j in range(ROWS) ] for i in range(COLUMNS) ]
	#plot_name = [ [ "alpha" for j in range(ROWS) ] for i in range(COLUMNS) ]
	plot_name = [ ["pedestals(bankA)","pedestals(bankB)"], ["RAW(bankA)","RAW(bankB)"], ["pedestal subtracted(bankA)","pedestal subtracted(bankB)"] ]
	data_and_pedestal_coefficients = [ [0,1], [1,0], [1,-1] ]
	short_feed_name = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
	minimum = [ [ 0 for j in range(ROWS) ] for i in range(COLUMNS) ]
	maximum = [ [ 100 for j in range(ROWS) ] for i in range(COLUMNS) ]
	waveform_data = [ [ [ [ 0 for n in range(MAX_SAMPLES_PER_WAVEFORM) ] for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ] for j in range(ROWS) ] for i in range(COLUMNS) ]
	pedestal_data = [ [ [ [ 0 for n in range(MAX_SAMPLES_PER_WAVEFORM) ] for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ] for j in range(ROWS) ] for i in range(COLUMNS) ]
	have_just_gathered_waveform_data = [ [ False for j in range(ROWS) ] for i in range(COLUMNS) ]
	average_pedestal = [ [ 2047.0 for k in range(NUMBER_OF_CHANNELS_PER_ASIC) ] for j in range(ROWS) ]
	setup()
	#write_to_pollable_memory_value()
	running = True
	while running:
		loop()
		sys.stdout.flush()
	pygame.quit()

