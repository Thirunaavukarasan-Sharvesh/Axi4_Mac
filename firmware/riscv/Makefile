# //////////////////////////////////////////////////////////////
# Firmware Build System for PicoRV32 + AXI MAC
# //////////////////////////////////////////////////////////////

RISCV_PREFIX = riscv-none-elf-
CC      = $(RISCV_PREFIX)gcc
OBJCOPY = $(RISCV_PREFIX)objcopy
PYTHON  = python

# Paths

SRC_DIR   = .
HEX_DIR   = ../hex
TOOLS_DIR = ../tools

# Files

SRC     = firmware.c
LINKER  = link.ld
ELF     = firmware.elf
BIN     = firmware.bin
HEX     = firmware.hex

# Flags

CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -nostdlib -nostartfiles
LFLAGS  = -T $(LINKER) -Wl,--no-relax -Wl,-Bstatic -ffreestanding

# Default target
all: $(HEX_DIR)/$(HEX)

# Step 1: C ->ELF

$(ELF): $(SRC) $(LINKER)
	$(CC) $(CFLAGS) $(LFLAGS) $(SRC) -o $(ELF)

# Step 2: ELF -> BIN

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BIN)

# Step 3: BIN → HEX

$(HEX_DIR)/$(HEX): $(BIN) $(TOOLS_DIR)/bin2hex.py
	@echo "Generating firmware.hex ..."
	$(PYTHON) $(TOOLS_DIR)/bin2hex.py $(BIN) $(HEX_DIR)/$(HEX)

# Clean

clean:
	@echo "Cleaning firmware build files..."
	rm -f $(ELF) $(BIN) $(HEX_DIR)/$(HEX)
