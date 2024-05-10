#!/usr/bin/env python3

# written 2023-08-23 by mza
# based on https://github.com/mzandrew/bin/blob/master/embedded/mondrian.py
# with help from https://realpython.com/pygame-a-primer/#displays-and-surfaces
# last updated 2024-05-10 by mza

number_of_pin_diode_boxes = 4
NUMBER_OF_CHANNELS_PER_BANK = 12 # this is probably fixed for protodune at least
gui_update_period = 0.2 # in seconds
cliff = "upper" # you want this for positive-going pulses
#cliff = "lower" # you want this for negative-going pulses
ToT_threshold = 0
exaggerate_sensitive_dimension = True

#raw_threshold_scan_filename = "ampoliros.raw_threshold_scan"
threshold_scan_accumulation_time = 0.1
LTC1631A_PEDESTAL_VOLTAGE = 1.21 # from LTC1963A-adj datasheet
DAC_EPSILON = 2.5 / 2**16
MAX_COUNTER = 2**24-1 # actual counter is 24 bit
incidentals_for_null_scalers = 3
incidentals_for_display = 3
display_precision_of_hex_counter_counts = 6
display_precision_of_hex_scaler_counts = 4
display_precision_of_DAC_voltages = 6
bump_amount = 0.000250 # for the [,] keys during running to bump the dac settings up or down
extra_voltage = 0.001 # a bit of padding on each side of the threshold scan
EXTRA_EXTRA_BUMP = 0.010

# typical threshold scan has peak scalers at these voltages:
# 1.215078 1.214924 1.217697 1.211535 1.212697 1.213695 1.216734 1.218696 1.214115 1.212620 1.218383 1.215811

# set to desired scaler rate results in these voltages (ampoliros revB first article):
# 1.205999 1.204813 1.199918 1.200357 1.207928 1.203623 1.199567 1.200689 1.200037 1.205867 1.203237 1.203374 

GAP_X_BETWEEN_PLOTS = 20
GAP_Y_BETWEEN_PLOTS = 44
GAP_X_LEFT = 14
GAP_X_RIGHT = 14
GAP_Y_TOP = 24
GAP_Y_BOTTOM = 24

# geometry of protodune LBLS PIN photodiode array:
#for i in range(NUMBER_OF_CHANNELS_PER_BANK):
#	print("PD" + str(i+1) + " " + str(photodiode_positions_x_in[i]) + "," + str(photodiode_positions_y_in[i]))
box_dimension_x_in = 4.5
box_dimension_y_in = 1.4
scale_pixels_per_in = 80
if exaggerate_sensitive_dimension:
	a_in = 0.7 # lattice spacing, in in
	photodiode_can_diameter_in = 0.6
	active_square_size_in = 0.45
else:
	a_in = 0.5 # lattice spacing, in in
	photodiode_can_diameter_in = 0.325
	active_square_size_in = 0.125
photodiode_positions_x_in = [ +2.75*a_in - a_in*i for i in range(6) ] + [ +2.25*a_in - a_in*i for i in range(6) ]
photodiode_positions_y_in = [ -a_in/2 for i in range(6)] + [ +a_in/2 for i in range(6) ]
active_square_size = active_square_size_in * scale_pixels_per_in

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
X_POSITION_OF_TOT = 230
X_POSITION_OF_BANK0_REGISTERS = 100
X_POSITION_OF_BANK1_REGISTERS = 100
X_POSITION_OF_COLUMN_HEADERS = 100

#channel_range = range(1, NUMBER_OF_CHANNELS_PER_BANK+1)

channel_names = [ "" ]
channel_names.extend(["ch" + str(i+1) for i in range(NUMBER_OF_CHANNELS_PER_BANK)])
#channel_names.extend([ "trigger_count", "suggested_inversion_map", "hit_counter" ])
#print(str(channel_names))
bank1_register_values = [ i for i in range(len(channel_names)) ]

bank0_register_names = [ "hit_mask", "inversion_mask", "desired_trigger_quantity", "trigger_duration_in_word_clocks", "monitor_channel", "reg5", "reg6", "coax_mux[0]", "coax_mux[1]", "coax_mux[2]", "coax_mux[3]" ]
bank1_register_names = [ "trigger_count", "raw_trigger_count" ]

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
should_show_bank0_registers = True
should_show_bank1_registers = True
scaler_values_seen = set()

# when run as a systemd service, it gets sent a SIGHUP upon pygame.init(), hence this dummy signal handler
# see https://stackoverflow.com/questions/39198961/pygame-init-fails-when-run-with-systemd
import signal
def signal_handler(signum, frame):
	print("signal handler: got signal " + str(signum))
	sys.stdout.flush()
	if 15==signum or 2==signum:
		disable_amplifiers()
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
import generic
import zmq # pip3 install zmq
import calendar
import struct
hitmap_message = bytearray(48)
#print(str(hitmap_message))
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
from generic import * # hex, eng
import althea
BANK_ADDRESS_DEPTH = 13
import ltc2657

def setup_trigger_mask_inversion_mask_trigger_quantity_and_duration():
	setup_hit_mask(0b111111111111)
	#setup_hit_mask(0b000000000001)
	setup_inversion_mask(0b000000000000)
	#setup_inversion_mask(0b111111111111)
	setup_desired_trigger_quantity(1e9)
	setup_trigger_duration(40000)
#	select(0)

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
	print("[" + str(i) + "][" + str(j) + "]")
	plot[i][j].fill(black)
	how_many_times_we_did_not_plot = 0
	offscale_count = 0
	first_y = extra_gap_y
	last_y = plot_height - extra_gap_y
	scale_y = last_y - first_y
	for x in range(extra_gap_x, plot_width-extra_gap_x):
		pygame.event.pump()
		how_many_things_were_plotted_at_this_x_value = 0
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
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
		if how_many_things_were_plotted_at_this_x_value<NUMBER_OF_CHANNELS_PER_BANK:
			#print(str(x) + ":" + str(how_many_things_were_plotted_at_this_x_value) + "/" + str(NUMBER_OF_CHANNELS_PER_BANK))
			how_many_times_we_did_not_plot += NUMBER_OF_CHANNELS_PER_BANK - how_many_things_were_plotted_at_this_x_value
		if 0:
			if extra_gap_x==x:
				string = ""
				for k in range(NUMBER_OF_CHANNELS_PER_ASIC):
					string += str(formatted_data[k][x-extra_gap_x]) + " " + str(int(plot_height-extra_gap_y-1 - (plot_height-2*extra_gap_y)*formatted_data[k][x-extra_gap_x] + 0.5)) + ", "
				print(string)
	#print("how_many_times_we_did_not_plot: " + str(how_many_times_we_did_not_plot))
	print("offscale_count: " + str(offscale_count))
	plots_were_updated[i][j] = True
	print("done")

def draw_photodiode_box(i, j):
	offset_x = 0 # GAP_X_LEFT+i*(photodiode_box_width+GAP_X_BETWEEN_PLOTS)
	offset_y = 0 # GAP_Y_TOP+j*(photodiode_box_height+GAP_Y_BETWEEN_PLOTS)
	radius = int(photodiode_can_diameter_in * scale_pixels_per_in / 2.0)
	box = pygame.draw.rect(photodiode_box[i][j], grey, pygame.Rect(offset_x, offset_y, photodiode_box_width, photodiode_box_height), 0)
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		x = int(offset_x + photodiode_box_width/2 + photodiode_positions_x_in[k] * scale_pixels_per_in)
		y = int(offset_y + photodiode_box_height/2 - photodiode_positions_y_in[k] * scale_pixels_per_in)
		pygame.draw.circle(photodiode_box[i][j], white, (x, y), radius, 0)
		if ToT_threshold<ToT[i][k]:
			color = blue
		else:
			color = black
		pygame.draw.rect(photodiode_box[i][j], color, pygame.Rect(x-active_square_size//2, y-active_square_size//2, active_square_size, active_square_size), 0)
	screen.blit(photodiode_box[i][j], (GAP_X_LEFT+i*(photodiode_box_width+GAP_X_BETWEEN_PLOTS), GAP_Y_TOP+j*(photodiode_box_height+GAP_Y_BETWEEN_PLOTS)))

def draw_plot_border(i, j):
	#print("drawing plot border...")
	pygame.draw.rect(screen, white, pygame.Rect(GAP_X_LEFT+i*(plot_width+GAP_X_BETWEEN_PLOTS)-1, GAP_Y_TOP+photodiode_box_height+5+j*(plot_height+GAP_Y_BETWEEN_PLOTS)-1, plot_width+2, plot_height+2), 1)

def setup_zmq():
	port = 9001
	#cib_ip_address = [ "10.73.137.148", "10.73.137.148" ]
	context = zmq.Context()
	global socket
	socket = context.socket(zmq.REP)
	url = "tcp://localhost:" + str(port)
	#url = "tcp://" + cib_ip_address[0] + ":" + str(port)
	print("binding to " + url)
	socket.bind(url)

def receive_message_from_cib():
	global timestamp
	try:
		message = socket.recv(flags=zmq.NOBLOCK)
		message1 = struct.unpack("!Q", message)[0]
		message2 = time.gmtime(message1//1e9)
		message3 = time.strftime("%Y-%m-%d %H:%M:%S", message2)
		print("received: " + str(message3))
		timestamp = message1
		return True
	except zmq.Again as e:
		#print("no message received yet: " + str(e))
		return False
	except Exception as e:
		print(str(type(e).__name__) + " " + str(e))

def send_message_to_cib():
	try:
		#ns = int(calendar.timegm(time.gmtime()) * 1e9)
		#message = struct.pack("!Q", ns)
		#message2 = time.gmtime(ns//1e9)
		#message3 = time.strftime("%Y-%m-%d %H:%M:%S", message2)
		#print("sending: " + str(hitmap_message))
		print("sending:")
		message = struct.unpack("!BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", hitmap_message)
		for i in range(number_of_pin_diode_boxes):
			string = "bank" + chr(i+ord('A')) + ": "
			for j in range(NUMBER_OF_CHANNELS_PER_BANK):
				string += generic.hex(message[i*12+j], 2)
			print(string)
		socket.send(hitmap_message)
	except Exception as e:
		print(str(e))
		raise

def receive_a_message_from_cib_and_then_send_a_message_back():
	if receive_message_from_cib():
		send_message_to_cib()

def setup():
	global extra_gap_x, extra_gap_y
	extra_gap_x = 4
	extra_gap_y = 4
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
	global photodiode_box_width, photodiode_box_height
	photodiode_box_width = int(box_dimension_x_in * scale_pixels_per_in)
	photodiode_box_height = int(box_dimension_y_in * scale_pixels_per_in)
	global Y_POSITION_OF_CHANNEL_NAMES
	global Y_POSITION_OF_COUNTERS
	global Y_POSITION_OF_SCALERS
	global Y_POSITION_OF_TOT
	global Y_POSITION_OF_BANK0_REGISTERS
	global Y_POSITION_OF_BANK1_REGISTERS
	global Y_POSITION_OF_COLUMN_HEADERS
	gap = 25
	Y_POSITION_OF_CHANNEL_NAMES   = photodiode_box_height + plot_height + FONT_SIZE_BANKS + gap
	Y_POSITION_OF_COUNTERS        = photodiode_box_height + plot_height + FONT_SIZE_BANKS + gap + FONT_SIZE_BANKS
	Y_POSITION_OF_SCALERS         = photodiode_box_height + plot_height + FONT_SIZE_BANKS + gap + FONT_SIZE_BANKS
	Y_POSITION_OF_TOT             = photodiode_box_height + plot_height + FONT_SIZE_BANKS + gap + FONT_SIZE_BANKS
	Y_POSITION_OF_BANK0_REGISTERS = photodiode_box_height + plot_height + FONT_SIZE_BANKS + gap + 200
	Y_POSITION_OF_BANK1_REGISTERS = photodiode_box_height + plot_height + FONT_SIZE_BANKS + gap + 375
	Y_POSITION_OF_COLUMN_HEADERS  = photodiode_box_height + plot_height + FONT_SIZE_BANKS + gap
	global number_of_threshold_steps
	number_of_threshold_steps = plot_width
	number_of_steps_we_might_have_to_take = 2*(GUESS_AT_THRESHOLD_VOLTAGE_DISTANCE_FROM_PEAK_TO_NULL+extra_voltage)/DAC_EPSILON
	global threshold_scan_horizontal_scale
	threshold_scan_horizontal_scale = number_of_steps_we_might_have_to_take/number_of_threshold_steps
	print("threshold_scan_horizontal_scale: " + str(threshold_scan_horizontal_scale))
	global threshold_step_size_in_volts
	threshold_step_size_in_volts = DAC_EPSILON * threshold_scan_horizontal_scale
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
	global photodiode_box
	photodiode_box = [ [ pygame.Surface((photodiode_box_width, photodiode_box_height)) for j in range(ROWS) ] for i in range(COLUMNS) ]
	#plot_rect = [ [ plot[i][j].get_rect() for j in range(ROWS) ] for i in range(COLUMNS) ]
	#clear_plots()
	global banks_font
	banks_font = pygame.font.SysFont("monospace", FONT_SIZE_BANKS)
	column_headers = [ "count", "scal", "ToT" ]
	x_positions_of_column_headers = [ X_POSITION_OF_COUNTERS-4, X_POSITION_OF_SCALERS, X_POSITION_OF_TOT+4 ]
	for i in range(len(column_headers)):
		register_name = banks_font.render(column_headers[i], 1, white)
		screen.blit(register_name, register_name.get_rect(center=(x_positions_of_column_headers[i]-register_name.get_width()//2,Y_POSITION_OF_COLUMN_HEADERS)))
	for i in range(len(bank0_register_names)):
		register_name = banks_font.render(bank0_register_names[i], 1, white)
		screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK0_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK0_REGISTERS+FONT_SIZE_BANKS*i)))
	for i in range(len(bank1_register_names)):
		register_name = banks_font.render(bank1_register_names[i], 1, white)
		screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_BANK1_REGISTERS+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))
	#for i in range(NUMBER_OF_CHANNELS_PER_BANK):
	for i in range(len(channel_names)):
		register_name = banks_font.render(channel_names[i], 1, white)
		screen.blit(register_name, register_name.get_rect(center=(X_POSITION_OF_CHANNEL_NAMES+BANKS_X_GAP+register_name.get_width()//2,Y_POSITION_OF_CHANNEL_NAMES+FONT_SIZE_BANKS*i)))
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
	#set_threshold_voltages(0.456789)
	set_thresholds_for_upper_null_scaler(i, 0)
	global should_check_for_new_data
	should_check_for_new_data = pygame.USEREVENT + 1
	#print("gui_update_period: " + str(gui_update_period))
	pygame.time.set_timer(should_check_for_new_data, int(gui_update_period*1000/COLUMNS/ROWS))
	enable_amplifiers()
	setup_zmq()

def loop():
	#pygame.time.wait(10)
	game_clock.tick(100)
	global running
	global something_was_updated
	something_was_updated = True
	#pressed_keys = pygame.key.get_pressed()
	#pygame.event.wait()
	mouse = pygame.mouse.get_pos()
	from pygame.locals import K_UP, K_DOWN, K_LEFT, K_RIGHT, K_ESCAPE, KEYDOWN, QUIT, K_BREAK, K_SPACE, K_F1, K_F2, K_F3, K_F4, K_F5, K_F6, K_F7, K_F8, K_c, K_d, K_s, K_t, K_z, K_q, K_0, K_1, K_2, K_3, K_RIGHTBRACKET, K_LEFTBRACKET
	for event in pygame.event.get():
		if event.type == KEYDOWN:
			if K_ESCAPE==event.key or K_q==event.key:
				running = False
			elif K_F1==event.key:
				sophisticated_threshold_scan(0, 0)
				after_running_sophisticated_threshold_scan(0, 0)
			elif K_F2==event.key:
				sophisticated_threshold_scan(1, 0)
				after_running_sophisticated_threshold_scan(1, 0)
			elif K_F3==event.key:
				sophisticated_threshold_scan(2, 0)
				after_running_sophisticated_threshold_scan(2, 0)
			elif K_F4==event.key:
				sophisticated_threshold_scan(3, 0)
				after_running_sophisticated_threshold_scan(3, 0)
			elif K_F5==event.key:
				set_thresholds_for_this_scaler_rate_during_this_accumulation_time(0, 0, 10, 0.5)
			elif K_F6==event.key:
				set_thresholds_for_this_scaler_rate_during_this_accumulation_time(1, 0, 10, 0.5)
			elif K_F7==event.key:
				set_thresholds_for_this_scaler_rate_during_this_accumulation_time(2, 0, 10, 0.5)
			elif K_F8==event.key:
				set_thresholds_for_this_scaler_rate_during_this_accumulation_time(3, 0, 10, 0.5)
			elif K_c==event.key:
				clear_channel_counters()
				clear_channel_ones_counters()
				print("channel counters cleared")
			elif K_d==event.key:
				global should_show_counters
				should_show_counters = not should_show_counters
			elif K_s==event.key:
				global should_show_scalers
				should_show_scalers = not should_show_scalers
			elif K_t==event.key:
				clear_trigger_count()
			elif K_z==event.key:
				for i in range(number_of_pin_diode_boxes):
					if "lower"==cliff:
						set_thresholds_for_lower_null_scaler(i, 0)
					else:
						set_thresholds_for_upper_null_scaler(i, 0)
			elif K_RIGHTBRACKET==event.key:
				for i in range(number_of_pin_diode_boxes):
					bump_thresholds_higher_by(i, 0, bump_amount)
			elif K_LEFTBRACKET==event.key:
				for i in range(number_of_pin_diode_boxes):
					bump_thresholds_lower_by(i, 0, bump_amount)
#			elif K_0==event.key:
#				increment_coax_mux(0)
#			elif K_1==event.key:
#				increment_coax_mux(1)
#			elif K_2==event.key:
#				increment_coax_mux(2)
#			elif K_3==event.key:
#				increment_coax_mux(3)
		elif event.type == QUIT:
			running = False
		elif event.type == should_check_for_new_data:
			should_respond_to_cib = receive_message_from_cib()
			update_bank0_registers()
			update_bank1_bank2_scalers()
			update_other_bank1_registers()
			update_counters()
			update_ToT()
			if should_respond_to_cib:
				send_message_to_cib()
		elif event.type == pygame.MOUSEBUTTONDOWN:
			do_something()
	for i in range(number_of_pin_diode_boxes):
		draw_photodiode_box(i, 0)
	flip()

def after_running_sophisticated_threshold_scan(i, j):
	global have_just_run_threshold_scan
	for i in range(COLUMNS):
		for j in range(ROWS):
			if have_just_run_threshold_scan[i]:
				have_just_run_threshold_scan[i] = False
				update_plot(i, j)
			#show_stuff()
	for i in range(COLUMNS):
		for j in range(ROWS):
			blit(i, j)

def blit(i, j):
	global something_was_updated
	if plots_were_updated[i][j]:
		#print("blitting...")
		screen.blit(plot[i][j], (GAP_X_LEFT+i*(plot_width+GAP_X_BETWEEN_PLOTS), GAP_Y_TOP+photodiode_box_height+5+j*(plot_height+GAP_Y_BETWEEN_PLOTS)))
		#pygame.image.save(plot[i][j], "protodune." + str(i) + ".png")
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

def read_bank1_registers():
	global bank1_register_values
	bank = 1
	bank1_register_values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 13, len(bank1_register_names), False)

def readout_ToT():
	global ToT
	global hitmap_message
	bank = 3
	values = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 1, NUMBER_OF_CHANNELS_PER_BANK, False)
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		ToT[0][k] = (values[k]    ) & 0xff
		ToT[1][k] = (values[k]>>8 ) & 0xff
		ToT[2][k] = (values[k]>>16) & 0xff
		ToT[3][k] = (values[k]>>24) & 0xff
	#hitmap_message = struct.pack("", )
	for j in range(number_of_pin_diode_boxes):
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			index = j*NUMBER_OF_CHANNELS_PER_BANK+k
			hitmap_message[index] = ToT[j][k]
			#hitmap_message[index] = k

bank0_register_object = [ 0 for i in range(len(bank0_register_names)) ]
bank1_register_object = [ 0 for i in range(len(bank1_register_names)) ]

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

def update_other_bank1_registers():
	#trigger_count = get_trigger_count()
	global bank1_register_object
	read_bank1_registers()
	if should_show_bank1_registers:
		for i in range(len(bank1_register_names)):
			try:
				temp_surface = pygame.Surface(bank1_register_object[i].get_size())
				temp_surface.fill(dark_green)
				screen.blit(temp_surface, bank1_register_object[i].get_rect(center=(X_POSITION_OF_BANK1_REGISTERS-bank1_register_object[i].get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))
			except Exception as e:
				#print(str(e))
				pass
			bank1_register_object[i] = banks_font.render(hex(bank1_register_values[i], 8, True), False, white)
			screen.blit(bank1_register_object[i], bank1_register_object[i].get_rect(center=(X_POSITION_OF_BANK1_REGISTERS-bank1_register_object[i].get_width()//2,Y_POSITION_OF_BANK1_REGISTERS+FONT_SIZE_BANKS*i)))

#def read_status_register():
#	bank = 1
#	global status_register
#	status_register, = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH, 0, False)
#	return status_register

#def show_status_register():
#	read_status_register()
#	print("status register: " + str(hex(status_register, 8)))

def show_other_registers():
	bank = 1
	trigger_count = althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 13, 1, False)[0]
	print("trigger_count: " + str(trigger_count))
#	print("suggested_inversion_map: " + hex(suggested_inversion_map, 3))
#	print("hit_counter_buffered: " + str(hit_counter_buffered))

def setup_hit_mask(hit_mask):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 0, [hit_mask], False)

def setup_inversion_mask(inversion_mask):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 1, [inversion_mask], False)

def setup_desired_trigger_quantity(quantity):
	bank = 0
	quantity = int(quantity)
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 2, [quantity], False)

def setup_trigger_duration(number_of_word_clocks):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 3, [number_of_word_clocks], False)

#def change_coax_mux(channel, mux_value):
#	bank = 0
#	channel &= 0x3
#	mux_value &= 0xf
#	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 7 + channel, [mux_value], False)

#def increment_coax_mux(channel):
#	channel &= 0x3
#	global coax_mux
#	coax_mux[channel] += 1
#	if 0xf<coax_mux[channel]:
#		coax_mux[channel] = 0
#	change_coax_mux(channel, coax_mux[channel])

def clear_something_on_bank0_reg5(bit_number):
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [1<<bit_number], False)
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [0], False)

def clear_gate_counter():
	clear_something_on_bank0_reg5(0)

def clear_trigger_count():
	print("trigger count cleared")
	clear_something_on_bank0_reg5(1)

def clear_hit_counter():
	clear_something_on_bank0_reg5(2)

def clear_channel_counters():
	clear_something_on_bank0_reg5(3)

def clear_channel_ones_counters():
	clear_something_on_bank0_reg5(4)

#def select(value):
#	print("select: " + str(value))
#	bank = 0
#	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 5, [value], False)

def enable_amplifiers():
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 6, [1], False)

def disable_amplifiers():
	bank = 0
	althea.write_to_half_duplex_bus_and_then_verify(bank * 2**BANK_ADDRESS_DEPTH + 6, [0], False)

def get_trigger_count():
	bank = 1
	return althea.read_data_from_pollable_memory_on_half_duplex_bus(bank * 2**BANK_ADDRESS_DEPTH + 13, 1, False)[0]

def show_trigger_count():
	trigger_count = get_trigger_count()
	#print("trigger count: " + str(hex(trigger_count, display_precision_of_hex_counter_counts)))
	print("trigger count: " + str(trigger_count))

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

def update_ToT():
	readout_ToT()
	for j in range(number_of_pin_diode_boxes):
		for i in range(NUMBER_OF_CHANNELS_PER_BANK):
			try:
				temp_surface = pygame.Surface(ToT_object[j][i].get_size())
				temp_surface.fill(blue)
				screen.blit(temp_surface, ToT_object[j][i].get_rect(center=(X_POSITION_OF_TOT+j*(plot_width+GAP_X_BETWEEN_PLOTS)-ToT_object[j][i].get_width()//2,Y_POSITION_OF_TOT+FONT_SIZE_BANKS*i)))
			except Exception as e:
				#print(str(e))
				pass
			ToT_object[j][i] = banks_font.render(hex(ToT[j][i], 2, True), False, white)
			screen.blit(ToT_object[j][i], ToT_object[j][i].get_rect(center=(X_POSITION_OF_TOT+j*(plot_width+GAP_X_BETWEEN_PLOTS)-ToT_object[j][i].get_width()//2,Y_POSITION_OF_TOT+FONT_SIZE_BANKS*i)))

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

def do_something():
	#print("")
	#show_other_registers()
	#show_status_register()
	show_trigger_count()
	#show_fifo()
	return
#	global selection
#	selection += 1
#	if 7<selection:
#		selection = 0
#	select(selection)

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
		counters = readout_counters(0, 0)
		string = ""
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			if counters[k]<number_of_passes*tickles_incidentals:
				string += "         "
			else:
				string += hex(counters[k], display_precision_of_hex_counter_counts) + " "
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
	for i in range(number_of_pin_diode_boxes):
		current_threshold_voltage[i] = [ voltage for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	#print(str(voltage))
	ltc2657.set_voltage_on_all_channels(voltage)

def set_threshold_voltage(i, channel, voltage):
	if 4==number_of_pin_diode_boxes:
		dac_addresses = [ 0x10, 0x52, 0x12, 0x60, 0x22, 0x70, 0x30, 0x72 ]
	else:
		dac_addresses = [ 0x10, 0x12 ]
	global current_threshold_voltage
	current_threshold_voltage[i][channel] = voltage
	#print(str(channel) + " " + str(voltage), end=" ")
	#print("bank" + chr(i+ord('A')) + " ch" + str(channel) + " volt" + str(voltage), end=" ")
	dac_address = dac_addresses[2*i+channel//6] # first 6 channels are on first i2c address in dac_addresses[]; next 6 are on the next in the list
	channel %= 6
	#print(hex(dac_address) + " " + str(channel))
	ltc2657.set_voltage_on_channel(dac_address, channel, voltage)

def set_thresholds_for_lower_null_scaler(i, j):
	voltage_at_lower_null_scaler = read_thresholds_for_lower_null_scalers_file(i, j)
	print(prepare_string_with_voltages(voltage_at_lower_null_scaler))
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		set_threshold_voltage(i, k, voltage_at_lower_null_scaler[k])

def set_thresholds_for_upper_null_scaler(i, j):
	voltage_at_upper_null_scaler = read_thresholds_for_upper_null_scalers_file(i, j)
	print(prepare_string_with_voltages(voltage_at_upper_null_scaler))
	voltage_at_upper_null_scaler = [ voltage_at_upper_null_scaler[k] + EXTRA_EXTRA_BUMP for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		set_threshold_voltage(i, k, voltage_at_upper_null_scaler[k])

def read_thresholds_for_lower_null_scalers_file(i, j):
	voltage_at_peak_scaler = read_thresholds_for_peak_scalers_file(i, j)
	#print("peak: " + str(voltage_at_peak_scaler))
	default_voltage_at_lower_null_scaler = [ voltage_at_peak_scaler[k] - GUESS_AT_THRESHOLD_VOLTAGE_DISTANCE_FROM_PEAK_TO_NULL for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	#print("null: " + str(default_voltage_at_lower_null_scaler))
	if not os.path.exists(thresholds_for_lower_null_scalers_filename[i]):
		print("thresholds for null scalers file not found")
		return default_voltage_at_lower_null_scaler
	try:
		with open(thresholds_for_lower_null_scalers_filename[i], "r") as thresholds_for_lower_null_scalers_file:
			string = thresholds_for_lower_null_scalers_file.read(256)
			voltage_at_lower_null_scaler = string.split(" ")
			voltage_at_lower_null_scaler = [ i for i in voltage_at_lower_null_scaler if i!='' ]
			voltage_at_lower_null_scaler.remove('\n')
			voltage_at_lower_null_scaler = [ float(voltage_at_lower_null_scaler[k]) for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
			#print(prepare_string_with_voltages(voltage_at_lower_null_scaler))
			#print("null: " + str(voltage_at_lower_null_scaler))
			return voltage_at_lower_null_scaler
	except:
		print("threshold for null scalers file exists but is corrupted")
		# maybe delete the file here?
		return default_voltage_at_lower_null_scaler

def read_thresholds_for_upper_null_scalers_file(i, j):
	voltage_at_peak_scaler = read_thresholds_for_peak_scalers_file(i, j)
	#print("peak: " + str(voltage_at_peak_scaler))
	default_voltage_at_upper_null_scaler = [ voltage_at_peak_scaler[k] + GUESS_AT_THRESHOLD_VOLTAGE_DISTANCE_FROM_PEAK_TO_NULL for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	#print("null: " + str(default_voltage_at_upper_null_scaler))
	if not os.path.exists(thresholds_for_upper_null_scalers_filename[i]):
		print("thresholds for null scalers file not found")
		return default_voltage_at_upper_null_scaler
	try:
		with open(thresholds_for_upper_null_scalers_filename[i], "r") as thresholds_for_upper_null_scalers_file:
			string = thresholds_for_upper_null_scalers_file.read(256)
			voltage_at_upper_null_scaler = string.split(" ")
			voltage_at_upper_null_scaler = [ i for i in voltage_at_upper_null_scaler if i!='' ]
			voltage_at_upper_null_scaler.remove('\n')
			voltage_at_upper_null_scaler = [ float(voltage_at_upper_null_scaler[k]) for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
			#print(prepare_string_with_voltages(voltage_at_upper_null_scaler))
			#print("null: " + str(voltage_at_upper_null_scaler))
			return voltage_at_upper_null_scaler
	except:
		print("threshold for null scalers file exists but is corrupted")
		# maybe delete the file here?
		return default_voltage_at_upper_null_scaler

def read_thresholds_for_peak_scalers_file(i, j):
	default_voltage_at_peak_scaler = [ GUESS_FOR_VOLTAGE_AT_PEAK_SCALER for i in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	if not os.path.exists(thresholds_for_peak_scalers_filename[i]):
		print("threshold for peak scalers file not found")
		return default_voltage_at_peak_scaler
	try:
		with open(thresholds_for_peak_scalers_filename[i], "r") as thresholds_for_peak_scalers_file:
			string = thresholds_for_peak_scalers_file.read(256)
			voltage_at_peak_scaler = string.split(" ")
			voltage_at_peak_scaler = [ i for i in voltage_at_peak_scaler if i!='' ]
			voltage_at_peak_scaler.remove('\n')
			voltage_at_peak_scaler = [ float(voltage_at_peak_scaler[k]) for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
			#print(prepare_string_with_voltages(voltage_at_peak_scaler))
			#print("peak: " + str(voltage_at_peak_scaler))
			return voltage_at_peak_scaler
	except:
		print("threshold for peak scalers file exists but is corrupted")
		return default_voltage_at_peak_scaler

def prepare_string_to_show_counters_or_scalers(values):
	string = ""
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		if values[k]<=incidentals_for_display:
			string += " %*s" % (display_precision_of_hex_counter_counts, "")
		else:
			string += hex(values[k], display_precision_of_hex_counter_counts, True) + " "
	return string

def prepare_string_with_voltages(voltage):
	string = ""
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		string += "%.*f " % (display_precision_of_DAC_voltages, voltage[k])
	return string

import copy
upper_null_scaler_zero_value = 1
lower_null_scaler_zero_value = 1
def sophisticated_threshold_scan(i, j):
	print("running threshold scan for bank" + chr(i+ord('A')) + "...")
	global have_just_run_threshold_scan
	have_just_run_threshold_scan[i] = True
	max_scaler_seen = [ 0 for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	global voltage_at_peak_scaler
	voltage_at_peak_scaler = [ 0 for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	bank = 0
	global voltage_at_lower_null_scaler
	global voltage_at_upper_null_scaler
	voltage_at_lower_null_scaler = read_thresholds_for_lower_null_scalers_file(i, j)
	voltage_at_upper_null_scaler = read_thresholds_for_upper_null_scalers_file(i, j)
	if "lower"==cliff:
		voltage = [ voltage_at_lower_null_scaler[k] - extra_voltage for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	else:
		voltage = [ voltage_at_upper_null_scaler[k] + extra_voltage for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	#print(str(voltage))
	for k in range(NUMBER_OF_CHANNELS_PER_BANK):
		#voltage[k] = fround(voltage[k], 0.000001)
		voltage[k] = fround(voltage[k], DAC_EPSILON)
	#print(str(voltage))
	number_of_unique_voltages = len(set(voltage))
	print("number_of_unique_voltages: " + str(number_of_unique_voltages))
	total_hits_seen_so_far_in_this_scan = [ 0 for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	global threshold_scan
	threshold_scan = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
	slice = [ [ i/10, 0 ] for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
	previous_count_was_nonzero = [ False for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
#	with open(raw_threshold_scan_filename, "w") as raw_threshold_scan_file:
	for n in range(number_of_threshold_steps):
		string = ""
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			set_threshold_voltage(i, k, voltage[k])
			#string += " %.*f " % (display_precision_of_DAC_voltages, voltage[k])
		#print(string)
		clear_channel_counters()
		time.sleep(threshold_scan_accumulation_time)
		counters = readout_counters(i, j)
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
#			slice[k] = [ copy.deepcopy(voltage[k]), counters[k] ]
			slice[k] = [ voltage[k], counters[k] ]
			scaler_values_seen.add(counters[k])
		#print(str(slice))
		threshold_scan[i][j].append(copy.deepcopy(slice))
		if 1==number_of_unique_voltages:
			string += " %.*f " % (display_precision_of_DAC_voltages, voltage[0]) # the voltages are potentially different for each channel here, so don't print this unless all voltages are equal
		string += prepare_string_to_show_counters_or_scalers(counters)
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			if max_scaler_seen[k]<counters[k]:
				max_scaler_seen[k] = counters[k]
				voltage_at_peak_scaler[k] = voltage[k]
			total_hits_seen_so_far_in_this_scan[k] += counters[k]
			if total_hits_seen_so_far_in_this_scan[k]<=incidentals_for_null_scalers:
				if "lower"==cliff:
					voltage_at_lower_null_scaler[k] = voltage[k]
				else:
					voltage_at_upper_null_scaler[k] = voltage[k]
				string += "*"
			else:
				string += " "
			if "lower"==cliff:
				if previous_count_was_nonzero[k] and upper_null_scaler_zero_value==counters[k]:
					voltage_at_upper_null_scaler[k] = voltage[k]
					#print("ch" + str(k) + " v:" + str(voltage[k]))
			else:
				if previous_count_was_nonzero[k] and lower_null_scaler_zero_value==counters[k]:
					voltage_at_lower_null_scaler[k] = voltage[k]
					#print("ch" + str(k) + " v:" + str(voltage[k]))
		print(string)
#		raw_threshold_scan_file.write(string + "\n")
#		if 0==n%10:
#			raw_threshold_scan_file.flush()
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			if "lower"==cliff:
				if upper_null_scaler_zero_value==counters[k]:
					previous_count_was_nonzero[k] = False
				else:
					previous_count_was_nonzero[k] = True
			else:
				if lower_null_scaler_zero_value==counters[k]:
					previous_count_was_nonzero[k] = False
				else:
					previous_count_was_nonzero[k] = True
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			if "lower"==cliff:
				voltage[k] += threshold_step_size_in_volts
			else:
				voltage[k] -= threshold_step_size_in_volts
	with open(thresholds_for_peak_scalers_filename[i], "w") as thresholds_for_peak_scalers_file:
		string = prepare_string_with_voltages(voltage_at_peak_scaler)
		print("peak: " + string)
		thresholds_for_peak_scalers_file.write(string + "\n")
	with open(thresholds_for_lower_null_scalers_filename[i], "w") as thresholds_for_lower_null_scalers_file:
		string = prepare_string_with_voltages(voltage_at_lower_null_scaler)
		print("null: " + string)
		thresholds_for_lower_null_scalers_file.write(string + "\n")
	with open(thresholds_for_upper_null_scalers_filename[i], "w") as thresholds_for_upper_null_scalers_file:
		string = prepare_string_with_voltages(voltage_at_upper_null_scaler)
		print("null: " + string)
		thresholds_for_upper_null_scalers_file.write(string + "\n")
	if "lower"==cliff:
		set_thresholds_for_lower_null_scaler(i, j)
	else:
		set_thresholds_for_upper_null_scaler(i, j)
#	print("number of scaler values seen: " + str(len(scaler_values_seen)))
#	min = 2**16-1
#	max = -1
#	for value in scaler_values_seen:
#		if value<min:
#			min = value
#		if max<value:
#			max = value
#	print("min:" + str(min))
#	print("max:" + str(max))
#	print(str(sorted(scaler_values_seen)))

def set_thresholds_for_this_scaler_rate_during_this_accumulation_time(i, j, desired_rate, accumulation_time):
	print("finding " + str(desired_rate) + " operating point for bank" + chr(i+ord('A')) + "...")
	span_up = 1.5
	span_down = 2.0
	target_chi_squared = 9 * (span_up + span_down)**2
	print("target_chi_squared: " + str(target_chi_squared))
	if "lower"==cliff:
		voltage = read_thresholds_for_lower_null_scalers_file(i, j)
	else:
		voltage = read_thresholds_for_upper_null_scalers_file(i, j)
	stable = False
	while not stable:
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			set_threshold_voltage(i, k, voltage[k])
		clear_channel_counters()
		time.sleep(accumulation_time)
		counters = readout_counters(i, j)
		string = prepare_string_to_show_counters_or_scalers(counters)
		print(string)
		chi_squared = 0
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			chi_squared += (counters[k] - desired_rate)**2
			if desired_rate<counters[k]+span_down:
				if "lower"==cliff:
					voltage[k] -= threshold_step_size_in_volts
				else:
					voltage[k] += threshold_step_size_in_volts
			if counters[k]+span_up<desired_rate:
				if "lower"==cliff:
					voltage[k] += threshold_step_size_in_volts
				else:
					voltage[k] -= threshold_step_size_in_volts
		pygame.event.pump()
		print("chi_squared: " + str(chi_squared))
		if chi_squared<target_chi_squared:
			stable = True
		time.sleep(0.1)
	print(prepare_string_with_voltages(voltage))

def bump_thresholds_lower_by(i, j, offset_voltage):
	for i in range(number_of_pin_diode_boxes):
		voltage = [ current_threshold_voltage[i][k] - offset_voltage for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
		string = prepare_string_with_voltages(voltage)
		print(string)
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			set_threshold_voltage(i, k, voltage[k])

def bump_thresholds_higher_by(i, j, offset_voltage):
	for i in range(number_of_pin_diode_boxes):
		voltage = [ current_threshold_voltage[i][k] + offset_voltage for k in range(NUMBER_OF_CHANNELS_PER_BANK) ]
		string = prepare_string_with_voltages(voltage)
		print(string)
		for k in range(NUMBER_OF_CHANNELS_PER_BANK):
			set_threshold_voltage(i, k, voltage[k])

def show_stuff():
	#althea.write_ones_to_bank_that_is_depth(0, BANK_ADDRESS_DEPTH)
	#althea.write_value_to_bank_that_is_depth(0b0000010000000000, 0, BANK_ADDRESS_DEPTH) # gpio16 tickles signal[1, 12]
	#althea.write_value_to_bank_that_is_depth(0b0000001000000000, 0, BANK_ADDRESS_DEPTH) # gpio15 tickles signal[7, 11, 12]
	#althea.write_value_to_bank_that_is_depth(0b0001000000000000, 0, BANK_ADDRESS_DEPTH) # gpio18 tickles signal[7, 12]
	#scalers_string = return_counters_string(i, j)
	#scalers_string = return_scalers_string(i, j)
	#fifo_string = ""
	#fifo_string = return_fifo_string()
	#print(return_fifo_string() + "     " + return_raw_values_string())
	#print(return_fifo_string() + "     " + return_scalers_string(i, j))
	#print(fifo_string + "     " + scalers_string)
	#show_fifo()
	#show_raw_values()
	#readout_fifo_multiple(4)
	#show_fifo_split()
	pass

if __name__ == "__main__":
	from sys import argv
	if len(argv)>1:
		channels = int(argv[1])
		print(str(channels))
		number_of_pin_diode_boxes = channels // NUMBER_OF_CHANNELS_PER_BANK
	ROWS = 1
	COLUMNS = number_of_pin_diode_boxes
	wasted_width = int(GAP_X_LEFT + GAP_X_RIGHT + (COLUMNS-1)*GAP_X_BETWEEN_PLOTS)
	desired_window_width = int(number_of_pin_diode_boxes * box_dimension_x_in * scale_pixels_per_in + wasted_width)
	SCREEN_WIDTH = desired_window_width
	SCREEN_HEIGHT = 725
	if 1==number_of_pin_diode_boxes:
		# ampoliros12 revB
		GUESS_FOR_VOLTAGE_AT_PEAK_SCALER = LTC1631A_PEDESTAL_VOLTAGE - 0.008 # [1.196,1.214] avg=1.2045
		GUESS_AT_THRESHOLD_VOLTAGE_DISTANCE_FROM_PEAK_TO_NULL = 0.060 / 2 # for when diff_term=false
	else:
		# ampoliros48 revA board #2
		GUESS_FOR_VOLTAGE_AT_PEAK_SCALER = LTC1631A_PEDESTAL_VOLTAGE - 0.006 # [1.194,1.210] avg=1.203
		GUESS_AT_THRESHOLD_VOLTAGE_DISTANCE_FROM_PEAK_TO_NULL = 0.045 / 2 # for when diff_term=false
	thresholds_for_peak_scalers_filename = []
	thresholds_for_lower_null_scalers_filename = []
	thresholds_for_upper_null_scalers_filename = []
	for i in range(number_of_pin_diode_boxes):
		thresholds_for_peak_scalers_filename.append("ampoliros.thresholds_for_peak_scalers.bank" + chr(i+ord('A')))
		thresholds_for_lower_null_scalers_filename.append("ampoliros.thresholds_for_lower_null_scalers.bank" + chr(i+ord('A')))
		thresholds_for_upper_null_scalers_filename.append("ampoliros.thresholds_for_upper_null_scalers.bank" + chr(i+ord('A')))
	have_just_run_threshold_scan = [ False for i in range(number_of_pin_diode_boxes) ]
	current_threshold_voltage = [ [ 0.45678 for k in range(NUMBER_OF_CHANNELS_PER_BANK) ] for i in range(number_of_pin_diode_boxes) ]
	plots_were_updated = [ [ False for j in range(ROWS) ] for i in range(COLUMNS) ]
	plot_name = [ [ "bank" + chr(i+ord('A')) for j in range(ROWS) ] for i in range(COLUMNS) ]
	short_feed_name = [ [ [] for j in range(ROWS) ] for i in range(COLUMNS) ]
	minimum = [ [ 0 for j in range(ROWS) ] for i in range(COLUMNS) ]
	maximum = [ [ 100 for j in range(ROWS) ] for i in range(COLUMNS) ]
	ToT = [ [ 0 for i in range(NUMBER_OF_CHANNELS_PER_BANK) ] for j in range(number_of_pin_diode_boxes) ]
	ToT_object = [ [ 0 for i in range(NUMBER_OF_CHANNELS_PER_BANK) ] for j in range(number_of_pin_diode_boxes) ]
	setup()
	#write_to_pollable_memory_value()
	running = True
	while running:
		loop()
		sys.stdout.flush()
	disable_amplifiers()
	pygame.quit()

