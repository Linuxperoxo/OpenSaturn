OUTPUT_FORMAT(elf32-i386)
/* OUTPUT_FORMAT(binary) */

SECTIONS {
  phys_init = 0x1000000;
  virtual_init = 0xC0000000;

  . = phys_init;

  .opensaturn.atlas : {
      . = ALIGN(64);
      KEEP(*(.opensaturn.data.atlas.header))
  }

  .opensaturn.arch : {
      . = ALIGN(64);
      KEEP(*(.x86.arch.text))
      KEEP(*(.x86.arch.data))
  }

  phys_arch_end = .;

  . = virtual_init;

  .opensaturn.text : AT(phys_arch_end) {
      . = ALIGN(64);
      *(.text*)
  }

  .opensaturn.data : AT(LOADADDR(.opensaturn.text) + SIZEOF(.opensaturn.text)) {
      . = ALIGN(64);
      *(.data*)
      *(.rodata*)
  }

  .opensaturn.bss (NOLOAD) : {
      . = ALIGN(64);
      *(.bss*)
      *(COMMON)
  }

  /DISCARD/ : {
      *(.comment*)
      *(.note*)
      *(.gnu*)
      *(.eh_frame*)
  }

  PROVIDE(
    AtlasImgSize = SIZEOF(.opensaturn.atlas)
      + SIZEOF(.opensaturn.arch)
      + SIZEOF(.opensaturn.text)
      + SIZEOF(.opensaturn.data)
      + SIZEOF(.opensaturn.bss)
  );
}
