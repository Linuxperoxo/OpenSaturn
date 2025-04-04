OUTPUT(sImage)
OUTPUT_FORMAT(binary)

SECTIONS {
  . = 0x1000000; 

  SF = .;

  .opensaturn.atlas : {
    *(.opensaturn.atlas.entry)
    AtlasImgSize = ( EF - SF) - 0x1000000;
  }

  .opensaturn.text : {
    *(.opensaturn.text.entry)
    *(.opensaturn.text.*)
  }

  /DISCARD/ : {
    *(.commet*)
    *(.note*)
    *(.gnu*)
  }
  
  EF = .;
}
