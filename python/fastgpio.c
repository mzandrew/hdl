// written 2020-06-05 by mza
// merged a modified version of code from https://github.com/hzeller/rpi-gpio-dma-demo/blob/master/gpio-dma-test.c
// with modification of example code from https://realpython.com/build-python-c-extension-module/
// with help from https://docs.python.org/3.7/extending/newtypes_tutorial.html
// last updated 2020-06-23 by mza

// how to use this module:
//	import fastgpio
//	# fastgpio.bus:
//	mask = 0xfff
//	output_bus = fastgpio.bus(mask, 1, 0)
//	data = [0xaaa, 0x555, 0xfff, 0x000]
//	output_bus.write(data)
//	# fastgpio.clock:
//	clock = fastgpio.clock()
//	...
//	clock.terminate()

typedef unsigned char u8;
typedef unsigned long u32;

#include <stdio.h> // printf, fprintf
#include <stdlib.h> // srandom, random
#include <time.h> // nanosleep
#include <fcntl.h> // open
#include <sys/mman.h> // mmap
#include <stdbool.h>
#include <Python.h>
#include <bcm_host.h> // bcm_host_get_peripheral_address -I/opt/vc/include -L/opt/vc/lib -lbcm_host
#include "DebugInfoWarningError.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// ---- GPIO specific defines
//#define PERI_BASE (0x20000000)
#define GPIO_REGISTER_BASE (0x200000)
#define GPIO_SET_OFFSET (0x1C/sizeof(u32))
#define GPIO_CLR_OFFSET (0x28/sizeof(u32))
#define GPIO_PIN_LEVEL  (0x34/sizeof(u32))
#define GPIO_REGISTER_MAX (0xb0/sizeof(u32))
#define PI_INPUT  0
#define PI_OUTPUT 1
#define PI_ALT0   4

#define BCM2835_PADS_GPIO_0_27 (0x100000)
#define BCM2835_PADS_GPIO_0_27_OFFSET (0x2c/sizeof(u32))
#define BCM2835_PADS_GPIO_MAX         (0x40/sizeof(u32))

#define CLK_BASE (0x101000)
#define CLK_PASSWD  (0x5A<<24)
//#define CLK_CTL_SRC_OSC  1  /* 19.2 MHz */
//#define CLK_CTL_SRC_PLLC 5  /* 1000 MHz */
#define CLK_CTL_SRC_PLLD (6)  /*  500 MHz */
//#define CLK_CTL_SRC_HDMI 7  /*  216 MHz */
#define CLK_CTL_BUSY     (1 << 7)
#define CLK_CTL_KILL     (1 << 5)
#define CLK_CTL_ENAB     (1 << 4)
#define CLK_CTL_MASH(x) ((x)<< 9)
#define CLK_CTL_SRC(x)  ((x)<< 0)
#define CLK_DIV_DIVI(x) ((x)<<12)
#define CLK_DIV_DIVF(x) ((x)<< 0)
#define CLK_GP0_CTL (28)
#define CLK_GP0_DIV (29)

static PyObject* method_test(PyObject *self, PyObject *args);

u32 short_delay = 30;
//u32 short_delay = 100000;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void show_a_block_of_registers(volatile u32 *start, u32 count) {
	if (0==start) { fprintf(warning, "cowardly refusing to show target of NULL pointer (run with sudo?)...\n"); return; }
	u32 value;
	for (u32 i=0; i<count+1; i++) {
		value = start[i];
		printf("%08lx:%08lx\n", (u32) &start[i], value); // read-only registers return 0x6770696f "gpio"
	}
}

// Return a pointer to a periphery subsystem register.
static void *mmap_bcm_gpio_register(off_t page_offset) {
	//const off_t base = PERI_BASE;
	//const off_t base = bcm_host_get_peripheral_address(); // https://www.raspberrypi.org/documentation/hardware/raspberrypi/peripheral_addresses.md
	// from openocd's src/jtag/drivers/bcm2835gpio.c
	// and from https://elinux.org/Rpi_Datasheet_751_GPIO_Registers
	// see also https://github.com/raspberrypi/linux/pull/1112
	int dev_mem_fd = open("/dev/gpiomem", O_RDWR | O_SYNC);
	if (dev_mem_fd < 0) {
		printf("Cannot open /dev/gpiomem, fallback to /dev/mem\n");
		dev_mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
		if (dev_mem_fd < 0) {
			perror("can't open /dev/mem: ");
			fprintf(stderr, "You need to run this as root!\n");
			return NULL;
		}
	} else {
		page_offset = 0; // just to prove the offset is meaningless for the gpiomem device
	}
	//printf("page_offset: %08lx\n", page_offset);
	u32 *result =
		(u32*) mmap(NULL,                  // Any adddress in our space will do
		                 sysconf(_SC_PAGE_SIZE),
		                 PROT_READ|PROT_WRITE,  // Enable r/w on GPIO registers.
		                 MAP_SHARED,
		                 dev_mem_fd,                // File to map
		                 page_offset // Offset to bcm register
		                 );
	close(dev_mem_fd);
	if (result == MAP_FAILED) {
		fprintf(stderr, "mmap error %p\n", result);
		return NULL;
	}
	return result;
}

// Return a pointer to a periphery subsystem register.
static void *mmap_bcm_register(off_t page_offset) {
	// from openocd's src/jtag/drivers/bcm2835gpio.c
	// and from https://elinux.org/Rpi_Datasheet_751_GPIO_Registers
	int dev_mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
	if (dev_mem_fd < 0) {
		perror("can't open /dev/mem: ");
		fprintf(stderr, "You need to run this as root!\n");
		return NULL;
	}
	//const off_t base = PERI_BASE;
	const off_t base = bcm_host_get_peripheral_address(); // https://www.raspberrypi.org/documentation/hardware/raspberrypi/peripheral_addresses.md
	//printf("base+page_offset: %08lx\n", base + page_offset);
	u32 *result =
		(u32*) mmap(NULL,                  // Any adddress in our space will do
		                 sysconf(_SC_PAGE_SIZE),
		                 PROT_READ|PROT_WRITE,  // Enable r/w on GPIO registers.
		                 MAP_SHARED,
		                 dev_mem_fd,                // File to map
		                 base + page_offset // Offset to bcm register
		                 );
	close(dev_mem_fd);
	if (result == MAP_FAILED) {
		fprintf(stderr, "mmap error %p\n", result);
		return NULL;
	}
	return result;
}

// https://www.raspberrypi.org/documentation/hardware/raspberrypi/gpio/gpio_pads_control.md
void set_drive_strength_and_slew_rate(volatile u32 *gpio_pads, u8 milliamps) {
	if (0==gpio_pads) { fprintf(warning, "cowardly refusing to change drive strength using a NULL pointer (run with sudo?)...\n"); return; }
//	u8 drive_strength[] = { 2, 4, 6, 8, 10, 12, 14, 16 };
//	u8 index = 0;
//	for (int i=0; i<8; i++) {
//		index = i;
//	}
	if (milliamps<2)  { milliamps =  2; }
	if (16<milliamps) { milliamps = 16; }
	/* set drive strength, slew rate limited, hysteresis on */
	u32 value = 0x5a000000; // password and slew rate limited mode
//	value |= 1<<4; // slew rate NOT limited
	value |= 1<<3; // input hysteresis enabled
	value |= (milliamps>>1)-1; // set drive strength
	printf("intended value for gpio_pads register: %08lx\n", value);
	gpio_pads[BCM2835_PADS_GPIO_0_27_OFFSET] = value;
	//show_a_block_of_registers(gpio_pads, BCM2835_PADS_GPIO_MAX);
	value = gpio_pads[BCM2835_PADS_GPIO_0_27_OFFSET];
	printf("pads register reads: %08lx\n", value);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void initialize_gpio_for_input(volatile u32 *gpio_port, int bit) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to change gpio mode using a NULL pointer (run with sudo?)...\n"); return; }
	*(gpio_port+(bit/10)) &= ~(7<<((bit%10)*3));  // set as input
}

void initialize_gpio_for_output(volatile u32 *gpio_port, int bit) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to change gpio mode using a NULL pointer (run with sudo?)...\n"); return; }
	*(gpio_port+(bit/10)) &= ~(7<<((bit%10)*3));  // prepare: set as input
	*(gpio_port+(bit/10)) |=  (1<<((bit%10)*3));  // set as output
}

void initialize_gpios_for_input(volatile u32 *gpio_port, u32 mask) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to change gpio mode using a NULL pointer (run with sudo?)...\n"); return; }
	for (int i=0; i<32; i++) {
		u32 bit = 1<<i;
		if (bit&mask) {
//			printf("bit %d = input\n", i);
			initialize_gpio_for_input(gpio_port, i);
		}
	}
}

void initialize_gpios_for_output(volatile u32 *gpio_port, u32 mask) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to change gpio mode using a NULL pointer (run with sudo?)...\n"); return; }
	for (int i=0; i<32; i++) {
		u32 bit = 1<<i;
		if (bit&mask) {
//			printf("bit %d = output\n", i);
			initialize_gpio_for_output(gpio_port, i);
		}
	}
}

void setup_bus_as_inputs(volatile u32 *gpio_port, u32 mask) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to change gpio mode using a NULL pointer (run with sudo?)...\n"); return; }
	//printf("%08lx\n", mask);
	initialize_gpios_for_input(gpio_port, mask);
}

void setup_bus_as_outputs(volatile u32 *gpio_port, u32 mask) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to change gpio mode using a NULL pointer (run with sudo?)...\n"); return; }
	//printf("%08lx\n", mask);
	initialize_gpios_for_output(gpio_port, mask);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void myusleep(u32 microseconds) {
	u32 seconds = 0;
	if (1000000<=microseconds) {
		seconds = microseconds / 1000000;
		microseconds -= seconds * 1000000;
	}
	u32 nanoseconds = 1000 * microseconds;
	//printf("seconds=%ld, nanoseconds=%ld\n", seconds, nanoseconds);
	struct timespec delay = { seconds, nanoseconds };
	struct timespec remaining_delay = { 0, 0 }; // seconds, nanoseconds
	nanosleep(&delay, &remaining_delay);
}

void mynsleep(u32 nanoseconds) {
	u32 seconds = 0;
	if (1000000000<=nanoseconds) {
		seconds = nanoseconds / 1000000000;
		nanoseconds -= seconds * 1000000000;
	}
	//printf("seconds=%ld, nanoseconds=%ld\n", seconds, nanoseconds);
	struct timespec delay = { seconds, nanoseconds };
	struct timespec remaining_delay = { 0, 0 }; // seconds, nanoseconds
	if (nanosleep(&delay, &remaining_delay)) {
		delay.tv_sec = remaining_delay.tv_sec;
		delay.tv_nsec = remaining_delay.tv_nsec;
	}
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

typedef struct {
	PyObject_HEAD
	volatile u32 *gpio_port;
	volatile u32 *gpio_pads;
	volatile u32 *gpio_clock;
} clock_object;

// distilled from https://raw.githubusercontent.com/mgrau/ad9959/master/minimal_clk.c
void gpioSetMode(volatile u32 *gpio_port, u32 gpio, u32 mode) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to change gpio mode using a NULL pointer (run with sudo?)...\n"); return; }
	u32 reg, shift;
	reg   =  gpio/10;
	shift = (gpio%10) * 3;
	gpio_port[reg] = (gpio_port[reg] & ~(7<<shift)) | (mode<<shift);
}

// distilled from https://raw.githubusercontent.com/mgrau/ad9959/master/minimal_clk.c
// this should do the same as initClock(1, 1, 50, 0, 0); // clock1=gpclk0, prefer PLLD, divI=50, divF=0, mash=0
void setup_clock10_on_gpclk0_gpio4(volatile u32 *gpio_port, volatile u32 *gpio_clock) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to setup clock output using a NULL pointer (run with sudo?)...\n"); return; }
	if (0==gpio_clock) { fprintf(warning, "cowardly refusing to setup clock output using a NULL pointer (run with sudo?)...\n"); return; }
	gpioSetMode(gpio_port, 4, PI_OUTPUT);
	gpio_clock[CLK_GP0_CTL] = CLK_PASSWD | CLK_CTL_KILL;
	while (gpio_clock[CLK_GP0_CTL] & CLK_CTL_BUSY) { myusleep(10); }
	gpio_clock[CLK_GP0_DIV] = CLK_PASSWD | CLK_DIV_DIVI(50) | CLK_DIV_DIVF(0);
	myusleep(10);
	gpio_clock[CLK_GP0_CTL] = CLK_PASSWD | CLK_CTL_MASH(0) | CLK_CTL_SRC(CLK_CTL_SRC_PLLD);
	myusleep(10);
	gpio_clock[CLK_GP0_CTL] |= CLK_PASSWD | CLK_CTL_ENAB;
	gpioSetMode(gpio_port, 4, PI_ALT0);
}

void terminate_clock10_on_gpclk0_gpio4(volatile u32 *gpio_port, volatile u32 *gpio_clock) {
	setup_DebugInfoWarningError_if_needed();
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to terminate clock output using a NULL pointer (run with sudo?)...\n"); return; }
	if (0==gpio_clock) { fprintf(warning, "cowardly refusing to terminate clock output using a NULL pointer (run with sudo?)...\n"); return; }
	gpioSetMode(gpio_port, 4, PI_OUTPUT);
	gpio_clock[CLK_GP0_CTL] = CLK_PASSWD | CLK_CTL_KILL;
	while (gpio_clock[CLK_GP0_CTL] & CLK_CTL_BUSY) { myusleep(10); }
}

static int init_clock(clock_object *self) {
	setup_DebugInfoWarningError_if_needed();
	self->gpio_port = mmap_bcm_gpio_register(GPIO_REGISTER_BASE);
	self->gpio_clock = mmap_bcm_register(CLK_BASE);
	setup_clock10_on_gpclk0_gpio4(self->gpio_port, self->gpio_clock);
	printf("clock initialized\n");
	return 0;
}

static PyObject *method_terminate(clock_object *self) {
	terminate_clock10_on_gpclk0_gpio4(self->gpio_port, self->gpio_clock);
	printf("clock terminated\n");
	return PyLong_FromLong(0);
}

//static PyMethodDef fastgpio_methods[] = {
static PyMethodDef clock_methods[] = {
	{ "terminate", (PyCFunction) method_terminate, METH_NOARGS, "terminate clock output" },
	{ "test", (PyCFunction) method_test, METH_NOARGS, "whatever code I'm testing at the moment" },
//	{ "", (PyCFunction) method_, METH_VARARGS, "" },
	{ NULL }
};

static PyTypeObject clock_type = {
	PyObject_HEAD_INIT(NULL)
	.tp_name = "fastgpio.clock",
	.tp_doc = "a clock object",
	.tp_basicsize = sizeof(clock_object),
	.tp_itemsize = 0,
	.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,
	.tp_new = PyType_GenericNew,
	.tp_init = (initproc) init_clock,
	.tp_methods = clock_methods,
};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

typedef struct {
	PyObject_HEAD
	u32 bus_mask;
	u32 partial_mask;
	u32 bus_width;
	u32 bus_offset;
	u32 transfers_per_data_word;
	u32 transfers_per_address_word;
	u32 register_select;
	u32 read;
	u32 enable;
	u32 ack_valid;
	u32 errors;
	u32 transactions;
	u32 retries;
	volatile u32 *gpio_port;
	volatile u32 *gpio_pads;
	volatile u32 *set_reg;
	volatile u32 *clr_reg;
	volatile u32 *read_port;
} half_duplex_bus_object;

static int init_half_duplex_bus(half_duplex_bus_object *self, PyObject *args, PyObject *kwds) {
	setup_DebugInfoWarningError_if_needed();
	u32 bus_offset = 0;
	u32 bus_width = 0;
	u32 transfers_per_data_word = 0;
	u32 transfers_per_address_word = 0;
	u32 register_select = 0;
	u32 read = 0;
	u32 enable = 0;
	u32 ack_valid = 0;
	// with help from https://gist.github.com/vuonghv/44dc334f3e116e32cc58d7a18b921fc3
	const char *format = "kkkkkkkk";
	static char *kwlist[] = { "bus_width", "bus_offset", "transfers_per_address_word", "transfers_per_data_word", "register_select", "read", "enable", "ack_valid", NULL };
	int success = PyArg_ParseTupleAndKeywords(args, kwds, format, kwlist, &bus_width, &bus_offset, &transfers_per_address_word, &transfers_per_data_word, &register_select, &read, &enable, &ack_valid);
	if (!success) { return -1; }
	if (bus_width<1 || 31<bus_width) { return -1; }
	self->bus_width = bus_width;
	//printf("bus_width: %08lx\n", self->bus_width);
	if (31<bus_offset) { return -1; }
	self->bus_offset = bus_offset;
	//printf("bus_offset: %08lx\n", self->bus_offset);
	if (0==transfers_per_data_word || 31<transfers_per_data_word) { return -1; }
	self->transfers_per_data_word = transfers_per_data_word;
	//printf("transfers_per_data_word: %08lx\n", self->transfers_per_data_word);
	if (0==transfers_per_address_word || 31<transfers_per_address_word) { return -1; }
	self->transfers_per_address_word = transfers_per_address_word;
	//printf("transfers_per_address_word: %08lx\n", self->transfers_per_address_word);
	if (31<register_select) { return -1; }
	self->register_select = 1<<register_select;
	//printf("register_select: %08lx\n", self->register_select);
	if (31<read) { return -1; }
	self->read = 1<<read;
	//printf("read: %08lx\n", self->read);
	if (31<enable) { return -1; }
	self->enable = 1<<enable;
	//printf("enable: %08lx\n", self->enable);
	if (31<ack_valid) { return -1; }
	self->ack_valid = 1<<ack_valid;
	//printf("ack_valid: %08lx\n", self->ack_valid);
	u32 bus_mask = 0;
	for (int i=0; i<bus_width; i++) {
		bus_mask |= 1<<(i+bus_offset);
	}
	self->bus_mask = bus_mask;
	//printf("bus_mask: %08lx\n", self->bus_mask);
	u32 partial_mask = 0;
	for (int i=0; i<bus_width; i++) {
		partial_mask |= 1<<i;
	}
	self->partial_mask = partial_mask;
	self->errors = 0;
	self->transactions = 0;
	self->retries = 0;
	//printf("partial_mask: %08lx\n", self->partial_mask);
	self->gpio_port = mmap_bcm_gpio_register(GPIO_REGISTER_BASE);
	self->gpio_pads = mmap_bcm_register(BCM2835_PADS_GPIO_0_27);
	self->set_reg = self->gpio_port + GPIO_SET_OFFSET;
	self->clr_reg = self->gpio_port + GPIO_CLR_OFFSET;
	self->read_port = self->gpio_port + GPIO_PIN_LEVEL;
	set_drive_strength_and_slew_rate(self->gpio_pads, 2); // 2 mA seems best
	return 0;
}

static void half_duplex_bus_destructor(half_duplex_bus_object *self) {
	if (self->errors) {
		printf("there were %ld total errors\n", self->errors);
	}
	if (self->transactions) {
		printf("there were %ld total transactions\n", self->transactions);
	}
	if (self->retries) {
		printf("there were %ld total retries\n", self->retries);
	}
	Py_TYPE(self)->tp_free((PyObject *) self);
}

// waiting for ack_valid is the difference between 2 MB/sec and 9 MB/sec
#define WAIT_FOR_ACK_STYLE_FOR
//#define WAIT_FOR_ACK_STYLE_WHILE
#define MAX_ACK_CYCLES_WARNING (3)
#define MAX_ACK_CYCLES_ERROR (4)
#define MAX_READBACK_CYCLES_ERROR (4)
#define MAX_RETRY_CYCLES_ERROR (4)

u32 set_address(half_duplex_bus_object *self, u32 address) {
	volatile u32 *set_reg = self->set_reg;
	volatile u32 *clr_reg = self->clr_reg;
	volatile u32 *read_port = self->read_port;
	u32 bus_mask = self->bus_mask;
	u32 bus_width = self->bus_width;
	u32 bus_offset = self->bus_offset;
	u32 partial_mask = self->partial_mask;
	u32 transfers_per_address_word = self->transfers_per_address_word;
	u32 register_select = self->register_select;
	u32 read = self->read;
	u32 enable = self->enable;
	u32 ack_valid = self->ack_valid;
	u32 new_errors = 0;
	u32 partial_address;
	u32 adjusted_address;
	u32 value, i, t;
	// write address
	//printf("address: %0*lx\n", (int) (transfers_per_address_word*bus_width/4), address);
	//for (t=0; t<transfers_per_address_word; t++) {
	*clr_reg = register_select | read | enable;
	for (t=0; t<1; t++) {
		partial_address = (address>>((transfers_per_address_word-t-1)*bus_width)) & partial_mask;
		//printf("partial_address: %0*lx\n", (int) bus_width/4, partial_address);
		adjusted_address = (partial_address<<bus_offset) & bus_mask;
		*clr_reg = bus_mask;
		*set_reg = adjusted_address;
		//printf("adjusted_address: %0*lx\n", bus_width/4, adjusted_address);
		//value = *read_port & ack_valid;
		//printf("value: %08lx\n", value);
		mynsleep(short_delay);
		*set_reg = enable;
		//mynsleep(short_delay);
		// wait for ack_valid
		#ifdef WAIT_FOR_ACK_STYLE_FOR
		for (i=0; i<MAX_ACK_CYCLES_ERROR; i++) {
			value = *read_port & ack_valid;
			//printf("value: %08lx\n", value);
			if (value) {
//				if (MAX_ACK_CYCLES_WARNING<i) {
//					printf("%d ", i);
//				}
				break;
			}
			mynsleep(short_delay);
		}
		if (MAX_ACK_CYCLES_ERROR==i) { new_errors++; }
		#else
		do { } while (!(*read_port & ack_valid));
		#endif
		mynsleep(short_delay);
		*clr_reg = enable;
		mynsleep(short_delay);
	}
	self->errors += new_errors;
	return new_errors;
}

u32 write_data(half_duplex_bus_object *self, u32 data) {
	volatile u32 *set_reg = self->set_reg;
	volatile u32 *clr_reg = self->clr_reg;
	volatile u32 *read_port = self->read_port;
	u32 bus_mask = self->bus_mask;
	u32 bus_width = self->bus_width;
	u32 bus_offset = self->bus_offset;
	u32 partial_mask = self->partial_mask;
	u32 transfers_per_data_word = self->transfers_per_data_word;
	u32 register_select = self->register_select;
	u32 read = self->read;
	u32 enable = self->enable;
	u32 ack_valid = self->ack_valid;
	u32 new_errors = 0;
	u32 partial_data;
	u32 adjusted_data;
	u32 value, i, t;
	u32 readback;
	// write data
	//printf("data to write: %0*lx\n", (int) (transfers_per_data_word*bus_width/4), data);
	*clr_reg = read | enable;
	*set_reg = register_select; // 1=data mode
	for (t=0; t<transfers_per_data_word; t++) {
		partial_data = (data>>((transfers_per_data_word-t-1)*bus_width)) & partial_mask;
		//printf("partial_data to write: %0*lx\n", (int) bus_width/4, partial_data);
		adjusted_data = (partial_data<<bus_offset) & bus_mask;
		//printf("adjusted_data to write: %0*lx\n", (int) (bus_width/4+1), adjusted_data);
		*clr_reg = bus_mask;
		*set_reg = adjusted_data;
		//mynsleep(short_delay);
		for (i=0; i<MAX_READBACK_CYCLES_ERROR; i++) {
			readback = (*read_port & bus_mask) >> bus_offset;
			if (readback == partial_data) {
				break;
			}
			mynsleep(short_delay);
		}
		if (MAX_READBACK_CYCLES_ERROR==i) {
			printf("can't set things right\n");
			new_errors++;
		}
		*set_reg = enable;
		mynsleep(short_delay);
		// wait for ack_valid
		#ifdef WAIT_FOR_ACK_STYLE_FOR
		for (i=0; i<MAX_ACK_CYCLES_ERROR; i++) {
			value = *read_port & ack_valid;
			//printf("value: %08lx\n", value);
			if (value) {
//				if (MAX_ACK_CYCLES_WARNING<i) {
//					printf("%d ", i);
//				}
				break;
			}
			mynsleep(short_delay);
		}
		if (MAX_ACK_CYCLES_ERROR==i) { new_errors++; }
		#else
		do { } while (!(*read_port & ack_valid));
		#endif
		mynsleep(short_delay);
		*clr_reg = enable;
		mynsleep(short_delay);
	}
	self->errors += new_errors;
	return new_errors;
}

u32 read_data(half_duplex_bus_object *self) {
	volatile u32 *gpio_port = self->gpio_port;
	volatile u32 *set_reg = self->set_reg;
	volatile u32 *clr_reg = self->clr_reg;
	volatile u32 *read_port = self->read_port;
	u32 bus_mask = self->bus_mask;
	u32 bus_width = self->bus_width;
	u32 bus_offset = self->bus_offset;
	u32 transfers_per_data_word = self->transfers_per_data_word;
	u32 read = self->read;
	u32 enable = self->enable;
	u32 ack_valid = self->ack_valid;
	u32 new_errors = 0;
	u32 partial_data0;//, partial_data1;
	u32 value, i, t;
	// readback data
	*clr_reg = enable;
	setup_bus_as_inputs(gpio_port, bus_mask);
	*set_reg = read;
	u32 data = 0;
	for (t=0; t<transfers_per_data_word; t++) {
		//partial_data = (data>>((transfers_per_data_word-t-1)*bus_width)) & partial_mask;
		//printf("partial_data: %0*lx\n", (int) bus_width/4, partial_data);
		//adjusted_data = (partial_data<<bus_offset) & bus_mask;
		//*set_reg = adjusted_data;
		//*clr_reg = bus_mask; // shouldn't need to do this...
		mynsleep(short_delay);
		*set_reg = enable;
		mynsleep(short_delay);
		// wait for ack_valid
		#ifdef WAIT_FOR_ACK_STYLE_FOR
		for (i=0; i<MAX_ACK_CYCLES_ERROR; i++) {
			value = *read_port;
			//printf("value: %08lx\n", value);
			if (value & ack_valid) {
				//if (MAX_ACK_CYCLES_WARNING<i) {
				//	printf("%d ", i);
				//}
				break;
			}
			mynsleep(short_delay);
		}
		if (MAX_ACK_CYCLES_ERROR==i) { new_errors++; }
		#else
		do { } while (!(*read_port & ack_valid));
		#endif
		mynsleep(short_delay);
		partial_data0 = (value & bus_mask)>>bus_offset;
//		partial_data1 = (*read_port & bus_mask)>>bus_offset;
//		if (partial_data0!=partial_data1) {
//			printf("data readpar0: %0*lx\n", (int) (bus_width/4), partial_data0);
//			printf("data readpar1: %0*lx\n", (int) (bus_width/4), partial_data1);
//		}
		data |= partial_data0 << ((transfers_per_data_word-t-1)*bus_width);
		*clr_reg = enable;
		//printf("partial_data readback: %0*lx\n", (int) (bus_width/4), partial_data);
	}
	*clr_reg = read;
	setup_bus_as_outputs(gpio_port, bus_mask);
	//printf("data readback: %0*lx\n", (int) (transfers_per_data_word*bus_width/4), data);
	self->errors += new_errors;
	return data;
}

static PyObject* method_half_duplex_bus_write(half_duplex_bus_object *self, PyObject *args) {
	// borrowed from https://stackoverflow.com/a/22487015/5728815
	u32 start_address = 0;
	//u32 length = 0;
	bool verify = true;
	PyObject *obj;
	if (!PyArg_ParseTuple(args, "kO|p", &start_address, &obj, &verify)) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(start_address, iteratable_object)");
	}
	PyObject *iter = PyObject_GetIter(obj);
	if (!iter) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(start_address, iteratable_object)");
	}
	u32 bus_mask = self->bus_mask;
	u32 register_select = self->register_select;
	u32 read = self->read;
	u32 enable = self->enable;
	u32 address = start_address;
	u32 bus_width = self->bus_width;
	u32 transfers_per_data_word = self->transfers_per_data_word;
	int hex_width = transfers_per_data_word*bus_width/4;
	u32 data, data_readback;
	u32 everything = bus_mask | register_select | read | enable;
	u32 count = 0;
	u32 i;
	u32 new_errors = 0;
	volatile u32 *gpio_port = self->gpio_port;
	volatile u32 *clr_reg = self->clr_reg;
	*clr_reg = everything;
	setup_bus_as_outputs(gpio_port, bus_mask);
	u32 max_retry_cycles_error_var = 1;
	if (verify) {
		max_retry_cycles_error_var = MAX_RETRY_CYCLES_ERROR;
	}
	while (1) {
		PyObject *next = PyIter_Next(iter);
		if (!next) { break; }
		//if (length<=count) { break; }
		data = PyLong_AsUnsignedLong(next);
		self->transactions++;
		for (i=0; i<max_retry_cycles_error_var; i++) {
			set_address(self, address);
			write_data(self, data);
			data_readback = read_data(self);
			if (data == data_readback) {
				break;
			}
			//printf("didn't work the first time\n");
			self->retries++;
		}
		if (max_retry_cycles_error_var==i) {
			//printf("max_retry_cycles_error_var-1 = %ld\n", max_retry_cycles_error_var-1);
			//self->retries += max_retry_cycles_error_var - 1;
			new_errors++;
			printf("data written (%0*lx) does not match data read back (%0*lx)\n", hex_width, data, hex_width, data_readback);
		}
		if (0) {
			if (0==count%10240) {
				mynsleep(short_delay);
			}
		}
		//address += len(u32);
		count++;
		address++;
	}
	*clr_reg = everything;
	//printf("completed %ld transactions\n", count);
//	if (new_errors) {
//		printf("there were %ld new errors\n", new_errors);
//	}
	self->errors += new_errors;
	return PyLong_FromLong(count);
}

static PyObject* method_half_duplex_bus_read(half_duplex_bus_object *self, PyObject *args) {
	// borrowed from https://stackoverflow.com/a/22487015/5728815
	u32 start_address = 0;
	u32 length = 1;
	if (!PyArg_ParseTuple(args, "k|k", &start_address, &length)) {
		return PyErr_Format(PyExc_ValueError, "usage:  read(start_address, length)");
	}
	u32 bus_mask = self->bus_mask;
	u32 register_select = self->register_select;
	u32 read = self->read;
	u32 enable = self->enable;
	u32 address = start_address;
	u32 data;
	volatile u32 *clr_reg = self->clr_reg;
	u32 everything = bus_mask | register_select | read | enable;
	*clr_reg = everything;
	u32 index = 0;
//	u32 new_errors = 0;
	PyObject *obj = PyList_New(0);
	while (1) {
		if (length<=index) { break; }
		self->transactions++;
		set_address(self, address);
		data = read_data(self);
		PyList_Append(obj, PyLong_FromLong(data));
		index++;
	}
	*clr_reg = everything;
	u32 other_length = PyList_Size(obj);
	if (length!=other_length) {
		printf("lengths don't match\n");
	}
	if (index<length) {
		printf("didn't get 'em all\n");
	}
//	if (new_errors) {
//		printf("there were %ld new errors\n", new_errors);
//	}
//	self->errors += new_errors;
	return obj;
}

//static PyMethodDef fastgpio_methods[] = {
static PyMethodDef half_duplex_bus_methods[] = {
	{ "write", (PyCFunction) method_half_duplex_bus_write, METH_VARARGS, "writes iteratable_object to the interface" },
	{ "read", (PyCFunction) method_half_duplex_bus_read, METH_VARARGS, "reads from the interface" },
//	{ "", (PyCFunction) method_, METH_VARARGS, "" },
	{ NULL }
};

static PyTypeObject half_duplex_bus_type = {
	PyObject_HEAD_INIT(NULL)
	.tp_name = "fastgpio.half_duplex_bus",
	.tp_doc = "a half_duplex_bus object",
	.tp_basicsize = sizeof(half_duplex_bus_object),
	.tp_itemsize = 0,
	.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,
	.tp_new = PyType_GenericNew,
	.tp_init = (initproc) init_half_duplex_bus,
	.tp_dealloc = (destructor) half_duplex_bus_destructor,
	.tp_methods = half_duplex_bus_methods,
};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

typedef struct {
	PyObject_HEAD
	u32 mask;
	u8 direction;
	u8 offset;
	volatile u32 *gpio_port;
	volatile u32 *gpio_pads;
} bus_object;

static int init_anubis(bus_object *self, PyObject *args, PyObject *kwds) {
	setup_DebugInfoWarningError_if_needed();
	//self->mask;
	u32 mask = 0;
	u32 direction = 1;
	u32 offset = 0;
	if (!PyArg_ParseTuple(args, "k|kk", &mask, &direction, &offset)) {
		//return PyErr_Format(PyExc_ValueError, "usage:  anubis(mask, direction=1)");
		return -1;
	}
	//printf("%08lx\n", mask);
	//printf("direction: %ld\n", direction);
	//printf("offset: %ld\n", offset);
//	if (offset) {
//		mask <<= offset;
//	}
	self->mask = mask;
	self->direction = direction;
	self->offset = offset;
	self->gpio_port = mmap_bcm_gpio_register(GPIO_REGISTER_BASE);
	self->gpio_pads = mmap_bcm_register(BCM2835_PADS_GPIO_0_27);
	if (direction) {
		setup_bus_as_outputs(self->gpio_port, mask);
	} else {
		setup_bus_as_inputs(self->gpio_port, mask);
	}
	set_drive_strength_and_slew_rate(self->gpio_pads, 2); // 2 mA seems best
	// according to looking at traces on a MSOX6004A and noting the overshoot on any higher value
	//show_a_block_of_registers(self->gpio_port, GPIO_REGISTER_MAX);
	return 0;
}

static PyObject* method_set_drive_strength(bus_object *self, PyObject *args) {
	u32 value;
	if (!PyArg_ParseTuple(args, "k", &value)) {
		return PyErr_Format(PyExc_ValueError, "usage:  change_drive_strength(number_of_milliamps)");
	}
	set_drive_strength_and_slew_rate(self->gpio_pads, (u8) value);
	return PyLong_FromLong(value);
}

static PyObject* method_write(bus_object *self, PyObject *args) {
	// borrowed from https://stackoverflow.com/a/22487015/5728815
	PyObject *obj;
	if (!PyArg_ParseTuple(args, "O", &obj)) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(iteratable_object)");
	}
	PyObject *iter = PyObject_GetIter(obj);
	if (!iter) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(iteratable_object)");
	}
	volatile u32 *set_reg = self->gpio_port + GPIO_SET_OFFSET;
	volatile u32 *clr_reg = self->gpio_port + GPIO_CLR_OFFSET;
	u32 mask = self->mask;
	u8 offset = self->offset;
	u32 value = 0;
//	u32 old_value = 0;
//	*clr_reg = (~old_value) & mask;
	*clr_reg = mask;
	u32 count = 0;
//	struct timespec short_delay = { 0, 1 }; // seconds, nanoseconds
#define ALE (22)
	//*clr_reg = 1<<ALE;
	*set_reg = 1<<ALE;
	while (1) {
		PyObject *next = PyIter_Next(iter);
		if (!next) {
			break;
		}
		value = PyLong_AsUnsignedLong(next);
		//printf("%08lx %08lx\n", value, mask);
//		value <<= offset;
//		value &= mask;
		value = (value<<offset) & mask;
		//value = value & mask;
//		if (0) {
//			*clr_reg = (~old_value) & mask;
//		} else {
		*clr_reg = mask;
		//*clr_reg = mask | (1<<ALE);
//		}
//		*clr_reg = 1<<ALE;
		*set_reg = value;
		//mynsleep(short_delay);
		//*set_reg = 1<<ALE;
		count++;
//		*clr_reg = value;
//		old_value = value;
		if (0) {
			if (0==count%10240) {
				mynsleep(short_delay);
			}
		}
	}
	//printf("%ld\n", count);
//	value = *set_reg;
//	printf("%08lx:%08lx\n", (u32) set_reg, value);
//	*set_reg = 0xffffffff && mask;
//	printf("%08lx:%08lx\n", (u32) set_reg, *set_reg);
//	*clr_reg = 0;
//	printf("%08lx:%08lx\n", (u32) clr_reg, *clr_reg);
	*clr_reg = 1<<ALE;
	return PyLong_FromLong(count);
}

//static PyMethodDef fastgpio_methods[] = {
static PyMethodDef bus_methods[] = {
	{ "write", (PyCFunction) method_write, METH_VARARGS, "writes iteratable_object to the interface" },
	{ "set_drive_strength", (PyCFunction) method_set_drive_strength, METH_VARARGS, "sets the drive strength of gpios 0-27" },
	{ "test", (PyCFunction) method_test, METH_VARARGS, "whatever code I'm testing at the moment" },
//	{ "", (PyCFunction) method_, METH_VARARGS, "" },
	{ NULL }
};

static PyTypeObject bus_type = {
	PyObject_HEAD_INIT(NULL)
	.tp_name = "fastgpio.bus",
	.tp_doc = "a bus object",
	.tp_basicsize = sizeof(bus_object),
	.tp_itemsize = 0,
	.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,
//	.tp_new = new_anubis,
	.tp_new = PyType_GenericNew,
	.tp_init = (initproc) init_anubis,
	.tp_methods = bus_methods,
};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

static PyObject* method_test(PyObject *self, PyObject *args) {
	printf("starting test...\n");
	if (1) {
		FILE *devnull_FILE = fopen("/dev/null",   "w");
		fprintf(devnull_FILE, "blah");
	}
	if (0) {
		myusleep(1);
		myusleep(1000);
		myusleep(999999);
		myusleep(1000000);
		myusleep(9999999);
		myusleep(10000000);
	}
	if (0) {
		volatile u32 *gpio_port = mmap_bcm_gpio_register(GPIO_REGISTER_BASE);
		volatile u32 *gpio_clock = mmap_bcm_register(CLK_BASE);
		setup_clock10_on_gpclk0_gpio4(gpio_port, gpio_clock);
	}
	printf("test completed\n");
	return PyLong_FromLong(0);
}

static struct PyModuleDef fastgpio_module = {
	PyModuleDef_HEAD_INIT,
	.m_name = "fastgpio",
	.m_doc = "hopefully a faster type of gpio than the standard lot",
	.m_size = -1,
//	.m_methods = fastgpio_methods,
};

PyMODINIT_FUNC PyInit_fastgpio(void) {
	PyObject *m;
	if (PyType_Ready(&clock_type) < 0) { return NULL; }
	if (PyType_Ready(&bus_type) < 0) { return NULL; }
	if (PyType_Ready(&half_duplex_bus_type) < 0) { return NULL; }
	m = PyModule_Create(&fastgpio_module);
	if (m == NULL) { return NULL; }
	Py_INCREF(&clock_type);
	if (PyModule_AddObject(m, "clock", (PyObject *) &clock_type) < 0) {
		Py_DECREF(&clock_type);
		Py_DECREF(m);
		return NULL;
	}
	Py_INCREF(&bus_type);
	if (PyModule_AddObject(m, "bus", (PyObject *) &bus_type) < 0) {
		Py_DECREF(&bus_type);
		Py_DECREF(m);
		return NULL;
	}
	Py_INCREF(&half_duplex_bus_type);
	if (PyModule_AddObject(m, "half_duplex_bus", (PyObject *) &half_duplex_bus_type) < 0) {
		Py_DECREF(&half_duplex_bus_type);
		Py_DECREF(m);
		return NULL;
	}
	return m;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

