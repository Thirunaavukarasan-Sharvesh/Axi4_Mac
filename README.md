## High-Speed AXI4-Lite Dynamic MAC Accelerator for RISC-V SoC Designs

This repository contains the RTL design, firmware, and testbenches for an
AXI4-Lite integrated Dynamic Precision Multiply–Accumulate (MAC) unit
interfaced with a PicoRV32 RISC-V processor.

## Repository Structure
- rtl/        : Synthesizable RTL (MAC, AXI, processor, RAM, SoC)
- tb/         : Basic functional testbenches
- firmware/   : RISC-V firmware and hex and related files
- docs/       : Reports, block diagrams, and waveforms
- constraints/: FPGA constraint files (Yet to be implemented)

## Verification
Functional verification is performed using directed testbenches at
MAC, AXI, and SoC levels to validate correctness and proper handshake.
