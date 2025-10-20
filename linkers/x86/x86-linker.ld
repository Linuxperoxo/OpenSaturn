OUTPUT_FORMAT(elf32-i386)
/* OUTPUT_FORMAT(binary) */

SECTIONS {
  /*
   * opensaturn_phys_address: difined in kernel/loader.zig
   * opensaturn_virtual_address: difined in kernel/loader.zig
  */
  phys_init = kernel_phys_address;
  virtual_init = kernel_virtual_address;

  phys_init_atlas_header = phys_init;

  . = phys_init;

  .opensaturn.atlas : {
      KEEP(*(.opensaturn.data.atlas.header))
  }

  PROVIDE(
    phys_i386_start = .
  );

  .opensaturn.arch : {
      /* .text expurgated after jmp to kernel */
      KEEP(*(.x86.arch.text)) /* free page for kernel after arch init */
      . = ALIGN(4096);
      PROVIDE(
        phys_i386_data_start = .
      );
      /* arch persistent data */
      KEEP(*(.x86.arch.data)) /* IDT GDT MMU STRUCTS WHERE */
      PROVIDE(
        phys_i386_data_end = .
      );
  }

  . = ALIGN(4096);

  PROVIDE(
    phys_i386_end = .
  );

  PROVIDE(
    phys_address_opensaturn_start = phys_i386_end
  );

  . = virtual_init;

  PROVIDE(
    phys_address_opensaturn_text_start = phys_i386_end
  );

  .opensaturn.text : AT(phys_address_opensaturn_text_start) {
      *(.text*)
  }

  PROVIDE(
    phys_address_opensaturn_text_end = LOADADDR(.opensaturn.text) + SIZEOF(.opensaturn.text)
  );

  PROVIDE(
    phys_address_opensaturn_data_start = ALIGN(phys_address_opensaturn_text_end, 4096)
  );

  . = kernel_data_virtual;

  .opensaturn.data : AT(phys_address_opensaturn_data_start) {
    *(.data*)
  }

  PROVIDE(
    phys_address_opensaturn_data_end = LOADADDR(.opensaturn.data) + SIZEOF(.opensaturn.data)
  );

  PROVIDE(
    phys_address_opensaturn_rodata_start = ALIGN(phys_address_opensaturn_data_end, 4096)
  );

  .opensaturn.rodata : AT(phys_address_opensaturn_rodata_start) {
    *(.rodata*)
  }

  PROVIDE(
    phys_address_opensaturn_rodata_end = LOADADDR(.opensaturn.rodata) + SIZEOF(.opensaturn.rodata)
  );

  .opensaturn.bss (NOLOAD) : {
    *(.bss*)
  }

  opensaturn_sections_total_of_size = ABSOLUTE(. - virtual_init);
  opensaturn_arch_sections_total_of_size = ABSOLUTE(phys_i386_end - phys_i386_start);
  opensaturn_atlas_section_total_of_size = SIZEOF(.opensaturn.atlas);

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
    AtlasImgSize =
      opensaturn_sections_total_of_size +
      opensaturn_arch_sections_total_of_size +
      opensaturn_atlas_section_total_of_size
  );
}
