HELLO MATE!

This repository contains the design and verification setup for a high-speed MAC unit. The documentation here outlines the specifications, design approach, verification plan, and directory structure.

I. SPEC for the MAC_Unit

* Operands A,B: 16-bit signed (2’s complement)
*  Multiplier: Radix-4 Booth + Wallace tree (pipelined)
* Product width: 32 bits (16×16) signed
*  Adder: Kogge-Stone (fast prefix)
*  Accumulator: 40-bit signed register (to avoid overflow across many accumulations)
* Pipelining: 2 stages total — Stage0: Multiplier, Stage1: Sign-extend product + add to accumulator
*  Reset: synchronous active-high
*  Overflow handling: wrap-around (2’s complement) — no saturation unless you add it later

II. Bit-width

*  16-bit signed × 16-bit signed → 32-bit signed product.
*  Accumulator is 40 bits. So before adding product to accumulator, sign-extend the 32-bit product to 40 bits.
*  Adder inputs → 40 bits each; adder output → 40 bits.

III. Verification plan

Unit tests (for each module)
    1. Multiplier TB
    2. Adder TB
    3. Accumulator TB
    4. Mac_Top TB (in SV)
For the verification part we shall tend to use the MATLAB in_order to verfiy the speed and timing constraints of the ML data sets (from kaggle) so that can be fed using the MATLAB (it seems so will look after that myself).

IV. Tools

Use Vivaldo, icarus verilog + GTK_wave 
Matlab (with HDL support)
Verification - Model_Sim, EDA playground for now!


V. The structure and the designing modules 
```
MAC_Unit/
│
├── src/                   # All design RTL files
│   ├── mac_top.v          # Top-level integration
│   ├── adder.v            # Kogge-Stone adder
│   ├── multiplier.v       # Wallace tree multiplier (radix-4 Booth)
│   ├── accumulator.v      # 40-bit signed accumulator
│
├── tb/                    # Testbenches
│   ├── mac_top_tb.sv      # SystemVerilog TB for full MAC
│   ├── adder_tb.v         # Simple Verilog TB for adder
│   ├── multiplier_tb.v    # Simple Verilog TB for multiplier
│   ├── accumulator_tb.v   # Simple Verilog TB for accumulator
│
└── README.md              
```
VI. Checklist before integration

    1. Implement and pass unit tests for multiplier and adder.
    2.  Verify sign-extension logic separately.
    3.  Verify accumulator register behavior (reset/en).
    4. Integrate into mac_top and run deterministic + random tests.
    5. Produce waveform screenshots for key cases (corner and random).
    5. Document latency and throughput clearly.