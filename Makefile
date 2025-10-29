# Makefile for the kernel module

# Driver name variable
DRIVER_NAME := fakmac

# Set source files
obj-m := $(DRIVER_NAME).o

# Get the path to the kernel build system
# KERNEL_BUILD_DIR should point to the directory containing the kernel source or headers' Makefile
# /lib/modules/$(shell uname -r)/build is the standard location for the currently running kernel's build system
KERNEL_BUILD_DIR := /lib/modules/$(shell uname -r)/build

# Default target: build the module
all:
	make -C $(KERNEL_BUILD_DIR) M=$(PWD) modules

# Clean target: remove generated files
clean:
	make -C $(KERNEL_BUILD_DIR) M=$(PWD) clean

# Load module with default parameters, set MAC address, and show details
load:
	sudo insmod ./$(DRIVER_NAME).ko
	sudo ip link set dev $(DRIVER_NAME)0 address de:ad:be:ef:00:01
	ip -d link show $(DRIVER_NAME)0
	ls /sys/devices/virtual/net/

# Unload the module
unload:
	sudo rmmod $(DRIVER_NAME)