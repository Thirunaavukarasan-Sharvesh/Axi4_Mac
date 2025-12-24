ENTRY(main)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 128K
}

SECTIONS
{
    .text : {
        *(.text*)
        *(.rodata*)
        *(.srodata*)
    } > RAM

    .data : {
        *(.data*)
        *(.sdata*)
        *(.srodata*)
    } > RAM

    .bss : {
        *(.bss*)
        *(.sbss*)
        *(COMMON)
    } > RAM

    .heap (NOLOAD) : {
        __heap_start = .;
        . += 4K;
        __heap_end = .;
    } > RAM

    .stack (NOLOAD) : {
        . = ORIGIN(RAM) + LENGTH(RAM) - 4K;
        __stack_top = .;
    } > RAM
}
