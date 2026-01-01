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
    .i386 => Architectures.i386,
    .amd64 => Architectures.amd64,
    .arm => Architectures.arm,
    .avr => Architectures.avr,
    .xtensa => Architectures.xtensa,
    .riscv64 => unreachable, // TODO:
};
pub const cpu: type = struct {
    pub const arch: type = SelectedArch.arch;
    pub const entry: type = SelectedArch.entry;
    pub const linker: type = SelectedArch.linker;
    pub const lib: type = if(@hasDecl(SelectedArch, "lib")) SelectedArch.lib else void;
    pub const segments: type = if(@hasDecl(SelectedArch, "segments")) SelectedArch.segments else void;
    pub const init: type = if(@hasDecl(SelectedArch, "init")) SelectedArch.init else
            @compileError("this architecture has no implementation for \'init\'");
    pub const interrupts: type = if(@hasDecl(SelectedArch, "interrupts")) SelectedArch.interrupts else
        @compileError("this architecture has no implementation for \'interrupts\'");
    pub const physio: type = if(@hasDecl(SelectedArch, "physio")) SelectedArch.physio else
        @compileError("this architecture has no implementation for \'physio\'");
    pub const mm: type = if(@hasDecl(SelectedArch, "mm")) SelectedArch.mm else
        @compileError("this architecture has no implementation for \'mm\'");
};
pub const Architectures: type = struct {
    // Eu poderia usar usar o @tagName para construir o caminho
    // do arquivo para cada arquitetura, mas assim alem de ficar
    // mais visivel, abre a possibilidade de modificar o diretorio
    // ou o nome do arquivo
    pub const @"i386": type = struct {
        pub const arch: type = @import("kernel/arch/i386/i386.zig");
        pub const entry: type = @import("kernel/entries/i386/entry.zig");
        pub const init: type = @import("kernel/init/i386/init.zig");
        pub const interrupts: type = @import("kernel/interrupts/i386/interrupts.zig");
        pub const linker: type = @import("linkers/i386/linker.zig");
        pub const physio: type = @import("kernel/physio/i386/physio.zig");
        pub const mm: type = @import("mm/i386/mm.zig");
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/i386/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/i386/lib.zig");
        };
    };

    pub const amd64: type = struct {
        pub const arch: type = @import("kernel/arch/amd64/amd64.zig");
        pub const entry: type = @import("kernel/entries/amd64/entry.zig");
        pub const interrupts: type = @import("kernel/interrupts/amd64/interrupts.zig");
        pub const linker: type = @import("linkers/amd64/linker.zig");
        pub const mm: type = @import("mm/amd64/mm.zig");
        pub const lib: type = struct {
            pub const kernel: type = @import("lib/saturn/kernel/arch/amd64/lib.zig");
            pub const userspace: type = @import("lib/saturn/userspace/amd64/lib.zig");
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
pub const physio: type = cpu.physio;
pub const arch: type = cpu.arch;
pub const entry: type = cpu.entry;
pub const init: type = cpu.init;
pub const interrupts: type = cpu.interrupts;
pub const linker: type = cpu.linker;
pub const mm: type = cpu.mm;
pub const core: type = struct {
    pub const module: type = @import("kernel/core/module/module.zig");
    pub const vfs: type = @import("kernel/core/vfs/vfs.zig");
    pub const devices: type = @import("kernel/core/devices/devices.zig");
    pub const fs: type = @import("kernel/core/fs/fs.zig");
    pub const drivers: type = @import("kernel/core/drivers/drivers.zig");
    pub const events: type = @import("kernel/core/events/events.zig");
};
// no futuro o ioreg sera usado para todas as arquiteturas como uma forma
// de procurar devices, cada arch vai ter sua implementacao, mas ioreg
// vai fazer a mesma coisa que o sba e o soa faz por exemplo
//pub const ioreg: type = @import("kernel/core/ioreg/ioreg.zig");
pub const loader: type = @import("kernel/loader.zig");
pub const modules: type = @import("modules.zig");
pub const fusioners: type = @import("fusioners.zig");
pub const fusium: type = @import("kernel/fusium/core.zig");
pub const modsys: type = struct {
    pub const core: type = @import("kernel/modsys/modsys.zig");
    pub const smll: type = @import("kernel/modsys/smll.zig");
};
pub const interfaces: type = struct {
    pub const fusium: type = @import("kernel/fusium/fusium.zig");
    pub const devices: type = @import("lib/saturn/interfaces/devices.zig");
    pub const fs: type = @import("lib/saturn/interfaces/fs.zig");
    pub const module: type = @import("lib/saturn/interfaces/module.zig");
    pub const arch: type = @import("lib/saturn/interfaces/arch.zig");
    pub const vfs: type = @import("lib/saturn/interfaces/vfs.zig");
    pub const drivers: type = @import("lib/saturn/interfaces/drivers.zig");
    pub const events: type = @import("lib/saturn/interfaces/events.zig");
};
pub const supervisor: type = @import("kernel/supervisor/supervisor.zig"); // NOTE: Tmp Obsolete
pub const decls: type = @import("kernel/decls.zig");
pub const step: type = @import("kernel/step/step.zig");
pub const lib: type = struct {
    pub const kernel: type = struct {
        pub const memory: type = @import("lib/saturn/kernel/memory/memory.zig");
        pub const utils: type = @import("lib/saturn/kernel/utils/utils.zig");
        pub const arch: type = if(cpu.lib != void and @hasDecl(cpu.lib, "kernel")) cpu.lib.kernel else
            @compileError("this architecture has no implementation \'for lib/arch\'");
    };
    pub const userspace: type = if(cpu.lib != void and @hasDecl(cpu.lib, "userspace")) cpu.lib.userspace else
        @compileError("this architecture has no implementation for \'lib/arch/userspace\'");
};
pub const config: type = struct {
    pub const modules: type = @import("config/modules/config.zig");
    pub const arch: type = @import("config/arch/config.zig");
    pub const compile: type = @import("config/compile/config.zig");
    pub const fusium: type = @import("config/fusium/config.zig");
    pub const kernel: type = struct {
        pub const options: type = @import("config/kernel/options.zig");
        pub const mem: type = if(cpu.segments == void) @import("config/kernel/segments.zig") else
            cpu.segments
        ;
    };
};
