OUTPUT_FORMAT(binary)

SECTIONS {
  . = 0x1000000; 

  SF = .;

  .opensaturn.atlas : {
    KEEP(*(.opensaturn.data.atlas.header))
    AtlasImgSize = ( EF - SF) - 0x1000000;
  }

  .opensaturn.text : {
    KEEP(*(*.text*))
  }

  .opensaturn.data : {
    . = ALIGN(4);
    KEEP(*(*.data*))
    . = ALIGN(4);
    KEEP(*(*.bss*))
  }

  /DISCARD/ : {
    *(.commet*)
    *(.note*)
    *(.gnu*)
  }

  EF = .;
}
