// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: msr.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub const MsrReturn: type = packed struct {
    low: u32,
    high: u32,
};

pub fn wrmsr(msr: u32, low: u32, high: u32) void {
    asm volatile(
        \\ wrmsr

        :
        :[_] "{ecx}" (msr),
         [_] "{eax}" (low),
         [_] "{edx}" (high)
        : .{}
    );
}

pub fn rdmsr(msr: u32) MsrReturn {
    var low: u32 = undefined;
    var high: u32 = undefined;

    asm volatile(
        \\ rdmsr

        :[_] "={eax}" (low),
         [_] "={edx}" (high)
        :[_] "{ecx}" (msr)
        : .{}
    );

    return MsrReturn {
        .low = low,
        .high = high,
    };
}
