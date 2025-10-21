// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: sections.zig │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const section_text_loader = ".x86.text";
pub const section_data_loader = ".x86.data";
pub const section_data_persist = ".x86.opensaturn.data";

comptime {
    const aux: type = opaque {
        pub fn retGlobalSym(name: []const u8, value: []const u8) []const u8 {
            return ".set " ++ name ++ ", " ++ value ++ "\n" ++
                ".globl " ++ name ++ "\n"
            ;
        }
    };
    asm(
        aux.retGlobalSym("section_text_loader", section_text_loader) ++
        aux.retGlobalSym("section_data_loader", section_data_loader) ++
        aux.retGlobalSym("section_data_persist", section_data_persist)
    );
}
