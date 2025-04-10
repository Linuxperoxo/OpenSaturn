// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: gdt.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const KernelCode: u8 = 0x08;
const KernelData: u8 = 0x10;
const UserCode: u8 = 0x18;
const UserData: u8 = 0x20;

pub const Entries = [_] Entry {
    setEntry(
        0,
        0,
        0,
        0
    ),

    setEntry(
        0,
        0xFFFFF,
        0x0C,
        0x9A
    ),

    setEntry(
        0, 
        0xFFFFF, 
        0x0C, 
        0x92
    ),
};

pub const Entry: type = packed struct {
    SegLimitLow: u16,
    BaseLow: u16,
    BaseMid: u8,
    Access: u8,
    SegLimitHigh: u4,
    Gran: u4,
    BaseHigh: u8,
};

pub const Pointer: type = packed struct {
    Limit: u16,
    First: u32,
};

pub fn load(GDT: Pointer) void {
    asm volatile(
        \\ lgdt (%[GDT])

        \\ movw %[KData], %ax
        \\ movw %ax, %ds
        \\ movw %ax, %ss
        \\ movw %ax, %fs
        \\ movw %ax, %gs
        \\ movw %ax, %es

        \\ ljmp %[KCode], $1f

        \\ 1:

        :
        :[GDT] "r" (&GDT),
         [KCode] "i" (KernelCode),
         [KData] "i" (KernelData),
        :"ax"
    );
}

pub fn setEntry(comptime Base: u32, comptime Limit: u32, comptime Gran: u8, comptime Access: u8) Entry {
    return Entry {
        .BaseLow = @as(u16, (Base & 0xFFFF)),
        .BaseMid = @as(u8, (Base >> 16) & 0xFF),
        .BaseHigh = @as(u8, (Base >> 24) & 0xFF),
        .SegLimitLow = @as(u16, Limit & 0xFFFF),
        .SegLimitHigh = @as(u4, (Limit >> 16) & 0xF),
        .Access = Access,
        .Gran = @as(u4, Gran & 0x0F),
    };
}
