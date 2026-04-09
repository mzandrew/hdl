/* 2025-03-07 modified by mza to be just a throughput test for bulk reads or writes
 * now licensed under GPLv3
 * symlink "resource0" should point to /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0/resource0 or similar (check output of lspci | grep Xilinx)
 * 01:00.0 Memory controller: Xilinx Corporation Device 7024
 * pcimem.c originally from https://github.com/billfarrow/pcimem.git
 *
 * pcimem.c: Simple program to read/write from/to a pci device from userspace.
 * Copyright (C) 2010, Bill Farrow (bfarrow@beyondelectronics.us)
 * Based on the devmem2.c code
 * Copyright (C) 2000, Jan-Derk Bakker (J.D.Bakker@its.tudelft.nl)
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

// read 1GB:
//real	0m17.285s
//user	0m0.004s
//sys	0m0.007s

// write 1GB:
//real	0m13.280s
//user	0m0.002s
//sys	0m0.005s

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <ctype.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/mman.h>

#define PRINT_ERROR do { fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", __LINE__, __FILE__, errno, strerror(errno)); exit(1); } while(0)

int main(int argc, char **argv) {
	int fd;
	void *map_base, *virt_addr;
	uint64_t read_result, writeval = 0;
	off_t target_base;
	int verbose = 0;
	int map_size = 4096UL;
	char mode = 'w';
	char filename[] = "resource0";
	off_t target = 0;
	int type_width = 4;
	int items_count = 1024*1024/type_width;
	int number_of_iterations = 1024;
	if ((fd = open(filename, O_RDWR | O_SYNC)) == -1) PRINT_ERROR;
	//printf("%s opened.\n", filename);
	//printf("Target offset is 0x%x, page size is %ld\n", (int) target, sysconf(_SC_PAGE_SIZE));
	//fflush(stdout);
	target_base = target & ~(sysconf(_SC_PAGE_SIZE)-1);
	if (target + items_count*type_width - target_base > map_size)
	map_size = target + items_count*type_width - target_base;
	/* Map one page */
	//printf("mmap(%d, %d, 0x%x, 0x%x, %d, 0x%x)\n", 0, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, (int) target);
	map_base = mmap(0, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, target_base);
	if (map_base == (void *) -1) PRINT_ERROR;
	//printf("PCI Memory mapped to address 0x%08lx.\n", (unsigned long) map_base);
	//fflush(stdout);
	if (mode=='r') {
		for (int j=0; j<number_of_iterations; j++) {
			for (int i=0; i<items_count; i++) {
				virt_addr = map_base + target + i*type_width - target_base;
				read_result = *((uint32_t *) virt_addr);
//				if (verbose) {
//					printf("Value at offset 0x%X (%p): 0x%0*lX\n", (int) target + i*type_width, virt_addr, type_width*2, read_result);
//				} else {
//					printf("0x%04X: 0x%0*lX\n", (int)(target + i*type_width), type_width*2, read_result);
//				}
			}
		}
	//fflush(stdout);
	//writeval = strtoull(argv[4], NULL, 0);
	} else {
		for (int j=0; j<number_of_iterations; j++) {
			for (int i=0; i<items_count; i++) {
				virt_addr = map_base + target + i*type_width - target_base;
				*((uint32_t *) virt_addr) = writeval;
				//read_result = *((uint32_t *) virt_addr);
			}
		}
	}
	//printf("Written 0x%0*lX; readback 0x%*lX\n", type_width, writeval, type_width, read_result);
	//fflush(stdout);
	if (munmap(map_base, map_size) == -1) PRINT_ERROR;
	close(fd);
	return 0;
}

