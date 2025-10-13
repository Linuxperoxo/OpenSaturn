/* OUTPUT_FORMAT(elf32-i386) */
OUTPUT_FORMAT(binary)

SECTIONS {
  phys_init = 0x1000000;
  phys_init1 = 0x2000000;
  virtual_init = 0xC0000000;

  . = phys_init;

  .opensaturn.atlas : {
    KEEP(*(.opensaturn.data.atlas.header))
  }

  . = ALIGN(64);
  .opensaturn.arch : {
    KEEP(*(.x86.arch.text))
    KEEP(*(.x86.arch.data))
  }

  end_phys = .;

  /*. = phys_init1; */
  . = phys_init1;

  . = ALIGN(64);
  .opensaturn.text : {
    KEEP(*(*.text))
  }

  . = ALIGN(64);
  .opensaturn.data : {
    KEEP(*(*.data))
    KEEP(*(*.rodata))
  }

  . = ALIGN(64);
  .opensaturn.bss : {
    KEEP(*(*.bss))
  }

  /DISCARD/ : {
    *(.comment*)
    *(.note*)
    *(.gnu*)
  }

  end_of_mem = .;

  PROVIDE(
      AtlasImgSize = SIZEOF(.opensaturn.atlas)
                 + SIZEOF(.opensaturn.arch)
                 + SIZEOF(.opensaturn.text)
                 + SIZEOF(.opensaturn.data)
                 + SIZEOF(.opensaturn.bss)
  );
}

