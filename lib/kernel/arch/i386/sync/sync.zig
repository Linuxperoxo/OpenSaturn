pub const Spinlock: type = @import("Spinlock.zig");

pub inline fn spinLoopHint() void {
    // Instrucao sem operacao que pode indicar economia (ou compartilhamento
    // com uma thread de hardware) de recursos de pipeline/energia
    // https://software.intel.com/content/www/us/en/develop/articles/benefitting-power-and-performance-sleep-loops.html
    asm volatile ("pause");
}
