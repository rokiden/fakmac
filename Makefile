# Makefile for the kernel module

# Driver name variable
DRIVER_NAME := fakmac

# Set the name of your module (without the .c extension)
# This will be the name of the .ko file
obj-m := $(DRIVER_NAME).o

# Get the path to the kernel build system
# KERNEL_BUILD_DIR should point to the directory containing the kernel source or headers' Makefile
# /lib/modules/$(shell uname -r)/build is the standard location for the currently running kernel's build system
KERNEL_BUILD_DIR := /lib/modules/$(shell uname -r)/build

# Default target: build the module
# Call make from the kernel build system, passing the current directory (PWD)
# as the source of the module's makefile
all:
	make -C $(KERNEL_BUILD_DIR) M=$(PWD) modules

# Clean target: remove generated files
clean:
	make -C $(KERNEL_BUILD_DIR) M=$(PWD) clean

load:
	sudo insmod ./$(DRIVER_NAME).ko numdummies=1

unload:
	sudo rmmod $(DRIVER_NAME)