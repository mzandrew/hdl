// written 2020-06-05 by mza
// merged a modified version of code from https://github.com/hzeller/rpi-gpio-dma-demo/blob/master/gpio-dma-test.c
// with modification of example code from https://realpython.com/build-python-c-extension-module/
// with help from https://docs.python.org/3.7/extending/newtypes_tutorial.html
// last updated 2020-06-20 by mza

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
//			printf("bit %d\n", i);
			initialize_gpio_for_input(gpio_port, i);
		}
	}
}

void initialize_gpios_for_output(volatile u32 *gpio_port, u32 mask) {
	if (0==gpio_port) { fprintf(warning, "cowardly refusing to change gpio mode using a NULL pointer (run with sudo?)...\n"); return; }
	for (int i=0; i<32; i++) {
		u32 bit = 1<<i;
		if (bit&mask) {
//			printf("bit %d\n", i);
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
	u32 bus_width;
	u32 bus_offset;
	u32 transfers_per_word;
	u32 register_select;
	u32 read;
	u32 enable;
	u32 ack;
	volatile u32 *gpio_port;
	volatile u32 *gpio_pads;
} half_duplex_bus_object;

static int init_half_duplex_bus(half_duplex_bus_object *self, PyObject *args, PyObject *kwds) {
	setup_DebugInfoWarningError_if_needed();
	u32 bus_offset = 0;
	u32 bus_width = 0;
	u32 transfers_per_word = 0;
	u32 register_select = 0;
	u32 read = 0;
	u32 enable = 0;
	u32 ack = 0;
	// with help from https://gist.github.com/vuonghv/44dc334f3e116e32cc58d7a18b921fc3
	const char *format = "kkkkkkk";
	static char *kwlist[] = { "bus_width", "bus_offset", "transfers_per_word", "register_select", "read", "enable", "ack", NULL };
	int success = PyArg_ParseTupleAndKeywords(args, kwds, format, kwlist, &bus_width, &bus_offset, &transfers_per_word, &register_select, &read, &enable, &ack);
	if (!success) { return -1; }
	if (bus_width<1 || 31<bus_width) { return -1; }
	self->bus_width = bus_width;
	if (31<bus_offset) { return -1; }
	self->bus_offset = bus_offset;
	if (0==transfers_per_word || 31<transfers_per_word) { return -1; }
	self->transfers_per_word = transfers_per_word;
	if (31<register_select) { return -1; }
	self->register_select = 1<<register_select;
	if (31<read) { return -1; }
	self->read = 1<<read;
	if (31<enable) { return -1; }
	self->enable = 1<<enable;
	if (31<ack) { return -1; }
	self->ack = 1<<ack;
	u32 bus_mask = 0;
	for (int i=0; i<bus_width; i++) {
		bus_mask |= 1<<(i+bus_offset);
	}
	self->bus_mask = bus_mask;
	//printf("bus_mask: %08lx\n", self->bus_mask);
	self->gpio_port = mmap_bcm_gpio_register(GPIO_REGISTER_BASE);
	self->gpio_pads = mmap_bcm_register(BCM2835_PADS_GPIO_0_27);
	set_drive_strength_and_slew_rate(self->gpio_pads, 2); // 2 mA seems best
	return 0;
}

static PyObject* method_half_duplex_bus_write(half_duplex_bus_object *self, PyObject *args) {
	// borrowed from https://stackoverflow.com/a/22487015/5728815
	u32 start_address = 0;
	u32 length = 0;
	PyObject *obj;
	if (!PyArg_ParseTuple(args, "kkO", &start_address, &length, &obj)) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(start_address, length, iteratable_object)");
	}
	PyObject *iter = PyObject_GetIter(obj);
	if (!iter) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(start_address, length, iteratable_object)");
	}
	u32 bus_mask = self->bus_mask;
	u32 bus_offset = self->bus_offset;
	u32 register_select = self->register_select;
	u32 read = self->read;
	u32 enable = self->enable;
	u32 address = start_address;
	u32 data;
	u32 adjusted_address;
	u32 adjusted_data;
	volatile u32 *set_reg = self->gpio_port + GPIO_SET_OFFSET;
	volatile u32 *clr_reg = self->gpio_port + GPIO_CLR_OFFSET;
	u32 everything = bus_mask | register_select | read | enable;
	*clr_reg = everything;
	u32 count = 0;
	while (1) {
		PyObject *next = PyIter_Next(iter);
		if (!next) { break; }
		if (length<count) { break; }
		data = PyLong_AsUnsignedLong(next);
		//printf("%08lx %08lx\n", data, mask);
		// write address
		adjusted_address = (address<<bus_offset) & bus_mask;
		*clr_reg = everything;
		*set_reg = adjusted_address;
		*set_reg = enable;
		// wait for ack
		*clr_reg = enable;
		// write data
		adjusted_data = (data<<bus_offset) & bus_mask;
		*clr_reg = everything;
		*set_reg = adjusted_data | register_select;
		*set_reg = enable;
		// wait for ack
		*clr_reg = enable;
		count++;
		//address += len(u32);
		address++;
//		if (0==count%1024) {
//			nanosleep(&long_delay, NULL);
//		}
	}
	*clr_reg = everything;
	return PyLong_FromLong(count);
}

//static PyMethodDef fastgpio_methods[] = {
static PyMethodDef half_duplex_bus_methods[] = {
	{ "write", (PyCFunction) method_half_duplex_bus_write, METH_VARARGS, "writes iteratable_object to the interface" },
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
	struct timespec long_delay = { 0, 1000 }; // seconds, nanoseconds
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
//		nanosleep(&short_delay, NULL);
		//*set_reg = 1<<ALE;
		count++;
//		*clr_reg = value;
//		old_value = value;
		if (0==count%1024) {
			nanosleep(&long_delay, NULL);
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

