OUTPUT_FORMAT(elf32-i386)
/* OUTPUT_FORMAT(binary) */

SECTIONS {
  /*
   * opensaturn_phys_address: difined in kernel/loader.zig
   * opensaturn_virtual_address: difined in kernel/loader.zig
  */
  phys_init = kernel_phys_address;

  opensaturn_text_virtual = kernel_text_virtual;
  opensaturn_data_virtual = kernel_data_virtual;

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
      KEEP(*(.x86.text)) /* free page for kernel after arch init */
      . = ALIGN(4096);
      PROVIDE(
        phys_i386_data_start = .
      );
      /* arch persistent data */
      KEEP(*(.x86.data)) /* IDT GDT MMU STRUCTS WHERE */
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

  . = opensaturn_text_virtual;

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

  . = opensaturn_data_virtual;

  .opensaturn.data : AT(phys_address_opensaturn_data_start) {
    *(.data*)
    *(.x86.opensaturn.data)
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

  /*
   * NOTE: Apenas para facilitar a vida do bootloader
   */
  .image_padding : AT(phys_address_opensaturn_rodata_end) {
      FILL(0x00);
      . = ALIGN(4096);
  }

  .opensaturn.bss (NOLOAD) : {
    *(.bss*)
  }

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
    AtlasImgSize = (LOADADDR(.image_padding) + SIZEOF(.image_padding)) - phys_init
  );
}
