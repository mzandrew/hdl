#!/usr/bin/env python3

# written 2023-08-23 by mza
# based on https://github.com/mzandrew/bin/blob/master/embedded/mondrian.py
# with help from https://realpython.com/pygame-a-primer/#displays-and-surfaces
# last updated 2023-08-23 by mza

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

plot_name = [ [ "" for j in range(ROWS) ] for i in range(COLUMNS) ]
feed_name = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
short_feed_name = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
minimum = [ [ 0 for j in range(ROWS) ] for i in range(COLUMNS) ]
maximum = [ [ 100 for j in range(ROWS) ] for i in range(COLUMNS) ]

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

# when run as a systemd service, it gets sent a SIGHUP upon pygame.init(), hence this dummy signal handler
# see https://stackoverflow.com/questions/39198961/pygame-init-fails-when-run-with-systemd
import signal
def signal_handler(signum, frame):
	print("signal handler: got signal " + str(signum))
	sys.stdout.flush()
	if 15==signum:
		pygame.quit()
		sys.exit(signum)
# from https://stackoverflow.com/a/34568177/5728815
for mysignal in set(signal.Signals)-{signal.SIGKILL, signal.SIGSTOP}:
	signal.signal(mysignal, signal_handler)

import sys
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
from pygame.locals import K_UP, K_DOWN, K_LEFT, K_RIGHT, K_ESCAPE, KEYDOWN, QUIT, K_q, K_BREAK, K_SPACE
from generic import * # hex, eng
import althea
BANK_ADDRESS_DEPTH = 13

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
	plot_caption_font = pygame.font.SysFont("monospace", FONT_SIZE_PLOT_CAPTION )
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
	global should_check_for_new_data
	should_check_for_new_data = pygame.USEREVENT + 1
	global target_period
	target_period = 0.1
	#print("target_period: " + str(target_period))
	pygame.time.set_timer(should_check_for_new_data, int(target_period*1000/COLUMNS/ROWS))

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

def read_status_register():
	bank = 1
	global status_register
	status_register, = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, 1, False)
	return status_register

def show_status_register():
	read_status_register()
	print("status register: " + str(hex(status_register, 8)))

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

def clear_trigger_count():
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 4, [1], False)
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 4, [0], False)

def select(value):
	bank = 2
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [value], False)

def get_trigger_count():
	bank = 1
	return althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 13, 1, False)

def show_trigger_count():
	trigger_count, = get_trigger_count()
	print("  trigger count: " + str(hex(trigger_count, 8)))

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

def readout_fifo():
	readback_4321, = althea.read_data_from_pollable_memory_on_half_duplex_bus(3 * 2**BANK_ADDRESS_DEPTH, 1, False)
	readback_8765, = althea.read_data_from_pollable_memory_on_half_duplex_bus(4 * 2**BANK_ADDRESS_DEPTH, 1, False)
	readback_cba9, = althea.read_data_from_pollable_memory_on_half_duplex_bus(5 * 2**BANK_ADDRESS_DEPTH, 1, False)
	return (readback_cba9, readback_8765, readback_4321)

def return_fifo_string():
	fifo_cba9, fifo_8765, fifo_4321 = readout_fifo()
	return str(hex(fifo_cba9, 8)) + " " + str(hex(fifo_8765, 8)) + " " + str(hex(fifo_4321, 8))

def show_fifo():
	print(return_fifo_string())

def readout_scalers():
	bank = 2
	return althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 6, 12, False)

def return_scalers_string():
	string = ""
	for scaler in readout_scalers():
		string += str(hex(scaler, 8)) + " "
	return string

def show_scalers():
	print(return_scalers_string())

def do_something():
	show_status_register()
	show_trigger_count()
	clear_trigger_count()
	show_fifo()
	global selection
	try:
		selection += 1
	except:
		selection = 0
	select(selection)

def show_stuff():
	#print(return_fifo_string() + "     " + return_raw_values_string())
	print(return_fifo_string() + "     " + return_scalers_string())
	#show_fifo()
	#show_raw_values()

def setup_trigger_mask_inversion_mask_trigger_quantity_and_duration():
	setup_hit_mask(0b111111111111)
	#setup_hit_mask(0b000000000001)
	#setup_inversion_mask(0b101010101010)
	#setup_inversion_mask(0b010101010101)
	#setup_inversion_mask(0b111111111111)
	#setup_inversion_mask(0b000000000000)
	setup_inversion_mask(0b101000010001)
	setup_desired_trigger_quantity(int(1e3))
	setup_trigger_duration(25)
	select(1)

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

