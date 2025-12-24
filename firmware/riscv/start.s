    .section .text.start
    .globl _start
_start:
    la sp, __stack_top     # Initialize stack pointer
    call main              # Jump to main()
1:  j 1b                   # Infinite loop if main returns
