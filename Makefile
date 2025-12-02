# Makefile for the kernel module

# Driver name variable
DRIVER_NAME := fakmac

# Get the path to the kernel build system
# KERNEL_BUILD_DIR should point to the directory containing the kernel source or headers' Makefile
# /lib/modules/$(shell uname -r)/build is the standard location for the currently running kernel's build system
KERNEL_BUILD_DIR := /lib/modules/$(shell uname -r)/build

SOURCES := $(wildcard src/*)
BUILD_DIR := $(CURDIR)/build
KO_PATH := $(BUILD_DIR)/$(DRIVER_NAME).ko

# Build the module
$(KO_PATH): $(SOURCES)
	@if [ "$$(id -u)" -eq 0 ]; then \
		owner=$$(stat -c '%U' .); \
		if [ "$$owner" = "root" ]; then \
			echo "Error: Do not build as root"; \
			exit 1; \
		else \
			echo "Running build as $$owner"; \
			su -c "$(MAKE) $@" $$owner; \
		fi \
	else \
		rm -rf $(BUILD_DIR); \
		mkdir -p $(BUILD_DIR); \
		cp $(SOURCES) $(BUILD_DIR); \
		make -C $(KERNEL_BUILD_DIR) M=$(BUILD_DIR) modules; \
	fi

# Alias
build: $(KO_PATH)

# Check if module is compiled for current kernel, compile if not
update:
	@if modinfo $(KO_PATH) 2>/dev/null | grep -q "$(shell uname -r)"; then \
		echo "Module $(DRIVER_NAME) is already compiled for kernel $(shell uname -r)."; \
	else \
		echo "Module $(DRIVER_NAME) is not compiled for kernel $(shell uname -r)."; \
		$(MAKE) build; \
	fi

# Clean target: remove generated files
clean:
	rm -rf $(BUILD_DIR)

# Load module with environment variables, set MAC addresses, and show details
load_env: unload update
	sudo insmod $(KO_PATH) numdummies=${FM_NUM}
	for i in $$(seq 0 $$(($${FM_NUM}-1))); do \
		eval mac=\$$FM_$$i; \
		if [ -z "$$mac" ]; then \
			echo "Error: Environment variable FM_$$i is not set"; \
			sudo rmmod $(DRIVER_NAME); \
			exit 1; \
		fi; \
		sudo ip link set dev $(DRIVER_NAME)$$i address $$mac; \
		ip -d link show $(DRIVER_NAME)$$i; \
	done

# Unload the module
unload:
	sudo rmmod $(DRIVER_NAME) || true

.DEFAULT_GOAL := build
.PHONY: build clean load_test load_env unload update