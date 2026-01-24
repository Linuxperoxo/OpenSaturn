// ┌─────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: csl.zig     │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

const modsys: type = @import("root").modsys.modules;
const config: type = @import("root").config;

// C Sources Loader

comptime {
    if(config.compile.options.CSupport) {
        for(modsys.saturn_modules) |module| {
            if(module.c_sources == null) continue;
            const c_sources: type = @cImport({
                for(module.c_sources.?) |c_source| {
                    @cInclude(c_source);
                }
            });
            _ = c_sources;
        }
    }
}
