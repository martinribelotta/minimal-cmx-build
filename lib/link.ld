INCLUDE memory.ld

SECTIONS
{
  .text : {
    KEEP(*(.vector_core*))
    *(.text)
    *(.text.*)
  } > rom /* fill rom memory area with .text section */

  .rodata : {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
  } > rom /* the memory region increment the dot pointer value */

  .init_array : {
    . = ALIGN(4);
    __init_array_start = .;
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    . = ALIGN(4);
    __init_array_end = .;
  } > rom

  .data : {
    _data = .;
    *(.data)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } > ram AT>rom /* AT>section is equivalent of ...AT(expression) */

  _data_loadaddr = LOADADDR(.data);

  .bss : {
    . = ALIGN(4);
    _bss = .;
    *(.bss)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > ram

  /* ORIGIN(region) return the address of memory region, LENGTH return the length */
  _stack = ORIGIN(ram) + LENGTH(ram);
}
