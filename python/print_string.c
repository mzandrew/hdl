// written 2020-06-05 by mza
// based on example code from https://realpython.com/build-python-c-extension-module/
// last updated 2020-06-05 by mza

#include <stdio.h>
#include <Python.h>

static PyObject* method_print_string(PyObject *self, PyObject *args) {
	char *string;
	if (!PyArg_ParseTuple(args, "s", &string)) {
		return NULL;
	}
	printf("%s\n", string);
	return PyLong_FromLong(7);
}

static PyMethodDef print_string_methods[] = {
	{ "print_string", method_print_string, METH_VARARGS, "a string to describe the method" },
	{ NULL, NULL, 0, NULL }
};

static struct PyModuleDef print_string_module = {
	PyModuleDef_HEAD_INIT,
	"method_print_string",
	"a string describing the module",
	-1,
	print_string_methods
};

PyMODINIT_FUNC PyInit_print_string(void) {
	return PyModule_Create(&print_string_module);
	//PyModule_Create(&print_string_module);
};

