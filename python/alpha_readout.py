#!/usr/bin/env python3

# written 2023-08-23 by mza
# based on protodune_LBLS_readout.py
# with help from https://realpython.com/pygame-a-primer/#displays-and-surfaces
# last updated 2024-04-11 by mza

bank0_register_names = [ "ls_i2c" ]

NUMBER_OF_CHANNELS_PER_BANK = 16
gui_update_period = 0.2 # in seconds

MAX_COUNTER = 650000 # actual counter is 24 bit, but we only see up to about this much for when diff_term=false
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

box_dimension_x_in = 3.0
box_dimension_y_in = 2.0
scale_pixels_per_in = 80

#channel_range = range(1, NUMBER_OF_CHANNELS_PER_BANK+1)

channel_names = [ "" ]
channel_names.extend(["ch" + str(i+1) for i in range(NUMBER_OF_CHANNELS_PER_BANK)])
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

color = [ black, white, red, green, blue, yellow, teal, pink, maroon, dark_green, light_blue, orange, purple, grey ]

selection = 0
coax_mux = [ 0 for i in range(4) ]

should_show_counters = True
should_show_scalers = True
should_show_bank0_registers = False
scaler_values_seen = set()

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
	global threshold_scan_horizontal_scale
	average_value_of_peak_scalers = 0
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		average_value_of_peak_scalers += voltage_at_peak_scaler[k]
	average_value_of_peak_scalers /= NUMBER_OF_CHANNELS_PER_BANK
	print("average_value_of_peak_scalers: " + str(average_value_of_peak_scalers))
	if (0):
		minimum_threshold_value_to_plot = average_value_of_peak_scalers - plot_width / 2 * DAC_EPSILON * threshold_scan_horizontal_scale
		maximum_threshold_value_to_plot = average_value_of_peak_scalers + plot_width / 2 * DAC_EPSILON * threshold_scan_horizontal_scale
	else:
		minimum_threshold_value_to_plot = 2.5
		maximum_threshold_value_to_plot = 0.0
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			if voltage_at_lower_null_scaler[k]<minimum_threshold_value_to_plot:
				minimum_threshold_value_to_plot = voltage_at_lower_null_scaler[k]
			if maximum_threshold_value_to_plot<voltage_at_upper_null_scaler[k]:
				maximum_threshold_value_to_plot = voltage_at_upper_null_scaler[k]
		threshold_scan_horizontal_scale = (maximum_threshold_value_to_plot-minimum_threshold_value_to_plot)/DAC_EPSILON/plot_width
	print("minimum_threshold_value_to_plot: " + str(minimum_threshold_value_to_plot))
	print("maximum_threshold_value_to_plot: " + str(maximum_threshold_value_to_plot))
	#print(str(volts_per_pixel_x))
	formatted_data = [ [ 0 for x in range(plot_width) ] for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	scale = 1 / MAX_COUNTER
	#print(str(scale))
	for n in range(len(threshold_scan[i][j])):
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			voltage = threshold_scan[i][j][n][k][0]
			scaler = threshold_scan[i][j][n][k][1]
			#print(str(voltage) + "," + str(scaler))
			if scaler>0:
				#if scaler>1000:
				#	print(str(voltage) + "," + str(scaler))
				x = int((voltage - minimum_threshold_value_to_plot)/(DAC_EPSILON*threshold_scan_horizontal_scale))
				if x<=0:
					continue
				elif plot_width<=x:
					continue
				formatted_data[k][x] = scaler * scale
				#if 0==n%40:
				#	print(str(threshold_scan[i][j][n][k]))
				#	print(str(voltage) + "," + str(scaler) + ":" + str(x) + ":" + str(formatted_data[k][x]))
	pygame.event.pump()
	print("plotting data...")
	# fill with colors for now:
	#plot[i][j].fill((random.randrange(0, 255), random.randrange(0, 255), random.randrange(0, 255)))
	print("[" + str(i) + "][" + str(j) + "]")
	for x in range(plot_width):
		pygame.event.pump()
		for y in range(plot_height):
			plot[i][j].set_at((x, y), black)
			for k in range(NUMBER_OF_CHANNELS_PER_BANK):
				yn = int(plot_height - plot_height * formatted_data[k][x])
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
	print("screen_width: " + str(SCREEN_WIDTH))
	usable_width = int(SCREEN_WIDTH - GAP_X_LEFT - GAP_X_RIGHT - (COLUMNS-1)*GAP_X_BETWEEN_PLOTS)
	print("usable_width: " + str(usable_width))
	usable_height = int(SCREEN_HEIGHT - GAP_Y_TOP - GAP_Y_BOTTOM - (ROWS-1)*GAP_Y_BETWEEN_PLOTS)
	print("usable_height: " + str(usable_height))
	plot_width = int(usable_width / COLUMNS)
	plot_height = int(usable_height / ROWS / 4)
	#print("plot_width: " + str(plot_width))
	print("plot_height: " + str(plot_height))
	global Y_POSITION_OF_CHANNEL_NAMES
	global Y_POSITION_OF_COUNTERS
	global Y_POSITION_OF_SCALERS
	#global Y_POSITION_OF_TOT
	global Y_POSITION_OF_BANK0_REGISTERS
	gap = 20
	Y_POSITION_OF_CHANNEL_NAMES = plot_height + gap
	Y_POSITION_OF_COUNTERS = plot_height + gap + FONT_SIZE_BANKS
	Y_POSITION_OF_SCALERS = plot_height + gap + FONT_SIZE_BANKS
	#Y_POSITION_OF_TOT = plot_height + gap + FONT_SIZE_BANKS
	Y_POSITION_OF_BANK0_REGISTERS = plot_height + gap + 200
	setup_pygame_sdl()
	#pygame.mixer.quit()
	global game_clock
	game_clock = pygame.time.Clock()
#	if not should_use_touchscreen:
#		pygame.mouse.set_cursor((8,8),(0,0),(0,0,0,0,0,0,0,0),(0,0,0,0,0,0,0,0))
	pygame.display.set_caption("alpha readout")
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
#	for i in range(len(bank0_register_names)):
#		register_name = banks_font.render(bank0_register_names[i], 1, white)
#		screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK0_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK0_REGISTERS+FONT_SIZE_BANKS*i)))
	#for i in range(NUMBER_OF_CHANNELS_PER_BANK):
	for i in range(len(channel_names)):
		register_name = banks_font.render(channel_names[i], 1, white)
		screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_CHANNEL_NAMES+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_CHANNEL_NAMES+FONT_SIZE_BANKS*i)))
	#for i in range(NUMBER_OF_CHANNELS_PER_BANK):
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

def loop():
	#pygame.time.wait(10)
	game_clock.tick(100)
	global running
	global something_was_updated
	something_was_updated = True
	#pressed_keys = pygame.key.get_pressed()
	#pygame.event.wait()
	mouse = pygame.mouse.get_pos()
	from pygame.locals import K_UP, K_DOWN, K_LEFT, K_RIGHT, K_ESCAPE, KEYDOWN, QUIT, K_BREAK, K_SPACE, K_F1, K_F2, K_F3, K_F4, K_F5, K_F6, K_F7, K_F8, K_c, K_d, K_s, K_z, K_q, K_0, K_1, K_2, K_3, K_RIGHTBRACKET, K_LEFTBRACKET
	for event in pygame.event.get():
		if event.type == KEYDOWN:
			if K_ESCAPE==event.key or K_q==event.key:
				running = False
			elif K_d==event.key:
				global should_show_counters
				should_show_counters = not should_show_counters
			elif K_s==event.key:
				global should_show_scalers
				should_show_scalers = not should_show_scalers
		elif event.type == QUIT:
			running = False
		elif event.type == should_check_for_new_data:
			update_bank0_registers()
#			update_bank1_bank2_scalers()
#			update_counters()
#	global have_just_run_threshold_scan
#	for i in range(COLUMNS):
#		for j in range(ROWS):
#			if have_just_run_threshold_scan[i]:
#				have_just_run_threshold_scan[i] = False
#				update_plot(i, j)
	for i in range(COLUMNS):
		for j in range(ROWS):
			blit(i, j)
#	draw_photodiode_box(i, j)
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
	#print(hex(bank0_register_values[11]))
	global coax_mux
	coax_mux = bank0_register_values[7:7+4]

bank0_register_object = [ 0 for i in range(len(bank0_register_names)) ]

def update_bank0_registers():
	global bank0_register_object
	read_bank0_registers()
	if should_show_bank0_registers:
		for i in range(len(bank0_register_names)):
			try:
				temp_surface = pygame.Surface(bank0_register_object[i].get_size())
				temp_surface.fill(green)
				screen.blit(temp_surface, bank0_register_object[i].get_rect(center=(X_POSITION_OF_BANK0_REGISTERS-bank0_register_object[i].get_width()//2,Y_POSITION_OF_BANK0_REGISTERS+FONT_SIZE_BANKS*i)))
			except Exception as e:
				#print(str(e))
				pass
			bank0_register_object[i] = banks_font.render(hex(bank0_register_values[i], 8, True), False, white)
			screen.blit(bank0_register_object[i], bank0_register_object[i].get_rect(center=(X_POSITION_OF_BANK0_REGISTERS-bank0_register_object[i].get_width()//2,Y_POSITION_OF_BANK0_REGISTERS+FONT_SIZE_BANKS*i)))

#def read_status_register():
#	bank = 1
#	global status_register
#	status_register, = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, 1, False)
#	return status_register

#def show_status_register():
#	read_status_register()
#	print("status register: " + str(hex(status_register, 8)))

#def show_other_registers():
#	bank = 1
#	trigger_count, suggested_inversion_map, hit_counter_buffered = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 13, 3, False)
#	print("trigger_count: " + str(trigger_count))
#	print("suggested_inversion_map: " + hex(suggested_inversion_map, 3))
#	print("hit_counter_buffered: " + str(hit_counter_buffered))

def clear_something_on_bank0_reg5(bit_number):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [1<<bit_number], False)
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [0], False)

def readout_raw_values():
	bank = 1
	return althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, NUMBER_OF_CHANNELS_PER_BANK, False)

def return_raw_values_string():
	values = readout_raw_values()
	string = ""
	for i in range(NUMBER_OF_CHANNELS_PER_BANK):
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
	ToT_reversed = [ 0 for i in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	for i in range(3):
		for j in range(4):
			k = i*4+j
			ToT_reversed[k] = (fifo[i] >> (8*(3-j)) ) & 0xff
#	string = ""
#	for i in range(3):
#		string += hex(fifo[i], 8, False) + " "
#	print(string)
	global ToT
	ToT = [ ToT_reversed[11-i] for i in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	return ToT

def show_fifo_split():
	readout_fifo_split()
	string = ""
	for i in range(NUMBER_OF_CHANNELS_PER_BANK):
		string += hex(ToT[i], 2, True) + " "
	print(string)

#def return_fifo_string():
#	fifo_cba9, fifo_8765, fifo_4321 = readout_fifo_single()
#	return str(hex(fifo_cba9, 8)) + " " + str(hex(fifo_8765, 8)) + " " + str(hex(fifo_4321, 8))

#def show_fifo():
#	print(return_fifo_string())

def readout_counters(i, j):
	global bank_counters
	bank_counters = [ [ 0 for k in range(NUMBER_OF_CHANNELS_PER_BANK) ] for i in range(number_of_pin_diode_boxes) ]
	if 0==i and 0==j:
		bank = 4
		bank_counters[i] = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, NUMBER_OF_CHANNELS_PER_BANK, False)
	if 1==i and 0==j:
		bank = 5
		bank_counters[i] = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, NUMBER_OF_CHANNELS_PER_BANK, False)
	if 2==i and 0==j:
		bank = 6
		bank_counters[i] = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, NUMBER_OF_CHANNELS_PER_BANK, False)
	if 3==i and 0==j:
		bank = 7
		bank_counters[i] = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, NUMBER_OF_CHANNELS_PER_BANK, False)
	return bank_counters[i]

def return_counters_string(i, j):
	string = ""
	for counter in readout_counters(i, j):
		string += str(hex(counter, display_precision_of_hex_counter_counts, True)) + " "
	return string

def update_counters():
	global counter_object
	try:
		counter_object[0][0].get_size()
	except:
		counter_object = [ [ 0 for k in range(NUMBER_OF_CHANNELS_PER_BANK) ] for i in range(number_of_pin_diode_boxes) ]
	if should_show_counters:
		for i in range(number_of_pin_diode_boxes):
			readout_counters(i, 0)
			for k in range(NUMBER_OF_CHANNELS_PER_BANK):
				try:
					temp_surface = pygame.Surface(counter_object[i][k].get_size())
					temp_surface.fill(red)
					screen.blit(temp_surface, counter_object[i][k].get_rect(center=(X_POSITION_OF_COUNTERS+i*(plot_width+GAP_X_BETWEEN_PLOTS)-counter_object[i][k].get_width()//2,Y_POSITION_OF_COUNTERS+FONT_SIZE_BANKS*k)))
				except Exception as e:
					#print(str(e))
					pass
				counter_object[i][k] = banks_font.render(hex(bank_counters[i][k], display_precision_of_hex_counter_counts, True), False, white)
				screen.blit(counter_object[i][k], counter_object[i][k].get_rect(center=(X_POSITION_OF_COUNTERS+i*(plot_width+GAP_X_BETWEEN_PLOTS)-counter_object[i][k].get_width()//2,Y_POSITION_OF_COUNTERS+FONT_SIZE_BANKS*k)))

def readout_scalers(i, j):
	global bank_scalers
	bank_scalers = [ [ 0 for k in range(NUMBER_OF_CHANNELS_PER_BANK) ] for i in range(number_of_pin_diode_boxes) ]
	bank = 1
	bank1_scalers = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, NUMBER_OF_CHANNELS_PER_BANK, False)
	bank = 2
	bank2_scalers = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, NUMBER_OF_CHANNELS_PER_BANK, False)
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		bank_scalers[0][k] =  bank1_scalers[k]      & 0xffff
		bank_scalers[1][k] = (bank1_scalers[k]>>16) & 0xffff
		bank_scalers[2][k] =  bank2_scalers[k]      & 0xffff
		bank_scalers[3][k] = (bank2_scalers[k]>>16) & 0xffff
	return bank_scalers[i]

def return_scalers_string(i, j):
	string = ""
	for scaler in readout_scalers(i, j):
		string += str(hex(scaler, display_precision_of_hex_scaler_counts, True)) + " "
	return string

def show_scalers(i, j):
	print(return_scalers_string(i, j))

def update_bank1_bank2_scalers():
	global bank_scalers_object
	try:
		bank_scalers_object[0][0].get_size()
	except:
		bank_scalers_object = [ [ 0 for k in range(NUMBER_OF_CHANNELS_PER_BANK) ] for i in range(number_of_pin_diode_boxes) ]
	readout_scalers(0, 0) # still reads out all scalers
	if should_show_scalers:
		for i in range(number_of_pin_diode_boxes):
			for k in range(NUMBER_OF_CHANNELS_PER_BANK):
				try:
					temp_surface = pygame.Surface(bank_scalers_object[i][k].get_size())
					temp_surface.fill(purple)
					screen.blit(temp_surface, bank_scalers_object[i][k].get_rect(center=(X_POSITION_OF_SCALERS+i*(plot_width+GAP_X_BETWEEN_PLOTS)-bank_scalers_object[i][k].get_width()//2,Y_POSITION_OF_SCALERS+FONT_SIZE_BANKS*k)))
				except Exception as e:
					#print(str(e))
					pass
				bank_scalers_object[i][k] = banks_font.render(hex(bank_scalers[i][k], display_precision_of_hex_scaler_counts, True), False, white)
				screen.blit(bank_scalers_object[i][k], bank_scalers_object[i][k].get_rect(center=(X_POSITION_OF_SCALERS+i*(plot_width+GAP_X_BETWEEN_PLOTS)-bank_scalers_object[i][k].get_width()//2,Y_POSITION_OF_SCALERS+FONT_SIZE_BANKS*k)))

def setup_everything():
	if 1:
		bank = 0
		print("bank" + str(bank) + ":")
		values = [ 0 for a in range(2**4) ]
		values[0] = 0b1 # ls_i2c: 0=i2c; 1=LS
		althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH, values)
		time.sleep(1)
		readback = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, 2**4)
		for i in range(16):
			print(hex(readback[i], 8))

if __name__ == "__main__":
	ROWS = 1
	COLUMNS = 1
	wasted_width = int(GAP_X_LEFT + GAP_X_RIGHT + (COLUMNS-1)*GAP_X_BETWEEN_PLOTS)
	desired_window_width = int(COLUMNS * box_dimension_x_in * scale_pixels_per_in + wasted_width)
	SCREEN_WIDTH = desired_window_width
	SCREEN_HEIGHT = 360
	plots_were_updated = [ [ False for j in range(ROWS) ] for i in range(COLUMNS) ]
	plot_name = [ [ "bank" + chr(i+ord('A')) for j in range(ROWS) ] for i in range(COLUMNS) ]
	short_feed_name = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
	minimum = [ [ 0 for j in range(ROWS) ] for i in range(COLUMNS) ]
	maximum = [ [ 100 for j in range(ROWS) ] for i in range(COLUMNS) ]
	setup()
	#write_to_pollable_memory_value()
	running = True
	while running:
		loop()
		sys.stdout.flush()
	pygame.quit()

