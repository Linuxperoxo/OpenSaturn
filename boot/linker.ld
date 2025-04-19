/*
 *
 *    /--------------------------------------------O
 *    |                                            |
 *    |  COPYRIGHT : (c) 2025 per Linuxperoxo.     |
 *    |  AUTHOR    : Linuxperoxo                   |
 *    |  FILE      : linker.ld                     |
 *    |                                            |
 *    O--------------------------------------------/
 *
 */

OUTPUT(AtlasB.osb)
OUTPUT_FORMAT(binary)

origin_text  = 0x7C00;
origin_magic = 0x7DFE;

SECTIONS {
  . = origin_text;

  .atlas.text : {
    *(.atlas.text.atlas)
    *(.atlas.text.*)
  }

  .atlas.data : {
    *(.atlas.data*)
  }

  . = origin_magic;

  .atlas.magic : {
    *(.atlas.mbr.magic)
  }

  .atlas.struct : {
    . = ALIGN(4);
    *(.atlas.struct.atlas)
  }

  /DISCARD/ : {
    *(.note*)
    *(.comment*)
    *(.gnu*)
  }
}
