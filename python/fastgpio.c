// written 2020-06-05 by mza
// merged a modified version of code from https://github.com/hzeller/rpi-gpio-dma-demo/blob/master/gpio-dma-test.c
// with modification of example code from https://realpython.com/build-python-c-extension-module/
// with help from https://docs.python.org/3.7/extending/newtypes_tutorial.html
// last updated 2020-06-09 by mza

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

// Raspberry Pi 2 or 1 ? Since this is a simple example, we don't
// bother auto-detecting but have it a compile-time option.
#ifndef PI_VERSION
#  define PI_VERSION 2
#endif

#define BCM2708_PI1_PERI_BASE  0x20000000
#define BCM2709_PI2_PERI_BASE  0x3F000000
#define BCM2711_PI4_PERI_BASE  0xFE000000

// --- General, Pi-specific setup.
#if PI_VERSION == 1
#  define PERI_BASE BCM2708_PI1_PERI_BASE
#elif PI_VERSION == 2 || PI_VERSION == 3
#  define PERI_BASE BCM2709_PI2_PERI_BASE
#else
#  define PERI_BASE BCM2711_PI4_PERI_BASE
#endif

#define PAGE_SIZE 4096

// ---- GPIO specific defines
#define GPIO_REGISTER_BASE 0x200000
#define GPIO_SET_OFFSET 0x1C
#define GPIO_CLR_OFFSET 0x28
#define PHYSICAL_GPIO_BUS (0x7E000000 + GPIO_REGISTER_BASE)

// Return a pointer to a periphery subsystem register.
static void *mmap_bcm_register(off_t register_offset) {
	const off_t base = PERI_BASE;
	int mem_fd;
	if ((mem_fd = open("/dev/mem", O_RDWR|O_SYNC) ) < 0) {
		perror("can't open /dev/mem: ");
		fprintf(stderr, "You need to run this as root!\n");
		return NULL;
	}
	uint32_t *result =
		(uint32_t*) mmap(NULL,                  // Any adddress in our space will do
		                 PAGE_SIZE,
		                 PROT_READ|PROT_WRITE,  // Enable r/w on GPIO registers.
		                 MAP_SHARED,
		                 mem_fd,                // File to map
		                 base + register_offset // Offset to bcm register
		                 );
	close(mem_fd);
	if (result == MAP_FAILED) {
		fprintf(stderr, "mmap error %p\n", result);
		return NULL;
	}
	return result;
}

void initialize_gpio_for_input(volatile uint32_t *gpio_registerset, int bit) {
	*(gpio_registerset+(bit/10)) &= ~(7<<((bit%10)*3));  // prepare: set as input
}

void initialize_gpio_for_output(volatile uint32_t *gpio_registerset, int bit) {
	*(gpio_registerset+(bit/10)) &= ~(7<<((bit%10)*3));  // prepare: set as input
	*(gpio_registerset+(bit/10)) |=  (1<<((bit%10)*3));  // set as output.
}

void initialize_gpios_for_input(volatile uint32_t *gpio_registerset, u32 mask) {
	for (int i=0; i<32; i++) {
		u32 bit = 1<<i;
		if (bit&&mask) {
			initialize_gpio_for_input(gpio_registerset, i);
		}
	}
}

void initialize_gpios_for_output(volatile uint32_t *gpio_registerset, u32 mask) {
	for (int i=0; i<32; i++) {
		u32 bit = 1<<i;
		if (bit&&mask) {
			initialize_gpio_for_output(gpio_registerset, i);
		}
	}
}

void setup_bus_as_inputs(u32 mask) {
	volatile uint32_t *gpio_port = mmap_bcm_register(GPIO_REGISTER_BASE);
	//printf("%08lx\n", mask);
	initialize_gpios_for_input(gpio_port, mask);
}

void setup_bus_as_outputs(u32 mask) {
	volatile uint32_t *gpio_port = mmap_bcm_register(GPIO_REGISTER_BASE);
	//printf("%08lx\n", mask);
	initialize_gpios_for_output(gpio_port, mask);
}

typedef struct {
	PyObject_HEAD
	u32 mask;
	u8 direction;
	u8 offset;
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
	if (direction) {
		setup_bus_as_outputs(mask);
	} else {
		setup_bus_as_inputs(mask);
	}
	self->mask = mask;
	self->direction = direction;
	self->offset = offset;
	return 0;
}

static PyObject* method_write(bus_object *self, PyObject *args) {
	// borrowed from https://stackoverflow.com/a/22487015/5728815
	PyObject *obj;
//	u32 mask;
	//if (!PyArg_ParseTuple(args, "Ok", &obj, &mask)) {
	if (!PyArg_ParseTuple(args, "O", &obj)) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(iteratable_object)");
	}
	PyObject *iter = PyObject_GetIter(obj);
	if (!iter) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(iteratable_object)");
	}
	volatile uint32_t *gpio_port = mmap_bcm_register(GPIO_REGISTER_BASE);
	volatile uint32_t *set_reg = gpio_port + (GPIO_SET_OFFSET / sizeof(uint32_t));
	volatile uint32_t *clr_reg = gpio_port + (GPIO_CLR_OFFSET / sizeof(uint32_t));
	u32 mask = self->mask;
	u8 offset = self->offset;
	u32 value = 0;
//	u32 old_value = 0;
//	*clr_reg = (~old_value) & mask;
	*clr_reg = mask;
	u32 count = 0;
	struct timespec short_delay = { 0, 1 }; // seconds, nanoseconds
	struct timespec long_delay = { 0, 1000 }; // seconds, nanoseconds
	*clr_reg = 1<<22; // fake address/data latch signal
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
//		if (0) {
//			*clr_reg = (~old_value) & mask;
//		} else {
		*clr_reg = mask | (1<<22); // fake address/data latch signal
//		}
//		*clr_reg = 1<<22; // fake address/data latch signal
		*set_reg = value;
//		nanosleep(&short_delay, NULL);
		*set_reg = 1<<22; // fake address/data latch signal
		count++;
//		*clr_reg = value;
//		old_value = value;
		if (0==count%1024) {
			nanosleep(&long_delay, NULL);
		}
	}
	//printf("%ld\n", count);
	return PyLong_FromLong(count);
}

//static PyMethodDef fastgpio_methods[] = {
static PyMethodDef bus_methods[] = {
	{ "write", (PyCFunction) method_write, METH_VARARGS, "writes iteratable_object to the interface" },
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

