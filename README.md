# High-Speed AXI4-Lite Dynamic MAC Accelerator for RISC-V SoC Designs

A programmable-precision Multiply–Accumulate (MAC) accelerator integrated with an **AXI4-Lite interface** and a **PicoRV32 RISC-V processor**.

The design implements a configurable MAC datapath using a **Radix-4 Booth multiplier**, **Brent–Kung adder**, and accumulator, with software-controlled operation through AXI4-Lite registers.

## Architecture

```text
                    PicoRV32 RISC-V
                          │
                          │
                     AXI4-Lite
                          │
                          ▼
                ┌──────────────────┐
                │   AXI Interface  │
                └────────┬─────────┘
                         │
                         ▼
                ┌──────────────────┐
                │ Dynamic Precision│
                │      MAC         │
                │                  │
                │ Radix-4 Booth    │
                │      ↓           │
                │ Brent–Kung Adder │
                │      ↓           │
                │   Accumulator    │
                └──────────────────┘
                         │
                         ▼
                       Result
```

## Key Features

* AXI4-Lite programmable control interface
* Dynamic MAC precision
* Radix-4 Booth multiplication
* Brent–Kung carry-lookahead addition
* Accumulator datapath
* PicoRV32 RISC-V processor integration
* On-chip RAM
* RISC-V firmware for accelerator control
* FPGA-oriented RTL and constraint files
* Functional simulation and verification

## Repository Structure

```text
rtl/
├── axi_interface/
│   ├── Axi4_Lite_Mac_Dy_v1_0.v
│   └── Axi4_Lite_Mac_Dy_v1_0_S00_AXI.v
│
├── mac_unit/
│   ├── BK_Top_dp.v
│   ├── accumulator_bk_dp.v
│   ├── booth_radix4_dp.v
│   ├── mac_top_dp.v
│   └── multiplier_stage_dp.v
│
├── processor/
│   └── picorv32.v
│
├── ram/
│   └── ram.v
│
└── soc/
    └── soc_top.v

firmware/
├── hex/
│   └── firmware.hex
├── riscv/
│   ├── firmware.c
│   ├── Makefile
│   ├── link.ld
│   └── start.s
└── tools/
    └── bin2hex.py

tb/
└── Testbenches

constraints/
└── FPGA constraint files

docs/
└── Design reports and documentation
```

## Verification

Functional verification is performed using directed testbenches at different levels of the design:

* MAC unit
* AXI4-Lite interface
* SoC integration
* RISC-V controlled operation

The testbenches are used to verify MAC functionality, AXI handshaking, register access, and processor-to-accelerator operation.

## Software / Hardware Integration

A PicoRV32 processor is used to control the MAC accelerator through memory-mapped AXI4-Lite registers.

The RISC-V firmware configures the accelerator, provides operands and precision settings, starts computation, and reads the resulting MAC value.

## Project Status

🚧 **Project completed as an academic RTL/SoC design project.**

Further work can include expanded automated verification, FPGA hardware validation, performance benchmarking, and additional precision configurations.
