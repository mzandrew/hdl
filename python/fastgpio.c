// written 2020-06-05 by mza
// merged a modified version of code from https://github.com/hzeller/rpi-gpio-dma-demo/blob/master/gpio-dma-test.c
// with modification of example code from https://realpython.com/build-python-c-extension-module/
// last updated 2020-06-05 by mza

#include <stdio.h> // printf
#include <stdlib.h> // srandom, random
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

typedef unsigned long u32;

void initialize_gpio_for_output(volatile uint32_t *gpio_registerset, int bit) {
	*(gpio_registerset+(bit/10)) &= ~(7<<((bit%10)*3));  // prepare: set as input
	*(gpio_registerset+(bit/10)) |=  (1<<((bit%10)*3));  // set as output.
}

void initialize_gpios_for_output(volatile uint32_t *gpio_registerset, u32 mask) {
	for (int i=0; i<32; i++) {
		if ((1<<i)&&mask) {
			initialize_gpio_for_output(gpio_registerset, i);
		}
	}
}

void run_cpu_direct(u32 mask) {
	// Prepare GPIO
	volatile uint32_t *gpio_port = mmap_bcm_register(GPIO_REGISTER_BASE);
	initialize_gpios_for_output(gpio_port, mask);
	volatile uint32_t *set_reg = gpio_port + (GPIO_SET_OFFSET / sizeof(uint32_t));
	volatile uint32_t *clr_reg = gpio_port + (GPIO_CLR_OFFSET / sizeof(uint32_t));
	// Do it. Endless loop, directly setting.
	printf("1) CPU: Writing to GPIO directly in tight loop\n"
	       "== Press Ctrl-C to exit.\n");
	for (;;) {
		*clr_reg = mask;
		*set_reg = mask;
	}
}

// import fastgpio
// fastgpio.setup_bus_as_outputs(0xffff0000)
// fastgpio.write_word(0x12345678, 0xffff0000)
//
// import fastgpio
// fastgpio.setup_bus_as_outputs(0x0000ffff)
// fastgpio.write([0xffff, 0x5555, 0xaaaa, 0x0000, 0xaf50], 0x0000ffff)

static PyObject* method_setup_bus_as_outputs(PyObject *self, PyObject *args) {
	u32 mask;
	if (!PyArg_ParseTuple(args, "k", &mask)) {
		return PyErr_Format(PyExc_ValueError, "usage:  setup_bus_as_outputs(mask)");
	}
	volatile uint32_t *gpio_port = mmap_bcm_register(GPIO_REGISTER_BASE);
	//printf("%08lx\n", mask);
	initialize_gpios_for_output(gpio_port, mask);
	return PyLong_FromLong(0);
}

static PyObject* method_write_word(PyObject *self, PyObject *args) {
	u32 value;
	u32 mask;
	if (!PyArg_ParseTuple(args, "kk", &value, &mask)) {
		return PyErr_Format(PyExc_ValueError, "usage:  write_word(value, mask)");
	}
	volatile uint32_t *gpio_port = mmap_bcm_register(GPIO_REGISTER_BASE);
	volatile uint32_t *set_reg = gpio_port + (GPIO_SET_OFFSET / sizeof(uint32_t));
	volatile uint32_t *clr_reg = gpio_port + (GPIO_CLR_OFFSET / sizeof(uint32_t));
	//printf("%08lx %08lx\n", value, mask);
	*clr_reg = mask;
	*set_reg = mask;
	return PyLong_FromLong(0);
}

//#define N (10000)
//static PyObject* method_write_block_of_pseudorandom_data(PyObject *self, PyObject *args) {
// srandom();
// random();
//	u32 *data = (u32*) malloc(N*sizeof(*u32));
static PyObject* method_write(PyObject *self, PyObject *args) {
	// borrowed from https://stackoverflow.com/a/22487015/5728815
	PyObject *obj;
	u32 mask;
	if (!PyArg_ParseTuple(args, "Ok", &obj, &mask)) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(iteratable_object, mask)");
	}
	PyObject *iter = PyObject_GetIter(obj);
	if (!iter) {
		return PyErr_Format(PyExc_ValueError, "usage:  write(iteratable_object, mask)");
	}
	u32 value;
	volatile uint32_t *gpio_port = mmap_bcm_register(GPIO_REGISTER_BASE);
	volatile uint32_t *set_reg = gpio_port + (GPIO_SET_OFFSET / sizeof(uint32_t));
	volatile uint32_t *clr_reg = gpio_port + (GPIO_CLR_OFFSET / sizeof(uint32_t));
	u32 count = 0;
	while (1) {
		PyObject *next = PyIter_Next(iter);
		if (!next) {
			break;
		}
		value = PyLong_AsUnsignedLong(next);
		//printf("%08lx %08lx\n", value, mask);
		value &= mask;
		*clr_reg = value;
		*set_reg = value;
		count++;
	}
	//printf("%ld\n", count);
	return PyLong_FromLong(count);
}

static PyMethodDef fastgpio_methods[] = {
	{ "setup_bus_as_outputs", method_setup_bus_as_outputs, METH_VARARGS, "sets up the gpios in the mask as outputs" },
	{ "write_word", method_write_word, METH_VARARGS, "writes a single word to the interface" },
	{ "write", method_write, METH_VARARGS, "writes iteratable_object to the interface" },
	{ NULL, NULL, 0, NULL }
};

static struct PyModuleDef fastgpio_module = {
	PyModuleDef_HEAD_INIT,
	"method_fastgpio",
	"hopefully a faster type of gpio than the standard lot",
	-1,
	fastgpio_methods
};

PyMODINIT_FUNC PyInit_fastgpio(void) {
	return PyModule_Create(&fastgpio_module);
};

