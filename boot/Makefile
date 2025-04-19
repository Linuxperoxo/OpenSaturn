#    /--------------------------------------------O
#    |                                            |
#    |  COPYRIGHT : (c) 2025 per Linuxperoxo.     |
#    |  AUTHOR    : Linuxperoxo                   |
#    |  FILE      : Makefile                      |
#    |                                            |
#    O--------------------------------------------/

ASM = /usr/bin/gcc

ASMFLAGS = -nostdlib -I $(INCLUDE_DIR) -T $(LINKER_FILE)

ATLAS_SRC = ./src/atlas.s
ATLAS_BIN = $(ATLAS_BIN_DIR)/AtlasB.osb
LINKER_FILE = ./linker.ld

INCLUDE_DIR = ./include
BIN_DIR = ./build
ATLAS_BIN_DIR = $(BIN_DIR)/atlas

ALL_DIRS = $(BIN_DIR) $(ATLAS_BIN_DIR)

all: $(ALL_DIRS) $(ATLAS_BIN)

clean: $(ALL_DIRS)
	@rm -r $(BIN_DIR)

$(ALL_DIRS):
	@mkdir -p $@

$(ATLAS_BIN):
	$(ASM) $(ASMFLAGS) $(ATLAS_SRC) -o $@

.PHONY: all clean build

