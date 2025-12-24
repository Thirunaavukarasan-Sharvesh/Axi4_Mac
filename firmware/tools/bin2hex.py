# Convert binary → 32-bit word-per-line hex for $readmemh
import sys

binfile = sys.argv[1]
hexfile = sys.argv[2]

with open(binfile, "rb") as f:
    data = f.read()

# Pad to multiple of 4 bytes
while len(data) % 4 != 0:
    data += b"\x00"

with open(hexfile, "w") as f:
    f.write("@00000000\n")
    for i in range(0, len(data), 4):
        w = data[i] | (data[i+1] << 8) | (data[i+2] << 16) | (data[i+3] << 24)
        f.write("{:08x}\n".format(w))
