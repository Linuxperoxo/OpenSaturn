OUTPUT_FORMAT(binary)

SECTIONS {
  . = 0x1000000; 

  SF = .;

  .opensaturn.atlas : {
    KEEP(*(.opensaturn.atlas.entry))
    AtlasImgSize = ( EF - SF) - 0x1000000;
  }

  .opensaturn.text : {
    KEEP(*(.opensaturn.text.entry))
    KEEP(*(*.text*))
  }

  /DISCARD/ : {
    *(.commet*)
    *(.note*)
    *(.gnu*)
  }
  
  EF = .;
}
