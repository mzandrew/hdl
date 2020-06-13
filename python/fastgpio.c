// written 2020-06-05 by mza
// merged a modified version of code from https://github.com/hzeller/rpi-gpio-dma-demo/blob/master/gpio-dma-test.c
// with modification of example code from https://realpython.com/build-python-c-extension-module/
// with help from https://docs.python.org/3.7/extending/newtypes_tutorial.html
// last updated 2020-06-13 by mza

// how to use this module:
//	import fastgpio
//	mask = 0xfff
//	output_bus = fastgpio.bus(mask, 1, 0)
//	data = [0xaaa, 0x555, 0xfff, 0x000]
//	output_bus.write(data)

typedef unsigned char u8;
typedef unsigned long u32;

#include <stdio.h> // printf
#include <stdlib.h> // srandom, random
#include <time.h> // nanosleep
#include <fcntl.h> // open
#include <sys/mman.h> // mmap
#include <Python.h>
#include <bcm_host.h> // bcm_host_get_peripheral_address -I/opt/vc/include -L/opt/vc/lib -lbcm_host

// ---- GPIO specific defines
//#define PERI_BASE (0x20000000)
#define GPIO_REGISTER_BASE (0x200000)
#define GPIO_SET_OFFSET (0x1C/sizeof(u32))
#define GPIO_CLR_OFFSET (0x28/sizeof(u32))
#define GPIO_PIN_LEVEL  (0x34/sizeof(u32))
#define GPIO_REGISTER_MAX (0xb0/sizeof(u32))
#define BCM2835_PADS_GPIO_0_27 (0x100000)
#define BCM2835_PADS_GPIO_0_27_OFFSET (0x2c/sizeof(u32))
#define BCM2835_PADS_GPIO_MAX         (0x40/sizeof(u32))

void show_a_block_of_registers(volatile u32 *start, u32 count) {
	if (0==start) { return; }
	u32 value;
	for (u32 i=0; i<count+1; i++) {
		value = start[i];
		printf("%08lx:%08lx\n", (u32) &start[i], value); // read-only registers return 0x6770696f "gpio"
	}
}

// Return a pointer to a periphery subsystem register.
static void *mmap_bcm_gpio_register(off_t register_offset) {
	// from openocd's src/jtag/drivers/bcm2835gpio.c
	// and from https://elinux.org/Rpi_Datasheet_751_GPIO_Registers
	int dev_mem_fd = open("/dev/gpiomem", O_RDWR | O_SYNC);
	if (dev_mem_fd < 0) {
		printf("Cannot open /dev/gpiomem, fallback to /dev/mem\n");
		dev_mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
		if (dev_mem_fd < 0) {
			perror("can't open /dev/mem: ");
			fprintf(stderr, "You need to run this as root!\n");
			return NULL;
		}
	}
	//const off_t base = PERI_BASE;
	const off_t base = bcm_host_get_peripheral_address(); // https://www.raspberrypi.org/documentation/hardware/raspberrypi/peripheral_addresses.md
	printf("base+register_offset: %08lx\n", base + register_offset);
	u32 *result =
		(u32*) mmap(NULL,                  // Any adddress in our space will do
		                 sysconf(_SC_PAGE_SIZE),
		                 PROT_READ|PROT_WRITE,  // Enable r/w on GPIO registers.
		                 MAP_SHARED,
		                 dev_mem_fd,                // File to map
		                 base + register_offset // Offset to bcm register
		                 );
	close(dev_mem_fd);
	if (result == MAP_FAILED) {
		fprintf(stderr, "mmap error %p\n", result);
		return NULL;
	}
	return result;
}

// Return a pointer to a periphery subsystem register.
static void *mmap_bcm_register(off_t register_offset) {
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
	printf("base+register_offset: %08lx\n", base + register_offset);
	u32 *result =
		(u32*) mmap(NULL,                  // Any adddress in our space will do
		                 sysconf(_SC_PAGE_SIZE),
		                 PROT_READ|PROT_WRITE,  // Enable r/w on GPIO registers.
		                 MAP_SHARED,
		                 dev_mem_fd,                // File to map
		                 base + register_offset // Offset to bcm register
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
	if (0==gpio_pads) { return; }
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

void initialize_gpio_for_input(volatile u32 *gpio_port, int bit) {
	*(gpio_port+(bit/10)) &= ~(7<<((bit%10)*3));  // prepare: set as input
}

void initialize_gpio_for_output(volatile u32 *gpio_port, int bit) {
	*(gpio_port+(bit/10)) &= ~(7<<((bit%10)*3));  // prepare: set as input
	*(gpio_port+(bit/10)) |=  (1<<((bit%10)*3));  // set as output.
}

void initialize_gpios_for_input(volatile u32 *gpio_port, u32 mask) {
	for (int i=0; i<32; i++) {
		u32 bit = 1<<i;
		if (bit&&mask) {
			initialize_gpio_for_input(gpio_port, i);
		}
	}
}

void initialize_gpios_for_output(volatile u32 *gpio_port, u32 mask) {
	for (int i=0; i<32; i++) {
		u32 bit = 1<<i;
		if (bit&&mask) {
			initialize_gpio_for_output(gpio_port, i);
		}
	}
}

void setup_bus_as_inputs(volatile u32 *gpio_port, u32 mask) {
	//printf("%08lx\n", mask);
	initialize_gpios_for_input(gpio_port, mask);
}

void setup_bus_as_outputs(volatile u32 *gpio_port, u32 mask) {
	//printf("%08lx\n", mask);
	initialize_gpios_for_output(gpio_port, mask);
}

typedef struct {
	PyObject_HEAD
	u32 mask;
	u8 direction;
	u8 offset;
	volatile u32 *gpio_port;
	volatile u32 *gpio_pads;
} bus_object;

static int init_anubis(bus_object *self, PyObject *args, PyObject *kwds) {
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
//	{ "", (PyCFunction) method_, METH_VARARGS, "" },
	{ NULL }
};

static struct PyModuleDef fastgpio_module = {
	PyModuleDef_HEAD_INIT,
	.m_name = "fastgpio",
	.m_doc = "hopefully a faster type of gpio than the standard lot",
	.m_size = -1,
//	.m_methods = fastgpio_methods,
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

PyMODINIT_FUNC PyInit_fastgpio(void) {
	PyObject *m;
	if (PyType_Ready(&bus_type) < 0) {
		return NULL;
	}
	m = PyModule_Create(&fastgpio_module);
	if (m == NULL) {
		return NULL;
	}
	Py_INCREF(&bus_type);
	if (PyModule_AddObject(m, "bus", (PyObject *) &bus_type) < 0) {
		Py_DECREF(&bus_type);
		Py_DECREF(m);
		return NULL;
	}
	return m;
}

