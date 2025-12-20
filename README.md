# RISC-V 3-Stage CPU Core

A fully functional 3-stage pipelined RISC-V CPU implementation in Verilog. This project implements a complete RISC-V instruction set architecture processor with memory hierarchy, cache system, and comprehensive test infrastructure.

## Overview

This is a 3-stage pipelined RISC-V processor core that supports the RV32I base instruction set. The processor features:

- 3-stage pipeline: Fetch, Decode/Execute, Writeback
- Complete RISC-V RV32I instruction set support
- Direct-mapped instruction and data cache
- Memory management unit with partial load/store support
- Comprehensive test suite with RISC-V ISA compliance tests

## Architecture

The CPU implements a classic 3-stage pipeline:

1. **Fetch Stage**: Instruction fetch from memory/cache
2. **Decode/Execute Stage**: Instruction decoding, ALU operations, memory access
3. **Writeback Stage**: Register file updates

## Core Components

### CPU Core (`Riscv151.v`)

The main processor module implementing the 3-stage pipeline. Handles instruction flow, hazard detection, and pipeline control.

### ALU (`ALU.v`)

Arithmetic Logic Unit supporting all RISC-V arithmetic and logical operations including:

- Addition, subtraction
- Bitwise operations (AND, OR, XOR)
- Shift operations
- Comparison operations

### Control Unit (`Control.v`)

Generates control signals for instruction execution, including:

- ALU control signals
- Register file read/write enables
- Memory access control
- Branch and jump control

### Register File (`RegFile.v`)

32-entry register file with dual read ports and single write port, implementing the RISC-V register specification (x0-x31).

### Memory System

- **Cache** (`Cache.v`): Direct-mapped instruction and data cache
- **Memory** (`Memory151.v`): Main memory controller
- **Partial Load/Store**: Handles byte and halfword memory operations

## Testing

The project includes comprehensive test coverage:

- **RISC-V ISA Compliance Tests**: Full suite of official RISC-V compliance tests
- **Benchmark Programs**: Various benchmark applications
- **ALU Testbenches**: Unit tests for ALU functionality

## Configuration Files

- `sim-rtl.yml`: RTL simulation configuration
- `sim-gl-syn.yml`: Gate-level simulation (post-synthesis)
- `sim-gl-par.yml`: Gate-level simulation (post-place-and-route)
- `syn.yml`: Synthesis configuration
- `par.yml`: Place and route configuration
- `sky130.yml`: SkyWater 130nm PDK configuration
