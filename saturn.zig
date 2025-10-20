// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: saturn.zig   │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo e responsavel por fazer resolver arquivos
// de arquitetura alvo, alem de juntar todas as partes do
// kernel em um unico arquivo

// Esse arquivo nao precisa ser legivel, apenas juntas todas
// as partes em um unico arquivo, partimos da ideia da leitura
// desse arquivo ficar dificil para a estrutura dos codigos fique
// organizada
const SelectedArch: type = switch(config.arch.options.Target) {
    .x86 => Architectures.x86,
    .x86_64 => Architectures.x86_64,
    .arm => Architectures.arm,
    .avr => Architectures.avr,
    .xtensa => Architectures.xtensa,
    .riscv => unreachable, // TODO:
};
pub const cpu: type = struct {
    pub const arch: type = SelectedArch.arch;
    pub const entry: type = SelectedArch.entry;
    pub const init: type = SelectedArch.init;
    pub const interrupts: type = SelectedArch.interrupts;
    pub const linker: type = SelectedArch.linker;
    pub const mm: type = SelectedArch.mm;
    pub const custom: bool = @hasDecl(SelectedArch, "config");
};
pub const Architectures: type = struct {
    // Eu poderia usar usar o @tagName para construir o caminho
    // do arquivo para cada arquitetura, mas assim alem de ficar
    // mais visivel, abre a possibilidade de modificar o diretorio
    // ou o nome do arquivo
    pub const x86: type = struct {
        pub const arch: type = @import("kernel/arch/x86/x86.zig");
        pub const entry: type = @import("kernel/entries/x86/entry.zig");
        pub const init: type = @import("kernel/init/x86/init.zig");
        pub const interrupts: type = @import("kernel/interrupts/x86/x86_interrupts.zig");
        pub const linker: type = @import("linkers/x86/x86-linker.zig");
        pub const mm: type = @import("mm/x86/mm.zig");
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/x86/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/x86/lib.zig");
        };
    };

    pub const x86_64: type = struct {
        pub const arch: type = @import("kernel/arch/x86_64/x86_64.zig");
        pub const entry: type = @import("kernel/entries/x86_64/entry.zig");
        pub const interrupts: type = @import("kernel/interrupts/x86_64/x86_64_interrupts.zig");
        pub const linker: type = @import("linkers/x86_64/x86_64-linker.zig");
        pub const mm: type = @import("mm/x86_64/mm.zig");
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/x86_64/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/x86_64/lib.zig");
        };
    };

    pub const arm: type = struct {
        pub const arch: type = @import("kernel/arch/arm/arm.zig");
        pub const entry: type = @import("kernel/entries/arm/entry.zig");
        pub const interrupts: type = @import("kernel/interrupts/arm/arm_interrupts.zig");
        pub const linker: type = @import("linkers/arm/arm-linker.zig");
        pub const mm: type = @import("mm/arm/mm.zig");
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/arm/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/arm/lib.zig");
        };
    };

    pub const avr: type = struct {
        pub const arch: type = @import("kernel/arch/avr/avr.zig");
        pub const entry: type = @import("kernel/entries/avr/entry.zig");
        pub const interrupts: type = @import("kernel/interrupts/avr/avr_interrupts.zig");
        pub const linker: type = @import("linkers/avr/avr-linker.zig");
        pub const mm: type = @import("mm/avr/mm.zig");
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/avr/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/avr/lib.zig");
        };
    };

    pub const xtensa: type = struct {
        pub const arch: type = @import("kernel/arch/xtensa/xtensa.zig");
        pub const entry: type = @import("kernel/entries/xtensa/entry.zig");
        pub const interrupts: type = @import("kernel/interrupts/xtensa/xtensa_interrupts.zig");
        pub const linker: type = @import("linkers/xtensa/xtensa-linker.zig");
        pub const mm: type = @import("mm/xtensa/mm.zig");
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/xtensa/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/xtensa/lib.zig");
        };
    };
};
pub const arch: type = SelectedArch.arch;
pub const entry: type = SelectedArch.entry;
pub const init: type = SelectedArch.init;
pub const interrupts: type = SelectedArch.interrupts;
pub const linker: type = SelectedArch.linker;
pub const mm: type = SelectedArch.mm;
pub const core: type = struct {
    pub const module: type = @import("kernel/core/module/module.zig");
    pub const paging: type = @import("kernel/core/paging/paging.zig");
    pub const vfs: type = @import("kernel/core/vfs/vfs.zig");
    pub const devices: type = @import("kernel/core/devices/devices.zig");
    pub const fs: type = @import("kernel/core/fs/fs.zig");
    pub const drivers: type = @import("kernel/core/drivers/drivers.zig");
};
pub const loader: type = @import("kernel/loader.zig");
pub const modules: type = @import("modules.zig");
pub const interfaces: type = struct {
    pub const devices: type = @import("lib/saturn/interfaces/devices.zig");
    pub const fs: type = @import("lib/saturn/interfaces/fs.zig");
    pub const module: type = @import("lib/saturn/interfaces/module.zig");
    pub const arch: type = @import("lib/saturn/interfaces/arch.zig");
    pub const vfs: type = @import("lib/saturn/interfaces/vfs.zig");
    pub const drivers: type = @import("lib/saturn/interfaces/drivers.zig");
};
pub const supervisor: type = @import("kernel/supervisor/supervisor.zig"); // NOTE: Tmp Obsolete
pub const lib: type = struct {
    pub const kernel: type = struct {
        pub const memory: type = @import("lib/saturn/kernel/memory/memory.zig");
        pub const utils: type = @import("lib/saturn/kernel/utils/utils.zig");
        pub const arch: type = SelectedArch.lib.kernel;
    };
    pub const userspace: type = SelectedArch.lib.userspace;
};
pub const config: type = struct {
    pub const modules: type = @import("config/modules/config.zig");
    pub const arch: type = @import("config/arch/config.zig");
    pub const compile: type = @import("config/compile/config.zig");
    pub const kernel: type = if(!@hasDecl(SelectedArch, "config")) @import("config/kernel/config.zig") else
        SelectedArch.config
    ;
};
pub const decls: type = @import("kernel/decls.zig");
pub const step: type = @import("kernel/step/step.zig");
