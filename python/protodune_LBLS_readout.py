#!/usr/bin/env python3

# written 2023-08-23 by mza
# based on https://github.com/mzandrew/bin/blob/master/embedded/mondrian.py
# with help from https://realpython.com/pygame-a-primer/#displays-and-surfaces
# last updated 2024-02-13 by mza

gui_update_period = 0.2

raw_threshold_scan_filename = "protodune.ampoliros12.raw_threshold_scan"
thresholds_for_peak_scalers_filename = "protodune.ampoliros12.thresholds_for_peak_scalers"
threshold_scan_accumulation_time = 0.1
threshold_voltage_distance_from_peak_to_null = 0.004200
threshold_step_size_in_volts = 2.5/2**16
max_number_of_threshold_steps = 1000
incidentals = 2
display_precision_of_hex_counts = 8
display_precision_of_DAC_voltages = 6
bump_amount = 0.000250
DEFAULT_GUESS_FOR_VOLTAGE_AT_PEAK_SCALER = 1.19

# typical threshold scan has peak scalers at these voltages:
# 1.215078 1.214924 1.217697 1.211535 1.212697 1.213695 1.216734 1.218696 1.214115 1.212620 1.218383 1.215811

# set to desired scaler rate results in these voltages (ampoliros revB first article):
# 1.205999 1.204813 1.199918 1.200357 1.207928 1.203623 1.199567 1.200689 1.200037 1.205867 1.203237 1.203374 

SCREEN_WIDTH = 720
SCREEN_HEIGHT = 720
ROWS = 1
COLUMNS = 1
NUMBER_OF_PHOTODIODES = 12

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
X_POSITION_OF_BANK1_REGISTERS = 100
Y_POSITION_OF_BANK1_REGISTERS = 250
X_POSITION_OF_BANK2_REGISTERS = 100
Y_POSITION_OF_BANK2_REGISTERS = 500
X_POSITION_OF_BANK6_COUNTERS = 250
Y_POSITION_OF_BANK6_COUNTERS = 250 + FONT_SIZE_BANKS
X_POSITION_OF_BANK7_SCALERS = 350
Y_POSITION_OF_BANK7_SCALERS = 250 + FONT_SIZE_BANKS
X_POSITION_OF_TOT = 450
Y_POSITION_OF_TOT = 250 + FONT_SIZE_BANKS
X_POSITION_OF_BANK0_COUNTERS = 550
Y_POSITION_OF_BANK0_COUNTERS = 250 + FONT_SIZE_BANKS

plot_name = [ [ "" for j in range(ROWS) ] for i in range(COLUMNS) ]
feed_name = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
short_feed_name = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
minimum = [ [ 0 for j in range(ROWS) ] for i in range(COLUMNS) ]
maximum = [ [ 100 for j in range(ROWS) ] for i in range(COLUMNS) ]

channel_names = ["ch_" + str(i) for i in range(1, 12+1)]
bank1_register_names = [ "status" ]
bank1_register_names.extend(channel_names)
bank1_register_names.extend([ "trigger_count", "suggested_inversion_map", "hit_counter" ])
#print(str(bank1_register_names))
bank1_register_values = [ i for i in range(len(bank1_register_names)) ]

bank2_register_names = [ "hit_mask", "inversion_mask", "desired_trigger_quantity", "trigger_duration_in_word_clocks", "monitor_channel", "reg5", "reg6", "coax_mux[0]", "coax_mux[1]", "coax_mux[2]", "coax_mux[3]" ]

# geometry of protodune LBLS PIN photodiode array:
#a_in = 0.5 # lattice spacing, in in
photodiode_can_diameter_in = 0.325
photodiode_positions_x_in = [ -1.375 + 0.5 * i for i in range(6) ] + [ -1.125 + 0.5 * i for i in range(6) ]
photodiode_positions_y_in = [ 0.25 for i in range(6)] + [ -0.25 for i in range(6) ]
#for i in range(12):
#	print("PD" + str(i+1) + " " + str(photodiode_positions_x_in[i]) + "," + str(photodiode_positions_y_in[i]))
box_dimension_x_in = 5.0
box_dimension_y_in = 2.0
scale_pixels_per_in = 100

black = (0, 0, 0)
white = (255, 255, 255)
grey = (127, 127, 127)
red = (255, 0, 0)
green = (0, 255, 0)
blue = (75, 75, 255)
yellow = (255, 255, 0)
teal = (0, 255, 255)
pink = (255, 63, 63)
maroon = (255, 0, 127)
dark_green = (0, 127, 0)
light_blue = (200, 200, 255)
orange = (255, 127, 0)
purple = (255, 0, 255)
grid_color_bright = (63, 63, 63)
grid_color_faint = (15, 15, 15)

selection = 0
coax_mux = [ 0 for i in range(4) ]

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
#os.environ["SDL_FBDEV"] = "/dev/fb0"
if should_use_touchscreen:
	if os.path.exists("/dev/input/touchscreen"):
		os.environ["SDL_MOUSEDEV"] = "/dev/input/touchscreen"
	else:
		os.environ["SDL_MOUSEDEV"] = "/dev/input/event0"
		#os.environ["SDL_MOUSEDEV"] = "/dev/input/mouse0"
		os.environ["SDL_MOUSEDRV"] = "TSLIB"
import pygame # sudo apt install -y python3-pygame # gets 1.9.6 as of early 2023
# pip3 install pygame # gets 2.1.2 as of early 2023
# sudo apt install -y libmad0 libmikmod3 libportmidi0 libsdl-image1.2 libsdl-mixer1.2 libsdl-ttf2.0 libsdl1.2debian
from pygame.locals import K_UP, K_DOWN, K_LEFT, K_RIGHT, K_ESCAPE, KEYDOWN, QUIT, K_q, K_BREAK, K_SPACE, K_t, K_c, K_m, K_0, K_1, K_2, K_3, K_RIGHTBRACKET, K_LEFTBRACKET
from generic import * # hex, eng
import althea
BANK_ADDRESS_DEPTH = 13
import ltc2657

def update_plot(i, j):
	for k in range(len(feed_name[i][j])):
		if not FAKE_DATA:
			#print("fetching another datapoint for feed \"" + feed_name[i][j][k] + "\"...")
#			feed_data[i][j][k] = fetch.add_most_recent_data_to_end_of_array(feed_data[i][j][k], feed_name[i][j][k])
			feed_data[i][j][k] = [[[ 0 for k in range(plot_width) ] for j in range(ROWS) ] for i in range(COLUMNS) ]
			#print("length of data = " + str(len(feed_data[i][j][k])))
	global plots_were_updated
	pygame.event.pump()
	print("normalizing data...")
	for k in range(len(feed_name[i][j])):
		normalized_feed_data[i][j][k] = format_for_plot(feed_data[i][j][k], minimum[i][j], maximum[i][j])
	pygame.event.pump()
	print("plotting data...")
	# fill with colors for now:
	#plot[i][j].fill((random.randrange(0, 255), random.randrange(0, 255), random.randrange(0, 255)))
	print("[" + str(i) + "][" + str(j) + "]")
	for x in range(plot_width):
		pygame.event.pump()
		for y in range(plot_height):
			plot[i][j].set_at((x, y), black)
			for k in range(len(feed_name[i][j])):
				yn = int(plot_height - plot_height * normalized_feed_data[i][j][k][x])
				doit = False
				if y==yn:
					doit = True
				elif 0==y and yn<0:
					doit = True
				elif plot_height-1==y and plot_height<yn:
					doit = True
				if doit:
					plot[i][j].set_at((x, y), color[k+2]) # first two indices are black and white
	plots_were_updated[i][j] = True

active_square_size_in = 0.125
active_square_size = active_square_size_in * scale_pixels_per_in
def draw_photodiode_box(i, j):
	width = int(box_dimension_x_in * scale_pixels_per_in)
	height = int(box_dimension_y_in * scale_pixels_per_in)
	offset_x = 0 # GAP_X_LEFT+i*(width+GAP_X_BETWEEN_PLOTS)
	offset_y = 0 # GAP_Y_TOP+j*(height+GAP_Y_BETWEEN_PLOTS)
	radius = int(photodiode_can_diameter_in * scale_pixels_per_in / 2.0)
	box = pygame.draw.rect(flarb[i][j], grey, pygame.Rect(offset_x, offset_y, width, height), 0)
	for k in range(NUMBER_OF_PHOTODIODES):
		x = int(offset_x + width/2 + photodiode_positions_x_in[k] * scale_pixels_per_in)
		y = int(offset_y + height/2 - photodiode_positions_y_in[k] * scale_pixels_per_in)
		pygame.draw.circle(flarb[i][j], white, (x, y), radius, 0)
		pygame.draw.rect(flarb[i][j], black, pygame.Rect(x-active_square_size//2, y-active_square_size//2, active_square_size, active_square_size), 0)
	screen.blit(flarb[i][j], (GAP_X_LEFT+i*(width+GAP_X_BETWEEN_PLOTS), GAP_Y_TOP+j*(height+GAP_Y_BETWEEN_PLOTS)))

def draw_plot_border(i, j):
	#print("drawing plot border...")
	pygame.draw.rect(screen, white, pygame.Rect(GAP_X_LEFT+i*(plot_width+GAP_X_BETWEEN_PLOTS)-1, GAP_Y_TOP+j*(plot_height+GAP_Y_BETWEEN_PLOTS)-1, plot_width+2, plot_height+2), 1)

def setup():
	global plot_width
	global plot_height
	global screen
	global plot
	global something_was_updated
	something_was_updated = False
	usable_width = SCREEN_WIDTH - GAP_X_LEFT - GAP_X_RIGHT - (COLUMNS-1)*GAP_X_BETWEEN_PLOTS
	#print("usable_width: " + str(usable_width))
	usable_height = SCREEN_HEIGHT - GAP_Y_TOP - GAP_Y_BOTTOM - (ROWS-1)*GAP_Y_BETWEEN_PLOTS
	#print("usable_height: " + str(usable_height))
	plot_width = int(usable_width / COLUMNS)
	plot_height = int(usable_height / ROWS)
	#print("plot_width: " + str(plot_width))
	#print("plot_height: " + str(plot_height))
	pygame.display.init()
	pygame.font.init()
	#pygame.mixer.quit()
	global game_clock
	game_clock = pygame.time.Clock()
#	if not should_use_touchscreen:
#		pygame.mouse.set_cursor((8,8),(0,0),(0,0,0,0,0,0,0,0),(0,0,0,0,0,0,0,0))
	pygame.display.set_caption("protodune LBLS")
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
	for i in range(len(bank1_register_names)):
		register_name = banks_font.render(bank1_register_names[i], 1, white)
		screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK1_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))
	#for i in range(len(channel_names)):
	for i in range(len(bank2_register_names)):
		register_name = banks_font.render(bank2_register_names[i], 1, white)
		screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK2_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK2_REGISTERS+FONT_SIZE_BANKS*i)))
	#for i in range(len(channel_names)):
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
			draw_photodiode_box(i, j)
			flip()
			sys.stdout.flush()
	althea.setup_half_duplex_bus("test058")
	setup_trigger_mask_inversion_mask_trigger_quantity_and_duration()
	import board
	i2c = board.I2C()
	ltc2657.setup(i2c)
	set_threshold_voltages(1.15)
	global should_check_for_new_data
	should_check_for_new_data = pygame.USEREVENT + 1
	#print("gui_update_period: " + str(gui_update_period))
	pygame.time.set_timer(should_check_for_new_data, int(gui_update_period*1000/COLUMNS/ROWS))

ij = 0
def loop():
	#pygame.time.wait(10)
	game_clock.tick(100)
	global running
	global should_update_plots
	global ij
	global something_was_updated
	something_was_updated = True
	should_update_plots = [ [ False for j in range(ROWS) ] for i in range(COLUMNS) ]
	#pressed_keys = pygame.key.get_pressed()
	#pygame.event.wait()
	mouse = pygame.mouse.get_pos()
	for event in pygame.event.get():
		if event.type == KEYDOWN:
			if K_ESCAPE==event.key or K_q==event.key:
				running = False
			elif K_SPACE==event.key:
				should_update_plots = [ [ True for j in range(ROWS) ] for i in range(COLUMNS) ]
			elif K_t==event.key:
				#scan_for_tickles()
				#simple_threshold_scan()
				sophisticated_threshold_scan()
			elif K_c==event.key:
				clear_channel_counters()
				clear_channel_ones_counters()
				print("channel counters cleared")
			elif K_m==event.key:
				set_thresholds_for_this_scaler_rate_during_this_accumulation_time(10, 0.5)
			elif K_RIGHTBRACKET==event.key:
				bump_thresholds_higher_by(bump_amount)
			elif K_LEFTBRACKET==event.key:
				bump_thresholds_lower_by(bump_amount)
			elif K_0==event.key:
				increment_coax_mux(0)
			elif K_1==event.key:
				increment_coax_mux(1)
			elif K_2==event.key:
				increment_coax_mux(2)
			elif K_3==event.key:
				increment_coax_mux(3)
		elif event.type == QUIT:
			running = False
		elif event.type == should_check_for_new_data:
			if 0==ij:
				should_update_plots[0][0] = True
			elif 1==ij:
				should_update_plots[0][1] = True
			elif 2==ij:
				should_update_plots[1][0] = True
			elif 3==ij:
				should_update_plots[1][1] = True
			ij += 1
			if COLUMNS*ROWS-1<ij:
				ij = 0
			update_bank1_registers()
			update_bank2_registers()
			update_bank6_counters()
			update_bank7_scalers()
			update_ToT()
			update_bank0_counters()
		elif event.type == pygame.MOUSEBUTTONDOWN:
			do_something()
	for i in range(COLUMNS):
		for j in range(ROWS):
			if should_update_plots[i][j]:
				#print("updating...")
				should_update_plots[i][j] = False
#				update_plot(i, j)
				show_stuff()
#	for i in range(COLUMNS):
#		for j in range(ROWS):
#			blit(i, j)
	draw_photodiode_box(i, j)
	flip()

def blit(i, j):
	global something_was_updated
	if plots_were_updated[i][j]:
		#print("blitting...")
		screen.blit(plot[i][j], (GAP_X_LEFT+i*(plot_width+GAP_X_BETWEEN_PLOTS), GAP_Y_TOP+j*(plot_height+GAP_Y_BETWEEN_PLOTS)))
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

def read_bank0_counters():
	global bank0_register_values
	bank = 0
	bank0_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, 12, False)

bank0_register_object = [ 0 for i in range(len(channel_names)) ]

def update_bank0_counters():
	global bank0_register_object
	read_bank0_counters()
	for i in range(len(channel_names)):
		try:
			temp_surface = pygame.Surface(bank0_register_object[i].get_size())
			temp_surface.fill(black)
			screen.blit(temp_surface, bank0_register_object[i].get_rect(center=(X_POSITION_OF_BANK0_COUNTERS-bank0_register_object[i].get_width()//2,Y_POSITION_OF_BANK0_COUNTERS+FONT_SIZE_BANKS*i)))
		except Exception as e:
			#print(str(e))
			pass
		bank0_register_object[i] = banks_font.render(hex(bank0_register_values[i], display_precision_of_hex_counts, True), False, white)
		screen.blit(bank0_register_object[i], bank0_register_object[i].get_rect(center=(X_POSITION_OF_BANK0_COUNTERS-bank0_register_object[i].get_width()//2,Y_POSITION_OF_BANK0_COUNTERS+FONT_SIZE_BANKS*i)))

def read_bank1_registers():
	global bank1_register_values
	bank = 1
	bank1_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, len(bank1_register_names), False)

bank1_register_object = [ 0 for i in range(len(bank1_register_names)) ]

def update_bank1_registers():
	global bank1_register_object
	read_bank1_registers()
	for i in range(len(bank1_register_names)):
		try:
			temp_surface = pygame.Surface(bank1_register_object[i].get_size())
			temp_surface.fill(black)
			screen.blit(temp_surface, bank1_register_object[i].get_rect(center=(X_POSITION_OF_BANK1_REGISTERS-bank1_register_object[i].get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))
		except Exception as e:
			#print(str(e))
			pass
		bank1_register_object[i] = banks_font.render(hex(bank1_register_values[i], 8, True), False, white)
		screen.blit(bank1_register_object[i], bank1_register_object[i].get_rect(center=(X_POSITION_OF_BANK1_REGISTERS-bank1_register_object[i].get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))

def read_bank2_registers():
	global bank2_register_values
	bank = 2
	bank2_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 0, len(bank2_register_names), False)
	global coax_mux
	coax_mux = bank2_register_values[7:7+4]

bank2_register_object = [ 0 for i in range(len(bank2_register_names)) ]

def update_bank2_registers():
	global bank2_register_object
	read_bank2_registers()
	for i in range(len(bank2_register_names)):
		try:
			temp_surface = pygame.Surface(bank2_register_object[i].get_size())
			temp_surface.fill(black)
			screen.blit(temp_surface, bank2_register_object[i].get_rect(center=(X_POSITION_OF_BANK2_REGISTERS-bank2_register_object[i].get_width()//2,Y_POSITION_OF_BANK2_REGISTERS+FONT_SIZE_BANKS*i)))
		except Exception as e:
			#print(str(e))
			pass
		bank2_register_object[i] = banks_font.render(hex(bank2_register_values[i], 8, True), False, white)
		screen.blit(bank2_register_object[i], bank2_register_object[i].get_rect(center=(X_POSITION_OF_BANK2_REGISTERS-bank2_register_object[i].get_width()//2,Y_POSITION_OF_BANK2_REGISTERS+FONT_SIZE_BANKS*i)))

def read_status_register():
	bank = 1
	global status_register
	status_register, = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, 1, False)
	return status_register

def show_status_register():
	read_status_register()
	print("status register: " + str(hex(status_register, 8)))

def show_other_registers():
	bank = 1
	trigger_count, suggested_inversion_map, hit_counter_buffered = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 13, 3, False)
	print("trigger_count: " + str(trigger_count))
	print("suggested_inversion_map: " + hex(suggested_inversion_map, 3))
	print("hit_counter_buffered: " + str(hit_counter_buffered))

def setup_hit_mask(hit_mask):
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, [hit_mask], False)

def setup_inversion_mask(inversion_mask):
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 1, [inversion_mask], False)

def setup_desired_trigger_quantity(quantity):
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 2, [quantity], False)

def setup_trigger_duration(number_of_word_clocks):
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 3, [number_of_word_clocks], False)

def change_coax_mux(channel, mux_value):
	bank = 2
	channel &= 0x3
	mux_value &= 0xf
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 7 + channel, [mux_value], False)

def increment_coax_mux(channel):
	channel &= 0x3
	global coax_mux
	coax_mux[channel] += 1
	if 0xf<coax_mux[channel]:
		coax_mux[channel] = 0
	change_coax_mux(channel, coax_mux[channel])

def clear_something_on_bank2_reg5(bit_number):
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [1<<bit_number], False)
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [0], False)

def clear_gate_counter():
	clear_something_on_bank2_reg5(0)

def clear_trigger_count():
	clear_something_on_bank2_reg5(1)

def clear_hit_counter():
	clear_something_on_bank2_reg5(2)

def clear_channel_counters():
	clear_something_on_bank2_reg5(3)

def clear_channel_ones_counters():
	clear_something_on_bank2_reg5(4)

def select(value):
	print("select: " + str(value))
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [value], False)

def get_trigger_count():
	bank = 1
	return althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 13, 1, False)

def show_trigger_count():
	trigger_count, = get_trigger_count()
	print("  trigger count: " + str(hex(trigger_count, display_precision_of_hex_counts)))

def readout_raw_values():
	bank = 1
	return althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, 12, False)

def return_raw_values_string():
	values = readout_raw_values()
	string = ""
	for i in range(12):
		string += str(hex(values[11 - i], 8)) + " "
	return string

def show_raw_values():
	print(return_raw_values_string())

def readout_fifo_multiple(depth):
	print("fifo" + ":")
	readback_4321 = althea.read_data_from_pollable_memory_on_half_duplex_bus(3 * 2**BANK_ADDRESS_DEPTH, depth, False)
	readback_8765 = althea.read_data_from_pollable_memory_on_half_duplex_bus(4 * 2**BANK_ADDRESS_DEPTH, depth, False)
	readback_cba9 = althea.read_data_from_pollable_memory_on_half_duplex_bus(5 * 2**BANK_ADDRESS_DEPTH, depth, False)
	for i in range(depth):
		print(hex(readback_cba9[i], 8) + " " + hex(readback_8765[i], 8) + " " + hex(readback_4321[i], 8))

def readout_fifo_single():
	readback_4321, = althea.read_data_from_pollable_memory_on_half_duplex_bus(3 * 2**BANK_ADDRESS_DEPTH, 1, False)
	readback_8765, = althea.read_data_from_pollable_memory_on_half_duplex_bus(4 * 2**BANK_ADDRESS_DEPTH, 1, False)
	readback_cba9, = althea.read_data_from_pollable_memory_on_half_duplex_bus(5 * 2**BANK_ADDRESS_DEPTH, 1, False)
	return (readback_cba9, readback_8765, readback_4321)

def readout_fifo_split():
	fifo = readout_fifo_single()
	ToT_reversed = [ 0 for i in range(12) ]
	for i in range(3):
		for j in range(4):
			k = i*4+j
			ToT_reversed[k] = (fifo[i] >> (8*(3-j)) ) & 0xff
#	string = ""
#	for i in range(3):
#		string += hex(fifo[i], 8, False) + " "
#	print(string)
	global ToT
	ToT = [ ToT_reversed[11-i] for i in range(12) ]
	return ToT

def show_fifo_split():
	readout_fifo_split()
	string = ""
	for i in range(12):
		string += hex(ToT[i], 2, True) + " "
	print(string)

ToT_object = [ 0 for i in range(len(channel_names)) ]

def update_ToT():
	readout_fifo_split()
	for i in range(len(channel_names)):
		try:
			temp_surface = pygame.Surface(ToT_object[i].get_size())
			temp_surface.fill(black)
			screen.blit(temp_surface, ToT_object[i].get_rect(center=(X_POSITION_OF_TOT-ToT_object[i].get_width()//2,Y_POSITION_OF_TOT+FONT_SIZE_BANKS*i)))
		except Exception as e:
			#print(str(e))
			pass
		ToT_object[i] = banks_font.render(hex(ToT[i], 2, True), False, white)
		screen.blit(ToT_object[i], ToT_object[i].get_rect(center=(X_POSITION_OF_TOT-ToT_object[i].get_width()//2,Y_POSITION_OF_TOT+FONT_SIZE_BANKS*i)))

def return_fifo_string():
	fifo_cba9, fifo_8765, fifo_4321 = readout_fifo_single()
	return str(hex(fifo_cba9, 8)) + " " + str(hex(fifo_8765, 8)) + " " + str(hex(fifo_4321, 8))

def show_fifo():
	print(return_fifo_string())

def readout_counters():
	bank = 6
	global bank6_counters
	bank6_counters = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, 12, False)
	return bank6_counters

def return_counters_string():
	string = ""
	for counter in readout_counters():
		string += str(hex(counter, display_precision_of_hex_counts, True)) + " "
	return string

bank6_counter_object = [ 0 for i in range(len(channel_names)) ]

def update_bank6_counters():
	readout_counters()
	for i in range(len(channel_names)):
		try:
			temp_surface = pygame.Surface(bank6_counter_object[i].get_size())
			temp_surface.fill(black)
			screen.blit(temp_surface, bank6_counter_object[i].get_rect(center=(X_POSITION_OF_BANK6_COUNTERS-bank6_counter_object[i].get_width()//2,Y_POSITION_OF_BANK6_COUNTERS+FONT_SIZE_BANKS*i)))
		except Exception as e:
			#print(str(e))
			pass
		bank6_counter_object[i] = banks_font.render(hex(bank6_counters[i], display_precision_of_hex_counts, True), False, white)
		screen.blit(bank6_counter_object[i], bank6_counter_object[i].get_rect(center=(X_POSITION_OF_BANK6_COUNTERS-bank6_counter_object[i].get_width()//2,Y_POSITION_OF_BANK6_COUNTERS+FONT_SIZE_BANKS*i)))

def readout_scalers():
	bank = 7
	global bank7_scalers
	bank7_scalers = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, 12, False)
	return bank7_scalers

def return_scalers_string():
	string = ""
	for scaler in readout_scalers():
		string += str(hex(scaler, display_precision_of_hex_counts, True)) + " "
	return string

def show_scalers():
	print(return_scalers_string())

bank7_scalers_object = [ 0 for i in range(len(channel_names)) ]

def update_bank7_scalers():
	readout_scalers()
	for i in range(len(channel_names)):
		try:
			temp_surface = pygame.Surface(bank7_scalers_object[i].get_size())
			temp_surface.fill(black)
			screen.blit(temp_surface, bank7_scalers_object[i].get_rect(center=(X_POSITION_OF_BANK7_SCALERS-bank7_scalers_object[i].get_width()//2,Y_POSITION_OF_BANK7_SCALERS+FONT_SIZE_BANKS*i)))
		except Exception as e:
			#print(str(e))
			pass
		bank7_scalers_object[i] = banks_font.render(hex(bank7_scalers[i], display_precision_of_hex_counts, True), False, white)
		screen.blit(bank7_scalers_object[i], bank7_scalers_object[i].get_rect(center=(X_POSITION_OF_BANK7_SCALERS-bank7_scalers_object[i].get_width()//2,Y_POSITION_OF_BANK7_SCALERS+FONT_SIZE_BANKS*i)))

def do_something():
	print("")
	#show_other_registers()
	#show_status_register()
	show_trigger_count()
	clear_trigger_count()
	show_fifo()
	return
	global selection
	selection += 1
	if 7<selection:
		selection = 0
	select(selection)

def scan_for_tickles():
	print("scanning hdrb for tickles...")
	bank = 0
	number_of_passes = 70
	tickles_incidentals = 5
	for i in range(18):
		token = 1<<i
		clear_channel_counters()
		for j in range(number_of_passes):
			althea.write_value_to_bank_that_is_depth(token, bank, BANK_ADDRESS_DEPTH)
		counters = readout_counters()
		string = ""
		for k in range(12):
			if counters[k]<number_of_passes*tickles_incidentals:
				string += "         "
			else:
				string += hex(counters[k], display_precision_of_hex_counts) + " "
		print("gpio" + dec(6+i, 2) + ": " + string)
#gpio06:                                                                                                    0005a47c 
#gpio07:                                                                                                    00050165 
#gpio08:                                                                                                    0001c27d 
#gpio09:                                                       00024884                                              
#gpio10:                                                                                                             
#gpio11:                                                                                                    000103d4 
#gpio12:                                                                                                             
#gpio13: 000054ef                                                                                           000191ec 
#gpio14:                                                                                                    00026a20 
#gpio15:                                                       0004746b                                              
#gpio16: 00037e85                                                                                           00035608 
#gpio17:                                                                                                    00054a86 
#gpio18:                                                       00037424                                              
#gpio19:                                                                                                    0003b973 
#gpio20:                                                                                                    0002f1b2 
#gpio21:                                                                                                             

def set_threshold_voltages(voltage):
	global current_threshold_voltage
	current_threshold_voltage = [ voltage for i in range(12) ]
	#print(str(voltage))
	ltc2657.set_voltage_on_all_channels(voltage)

def set_threshold_voltage(channel, voltage):
	global current_threshold_voltage
	current_threshold_voltage[channel] = voltage
	#print(str(channel) + " " + str(voltage), end=" ")
	address = 0x10 + 2 * (channel // 6) # first 6 channels are on i2c address 0x10; next 6 are at address 0x12
	channel %= 6
	#print(hex(address) + " " + str(channel))
	ltc2657.set_voltage_on_channel(address, channel, voltage)

def read_thresholds_for_peak_scalers_file():
	voltage_at_peak_scaler = [ DEFAULT_GUESS_FOR_VOLTAGE_AT_PEAK_SCALER for i in range(12) ]
	if not os.path.exists(thresholds_for_peak_scalers_filename):
		print("threshold file not found")
		return voltage_at_peak_scaler
	try:
		with open(thresholds_for_peak_scalers_filename, "r") as thresholds_for_peak_scalers_file:
			string = thresholds_for_peak_scalers_file.read(256)
			voltage_at_peak_scaler = string.split(" ")
			voltage_at_peak_scaler = [ i for i in voltage_at_peak_scaler if i!='' ]
			voltage_at_peak_scaler.remove('\n')
			voltage_at_peak_scaler = [ float(voltage_at_peak_scaler[k]) for k in range(12) ]
			for k in range(12):
				print(str(voltage_at_peak_scaler[k]), end=" ")
			print("")
	except:
		print("threshold file exists but is corrupted")
	return voltage_at_peak_scaler

def prepare_string_to_show_counters_or_scalers(values):
	string = ""
	for k in range(12):
		if values[k]<=incidentals:
			string += " %*s" % (display_precision_of_hex_counts, "")
		else:
			string += hex(values[k], display_precision_of_hex_counts, True) + " "
	return string

def prepare_string_with_voltages(voltage):
	string = ""
	for k in range(12):
		string += "%.*f " % (display_precision_of_DAC_voltages, voltage[k])
	return string

def simple_threshold_scan():
	print("running threshold scan...")
	threshold_minimum_voltage = 1.2100
	threshold_maximum_voltage = 1.2203
	number_of_threshold_steps = int(1+(threshold_maximum_voltage-threshold_minimum_voltage)/threshold_step_size_in_volts)
	print(str(number_of_threshold_steps))
	max_scaler_seen = [ 0 for i in range(12) ]
	voltage_at_peak_scaler = [ 0 for i in range(12) ]
	bank = 0
	voltage = threshold_minimum_voltage
	with open(raw_threshold_scan_filename, "w") as raw_threshold_scan_file:
		for i in range(number_of_threshold_steps):
			set_threshold_voltages(voltage)
			clear_channel_counters()
			time.sleep(threshold_scan_accumulation_time)
			counters = readout_counters()
			string = prepare_string_to_show_counters_or_scalers(counters)
			print("threshold voltage %.f: %s" % (voltage, string))
			raw_threshold_scan_file.write(string + "\n")
			for k in range(12):
				if max_scaler_seen[k]<counters[k]:
					max_scaler_seen[k] = counters[k]
					voltage_at_peak_scaler[k] = voltage
					#print(str(k) + " " + str(max_scaler_seen[k]) + " " + str(voltage_at_peak_scaler[k]))
			if 0==i%10:
				raw_threshold_scan_file.flush()
			voltage += threshold_step_size_in_volts
	with open(thresholds_for_peak_scalers_filename, "w") as thresholds_for_peak_scalers_file:
		string = prepare_string_with_voltages(voltage_at_peak_scaler)
		print(string)
		thresholds_for_peak_scalers_file.write(string + "\n")

def sophisticated_threshold_scan():
	print("running threshold scan...")
	max_scaler_seen = [ 0 for i in range(12) ]
	voltage_at_peak_scaler = [ 0 for i in range(12) ]
	bank = 0
	voltage_at_peak_scaler = read_thresholds_for_peak_scalers_file()
	voltage = [ voltage_at_peak_scaler[k] - threshold_voltage_distance_from_peak_to_null for k in range(12) ]
	with open(raw_threshold_scan_filename, "w") as raw_threshold_scan_file:
		for i in range(max_number_of_threshold_steps):
			#string = ""
			for k in range(12):
				set_threshold_voltage(k, voltage[k])
				#string += " %.*f " % (display_precision_of_DAC_voltages, voltage[k])
			#print(string)
			clear_channel_counters()
			time.sleep(threshold_scan_accumulation_time)
			counters = readout_counters()
			string = prepare_string_to_show_counters_or_scalers(counters)
			print(string)
			raw_threshold_scan_file.write(string + "\n")
			for k in range(12):
				if max_scaler_seen[k]<counters[k]:
					max_scaler_seen[k] = counters[k]
					voltage_at_peak_scaler[k] = voltage[k]
			if 0==i%10:
				raw_threshold_scan_file.flush()
			for k in range(12):
				voltage[k] += threshold_step_size_in_volts
	with open(thresholds_for_peak_scalers_filename, "w") as thresholds_for_peak_scalers_file:
		string = prepare_string_with_voltages(voltage_at_peak_scaler)
		print(string)
		thresholds_for_peak_scalers_file.write(string + "\n")

def set_thresholds_for_this_scaler_rate_during_this_accumulation_time(desired_rate, accumulation_time):
	span_up = 2
	span_down = 3
	voltage_at_peak_scaler = read_thresholds_for_peak_scalers_file()
	voltage = [ voltage_at_peak_scaler[k] - threshold_voltage_distance_from_peak_to_null/2 for k in range(12) ]
	stable = False
	while not stable:
		for k in range(12):
			set_threshold_voltage(k, voltage[k])
		clear_channel_counters()
		time.sleep(accumulation_time)
		counters = readout_counters()
		string = prepare_string_to_show_counters_or_scalers(counters)
		print(string)
		out_of_whack = 0
		for k in range(12):
			out_of_whack += int(math.fabs(desired_rate-counters[k]))
			if desired_rate<counters[k]+span_down:
				voltage[k] -= threshold_step_size_in_volts
			if counters[k]+span_up<desired_rate:
				voltage[k] += threshold_step_size_in_volts
		pygame.event.pump()
		#print(str(out_of_whack))
		if out_of_whack<12*span_up*span_down:
			stable = True
		time.sleep(0.1)

def bump_thresholds_lower_by(offset_voltage):
	voltage = [ current_threshold_voltage[k] - offset_voltage for k in range(12) ]
	string = prepare_string_with_voltages(voltage)
	print(string)
	for k in range(12):
		set_threshold_voltage(k, voltage[k])

def bump_thresholds_higher_by(offset_voltage):
	voltage = [ current_threshold_voltage[k] + offset_voltage for k in range(12) ]
	string = prepare_string_with_voltages(voltage)
	print(string)
	for k in range(12):
		set_threshold_voltage(k, voltage[k])

def show_stuff():
	#althea.write_ones_to_bank_that_is_depth(0, BANK_ADDRESS_DEPTH)
	#althea.write_value_to_bank_that_is_depth(0b0000010000000000, 0, BANK_ADDRESS_DEPTH) # gpio16 tickles signal[1, 12]
	#althea.write_value_to_bank_that_is_depth(0b0000001000000000, 0, BANK_ADDRESS_DEPTH) # gpio15 tickles signal[7, 11, 12]
	#althea.write_value_to_bank_that_is_depth(0b0001000000000000, 0, BANK_ADDRESS_DEPTH) # gpio18 tickles signal[7, 12]
	#scalers_string = return_counters_string()
	#scalers_string = return_scalers_string()
	#fifo_string = ""
	#fifo_string = return_fifo_string()
	#print(return_fifo_string() + "     " + return_raw_values_string())
	#print(return_fifo_string() + "     " + return_scalers_string())
	#print(fifo_string + "     " + scalers_string)
	#show_fifo()
	#show_raw_values()
	#readout_fifo_multiple(4)
	#show_fifo_split()
	pass

def setup_trigger_mask_inversion_mask_trigger_quantity_and_duration():
	setup_hit_mask(0b111111111111)
	#setup_hit_mask(0b000000000001)
	#setup_inversion_mask(0b000000000000)
	setup_inversion_mask(0b111111111111)
	setup_desired_trigger_quantity(int(1e3))
	setup_trigger_duration(25)
	select(0)

def setup_everything():
	if 1: # mza-test058.palimpsest.protodune-LBLS-DAQ.althea.revBLM
		bank = 2
		print("bank" + str(bank) + ":")
		values = [ 0 for a in range(2**4) ]
		values[0] = 0b111111111111 # hit_mask
		values[1] = 0b000000000000 # inversion_mask
		values[2] = int(1e6) # desired_trigger_quantity
		values[3] = 250 # trigger_duration_in_word_clocks
		values[4] = 1 # clear_trigger_count
		#values[0] = 0xff # minuend
		#values[4] = 0 # train_oserdes
		#values[5] = 0b10001010 # train_oserdes_pattern
		values[6] = 0 # start_sample (3 LSBs ignored)
		values[7] = 0 # end_sample (3 LSBs ignored)
		althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH, values)
		values[4] = 0 # clear_trigger_count
		althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH, values)
		time.sleep(1)
		readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, 2**4)
		for i in range(16):
			print(hex(readback[i], 8))
	if 1:
	#	for bank in range(4):
	#		print()
		bank = 1
		print("bank" + str(bank) + ":")
		readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, 2**4)
		for i in range(2**4):
	#	for i in range(8):
			print(hex(readback[i], 8))
	if 1:
		depth = 4
		print("fifo" + ":")
		readback_4321 = althea.read_data_from_pollable_memory_on_half_duplex_bus(3 * 2**BANK_ADDRESS_DEPTH, 2**depth)
		readback_8765 = althea.read_data_from_pollable_memory_on_half_duplex_bus(4 * 2**BANK_ADDRESS_DEPTH, 2**depth)
		readback_cba9 = althea.read_data_from_pollable_memory_on_half_duplex_bus(5 * 2**BANK_ADDRESS_DEPTH, 2**depth)
		for i in range(2**depth):
			print(hex(readback_cba9[i], 8) + " " + hex(readback_8765[i], 8) + " " + hex(readback_4321[i], 8))

running = True
should_update_plots = [ [ False for j in range(ROWS) ] for i in range(COLUMNS) ]
plots_were_updated = [ [ False for j in range(ROWS) ] for i in range(COLUMNS) ]
setup()
while running:
	loop()
	sys.stdout.flush()
pygame.quit()

