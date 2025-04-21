// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: msr.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const MsrReturn: type = packed struct {
    Low: u32,
    High: u32,
};

pub fn wrmsr(Msr: u32, Low: u32, High: u32) void {
    asm volatile(
        \\ wrmsr

        :
        :[_] "{ecx}" (Msr),
         [_] "{eax}" (Low),
         [_] "{edx}" (High)
        :
    );
}

pub fn rdmsr(Msr: u32) MsrReturn {
    var Low: u32 = undefined;
    var High: u32 = undefined;

    asm volatile(
        \\ rdmsr

        :[_] "={eax}" (Low),
         [_] "={edx}" (High)
        :[_] "{ecx}" (Msr)
        :
    );

    return MsrReturn {
        .Low = Low,
        .High = High,
    };
}
