// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: fstab.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// Esse arquivo e responsavel por fazer a montagem dos sistemas de
// arquivos no momento da inicializacao, todos os sistemas de arquivos
// colocados aqui, sempre vao ser montados, e esse comportamento nao podera
// ser mudado a nao ser recompilando o kernel sem esse fs posto em MountFileSystem.

// O ideal e que o MountFileSystem tenha pelo menos um sistema de arquivos que seja
// montado em /, nao ter nenhum sistema de arquivo nao vai impedir o funcionamento do
// kernel, para sistemas que nao precisam disso, como em embarcados, pode ser util.



// --- TO MOUNT ---
pub const MountFileSystem = [_]type {
    @import("internal/rootfs/module.zig"),
};



pub fn mountFilesystem() void {
    inline for(MountFileSystem) |_| {
        // mount(fs.__linkable_module_name__, fs.__linkable_module_mountpoint__)
    }
}
