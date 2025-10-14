OUTPUT_FORMAT(elf32-i386)
/* OUTPUT_FORMAT(binary) */

SECTIONS {
  /*
   * opensaturn_phys_address: difined in kernel/loader.zig
   * opensaturn_virtual_address: difined in kernel/loader.zig
  */
  phys_init = opensaturn_phys_address;
  virtual_init = opensaturn_virtual_address;

  . = phys_init;

  .opensaturn.atlas : {
      KEEP(*(.opensaturn.data.atlas.header))
  }

  PROVIDE(
    phys_arch_start = .
  );

  .opensaturn.arch : {
      KEEP(*(.x86.arch.text)) /* free page for kernel after arch init */
      KEEP(*(.x86.arch.tmp.data))
      . = ALIGN(4096);
      PROVIDE(
        phys_arch_data_start = .
      );
      /* arch persistent data */
      KEEP(*(.x86.arch.data)) /* IDT GDT MMU STRUCTS WHERE */
  }

  . = ALIGN(4096);

  phys_arch_end = .;

  PROVIDE(
    phys_address_opensaturn_start = phys_arch_end
  );

  . = virtual_init;

  .opensaturn.text : AT(phys_arch_end) {
      *(.text*)
  }

  .opensaturn.data : AT(LOADADDR(.opensaturn.text) + SIZEOF(.opensaturn.text)) {
      *(.data*)
      *(.rodata*)
  }

  .opensaturn.bss (NOLOAD) : {
      *(.bss*)
      *(COMMON)
  }

  . = ALIGN(4096);

  PROVIDE(
    phys_address_opensaturn_end = LOADADDR(.opensaturn.bss) + SIZEOF(.opensaturn.bss)
  );

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
