OUTPUT_FORMAT(binary)
OUTPUT(OpenSaturn)

SECTIONS {
  . = 0x1000000; 

  INIT_BIN = .;

  .opensaturn.atlas : {
    *(.opensaturn.atlas.entry)
    ATLASSIZE = ( END_BIN - INIT_BIN) - 0x1000000;
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
  END_BIN = .;
}
