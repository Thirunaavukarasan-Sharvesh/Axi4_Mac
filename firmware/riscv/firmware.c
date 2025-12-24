// ------------------------------------------------------------
// Dynamic-Precision MAC test firmware for PicoRV32
// ------------------------------------------------------------
#include <stdint.h>

#define MAC_BASE      0x40000000u
#define MAC_CTRL      (*(volatile unsigned int*)(MAC_BASE + 0x00))
#define MAC_OP        (*(volatile unsigned int*)(MAC_BASE + 0x04))
#define MAC_RES       (*(volatile unsigned int*)(MAC_BASE + 0x08))
#define MAC_PREC      (*(volatile unsigned int*)(MAC_BASE + 0x0C))

#define N_TESTS 6

// Test vectors
static const int testA[N_TESTS] = {  10,   3,  -4, 100,  -20,   7 };
static const int testB[N_TESTS] = {   5,   7,   6,  -2,   10,  -3 };

// Precision modes:
// 0 → 8-bit
// 1 → 16-bit
// 2 → 32/40-bit
static const unsigned precision_modes[3] = {0, 1, 2};

void main(void)
{
    volatile unsigned int *store = (volatile unsigned int *)0x000000A0 ;

    int index = 0;

    // --------------------------------------------------------
    // LOOP OVER PRECISION MODES
    // --------------------------------------------------------
    for (int pm = 0; pm < 3; pm++)
    {
        MAC_PREC = precision_modes[pm];   // write precision

        // Clear accumulator for each precision test
        MAC_CTRL = 2;   // clear=1
        MAC_CTRL = 0;

        // ----------------------------------------------------
        // Run all test vectors
        // ----------------------------------------------------
        for (int i = 0; i < N_TESTS; i++) {

            int a = testA[i];
            int b = testB[i];

            // Pack A and B
            unsigned int packed =
                (((unsigned int)(a & 0xFFFF)) << 16) |
                 ((unsigned int)(b & 0xFFFF));

            // Write operands
            MAC_OP = packed;

            // Pulse enable
            MAC_CTRL = 0;
            MAC_CTRL = 1;

            // Read accumulator result
            unsigned int result = MAC_RES;

            // Store output in RAM
            store[index++] = result;
        }
    }

    // Done
    while (1) { }
}
