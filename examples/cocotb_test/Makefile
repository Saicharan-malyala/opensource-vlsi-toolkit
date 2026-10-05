# Makefile for running cocotb simulation with Icarus Verilog
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = $(shell pwd)/../counter/counter.v

TOPLEVEL = counter
MODULE = test_counter

include $(shell cocotb-config --makefiles)/Makefile.sim
