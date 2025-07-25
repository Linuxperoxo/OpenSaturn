// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: arch.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// --- SATURN TARGET ---
pub const __SaturnTarget__: target_T = .x86;
pub const __SaturnCodeModel__: codeMode_T = .Runtime;
pub const __SaturnOptimize__: opt_T = .Small;

// --- SATURN ARCH ---
pub const __SaturnAllArchs__ = [_]type {
    @import("kernel/arch/x86/x86.zig"),
    @import("kernel/arch/x86_64/x86_64.zig"),
    @import("kernel/arch/arm/arm.zig"),
    @import("kernel/arch/avr/avr.zig"),
};

// --- SATURN ENABLED ARCH ---
pub const __SaturnEnabledArch__: type = switch(__SaturnTarget__) {
    .x86 => __SaturnAllArchs__[0],
    .x86_64 => __SaturnAllArchs__[1],
    .arm => __SaturnAllArchs__[2],
    .avr => __SaturnAllArchs__[3],
};

// --- SATURN ENABLED ARCH INFOS ---
pub const __SaturnEnabledArchUsable__: usable_T = __SaturnEnabledArch__.__arch_usable__;
pub const __SaturnEnabledArchLinker__: linker_T = __SaturnEnabledArch__.__arch_linker_build__;
pub const __SaturnEnabledArchSupervisor__: supervisor_T = __SaturnEnabledArch__.__arch_supervisor__;
pub const __SaturnEnabledArchMaintainer__: ?maintainer_T = verify: {
    if(@hasDecl(__SaturnEnabledArch__, "__arch_maintainer__")) {
        break :verify __SaturnEnabledArch__.__arch_maintainer__;
    }
    break :verify null;
};

const name_T: type = []const u8;
const maintainer_T: type = []const u8;
const usable_T: type = bool;
const supervisor_T: type = bool;
const supervisorInit_T: type = fn() void;
const entry_T: type = fn() callconv(.naked) noreturn;
const init_T: type = fn() void;
const linker_T: type = []const u8;
pub const target_T: type = enum {
    x86,
    x86_64,
    arm,
    avr
};
pub const codeMode_T: type = enum {
    Debug,
    Runtime,
};
pub const opt_T: type = enum {
    Small,
    Fast,
};

fn verifyExistence(comptime name: []const u8, T: type) void {
    if(!@hasDecl(__SaturnEnabledArch__, name)) {
        @compileError(
            "target kernel cpu architecture does not have internal declaration set to 'pub " ++ name ++ " type " ++ @typeName(T) ++ "'"
        );
    }
}

fn verifyTypes(comptime name: []const u8, T0: type, T1: type) void {
    if(T0 != T1) {
        @compileError(
            name ++ " is expected to be an " ++ @typeName(T0)
        );
    }
}

comptime {
    verifyExistence("entry", entry_T);
    verifyTypes("entry", entry_T, @TypeOf(__SaturnEnabledArch__.entry));

    verifyExistence("init", init_T);
    verifyTypes("init", init_T, @TypeOf(__SaturnEnabledArch__.init));

    verifyExistence("__arch_linker_build__", linker_T);
    verifyTypes("__arch_linker_build__", linker_T, @TypeOf(__SaturnEnabledArch__.__arch_linker_build__));

    verifyExistence("__arch_supervisor__", supervisor_T);
    verifyTypes("__arch_supervisor__", supervisor_T, @TypeOf(__SaturnEnabledArch__.__arch_supervisor__));

    sw: switch(@hasDecl(__SaturnEnabledArch__, "__arch_usable__")) {
        true => {
            verifyTypes("__arch_usable__", usable_T, @TypeOf(__SaturnEnabledArch__.__arch_usable__));
            if(!__SaturnEnabledArch__.__arch_usable__) {
                continue :sw false; // Voltando para o inicio do switch so que passando false para o switch
            }
        },
        false => {
            @compileError(
                \\ target kernel cpu architecture has no guarantee of functioning by the developer
            );
        },
    }
}

