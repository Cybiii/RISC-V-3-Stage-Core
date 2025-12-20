# RISC-V 3-Stage CPU Core

A fully functional 3-stage pipelined RISC-V CPU implementation in Verilog. This project implements a complete RISC-V instruction set architecture (ISA) processor with memory hierarchy, cache system, and comprehensive test infrastructure.

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

## Project Structure

```
RISC-V-3-Stage-Core/
├── src/                    # Verilog source files
│   ├── Riscv151.v         # Main CPU core module
│   ├── riscv_top.v        # Top-level module
│   ├── ALU.v              # Arithmetic Logic Unit
│   ├── Control.v          # Control unit
│   ├── RegFile.v          # Register file
│   ├── BranchComp.v       # Branch comparator
│   ├── ImmGen.v           # Immediate generator
│   ├── Cache.v            # Cache controller
│   ├── Memory151.v        # Main memory
│   ├── PartialLoad.v      # Partial load handler
│   ├── PartialStore.v     # Partial store handler
│   └── *.vh               # Header files (constants, opcodes)
├── tests/                  # Test infrastructure
│   ├── asm/               # Assembly test suite
│   │   └── riscv-tests/   # RISC-V compliance tests
│   └── bmark/             # Benchmark programs
├── scripts/                # Build and analysis scripts
│   ├── fom.py             # Figure of merit calculator
│   └── get_area.sh        # Area extraction script
└── *.yml                   # Configuration files for synthesis/par
```

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

## Building and Simulation

### Prerequisites
- Verilog simulator (e.g., Verilator, ModelSim, VCS)
- Make
- Python 3 (for test generation)

### Building
```bash
make
```

### Running Tests
```bash
cd tests/asm
make
```

## Testing

The project includes comprehensive test coverage:

- **RISC-V ISA Compliance Tests**: Full suite of official RISC-V compliance tests
- **Benchmark Programs**: Various benchmark applications
- **ALU Testbenches**: Unit tests for ALU functionality

Test results verify correct implementation of:
- All RV32I base instructions
- Memory operations (load/store)
- Branch and jump instructions
- Arithmetic and logical operations

## Configuration Files

- `sim-rtl.yml`: RTL simulation configuration
- `sim-gl-syn.yml`: Gate-level simulation (post-synthesis)
- `sim-gl-par.yml`: Gate-level simulation (post-place-and-route)
- `syn.yml`: Synthesis configuration
- `par.yml`: Place and route configuration
- `sky130.yml`: SkyWater 130nm PDK configuration

## Scripts

- `scripts/fom.py`: Calculates figure of merit (area, power, performance)
- `scripts/get_area.sh`: Extracts area information from synthesis reports
- `scripts/get_area.tcl`: TCL script for area extraction

## License

This project is part of the EECS 151/251A ASIC Project for Fall 2025.

## Contributing

This is an academic project. For questions or issues, please refer to the course materials.
