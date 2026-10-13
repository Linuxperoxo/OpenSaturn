OUTPUT_FORMAT(elf32-i386)
ENTRY(_start) /* Remove _start warning */

_start = .i386.entry;

SECTIONS
{
  /*
   * These symbols are emitted by kernel/asl/asl.zig.
   *
   * The linker script uses VMA for the virtual address of the regular
   * kernel sections and LMA for their physical load address.
   */
  image_phys_base = kernel_mem_phys_base;
  kernel_text_vma = kernel_mem_virtual_text;
  kernel_data_vma = kernel_mem_virtual_data;

  . = image_phys_base;

  .opensaturn.bootloader.header : {
    KEEP(*(.opensaturn.bootloader.header))
  }

  phys_i386_start = .;

  .opensaturn.arch : {
    phys_i386_text_start = .;
    /* Discarded by the kernel after the architecture initialization. */
    KEEP(*(.i386.text))
    phys_i386_text_end = .;

    . = ALIGN(4096);

    phys_i386_data_start = .;
    KEEP(*(.i386.data))
    phys_i386_data_end = .;
  }

  . = ALIGN(4096);
  phys_i386_end = .;

  phys_opensaturn_start = phys_i386_end;

  . = kernel_text_vma;

  phys_opensaturn_text_start = phys_i386_end;

  .opensaturn.text : AT(phys_opensaturn_text_start) {
    *(.text*)
  }

  phys_opensaturn_text_end = LOADADDR(.opensaturn.text) + SIZEOF(.opensaturn.text);

  phys_opensaturn_data_start = ALIGN(phys_opensaturn_text_end, 4096);

  . = kernel_data_vma;

  .opensaturn.data : AT(phys_opensaturn_data_start) {
    *(.data*)
    *(.i386.opensaturn.data)
  }

  phys_opensaturn_data_end = LOADADDR(.opensaturn.data) + SIZEOF(.opensaturn.data);
  phys_opensaturn_rodata_start = ALIGN(phys_opensaturn_data_end, 4096);

  /* Keep read-only data on its own virtual page. */
  . = ALIGN(4096);

  .opensaturn.rodata : AT(phys_opensaturn_rodata_start) {
    *(.rodata*)
  }

  phys_opensaturn_rodata_end = LOADADDR(.opensaturn.rodata) + SIZEOF(.opensaturn.rodata);
  phys_opensaturn_bss_start = ALIGN(phys_opensaturn_rodata_end, 4096);

  /* Keep writable zero-initialized data out of the read-only page. */
  . = ALIGN(4096);

  .opensaturn.bss (NOLOAD) : AT(phys_opensaturn_bss_start) {
    *(.bss*)
  }

  phys_opensaturn_bss_end = LOADADDR(.opensaturn.bss) + SIZEOF(.opensaturn.bss);

  . = ALIGN(phys_opensaturn_bss_end, 4096);

  phys_opensaturn_mmu_start = .;

  .opensaturn.mmu : AT(phys_opensaturn_mmu_start) {
    *(.i386.opensaturn.pagedir)
    *(.i386.opensaturn.pagetable)
  }

  phys_opensaturn_mmu_end = .;

  /*
   * Keep the image size page-aligned for the bootloader.
   */
  phys_opensaturn_end = LOADADDR(.opensaturn.mmu) + SIZEOF(.opensaturn.mmu);

  .image_padding : AT(phys_opensaturn_end - 1) {
    FILL(0x00);
    . = ALIGN(4096);
    BYTE(0x00);
  }

  phys_opensaturn_kernel_zone_start = ALIGN(phys_opensaturn_end, 4096);

  /DISCARD/ : {
    *(.comment*)
    *(.note*)
    *(.gnu*)
    *(.eh_frame*)
  }

  PROVIDE(
    AtlasImgSize = (LOADADDR(.image_padding) + SIZEOF(.image_padding)) - image_phys_base
  );
}
