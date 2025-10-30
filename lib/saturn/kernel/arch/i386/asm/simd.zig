// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: simd.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

pub inline fn movaps(xmm: u128, dest: *anyopaque) void {
    asm volatile(
        \\ movaps %xmm0, (%edi)
        :
        :[_] "{xmm0}" (xmm),
         [_] "{edi}" (dest)
    );
}

pub inline fn movups(xmm: u128, dest: *anyopaque) void {
    asm volatile(
        \\ movups %xmm0, (%edi)
        :
        :[_] "{xmm0}" (xmm),
         [_] "{edi}" (dest)
    );
}

pub inline fn ldaps(dest: *anyopaque) u128 {
    asm volatile(
        \\ movaps (%edi), %xmm0
        :[_] "={xmm0}" (-> u128)
        :[_] "{edi}" (dest)
    );
}

pub inline fn ldups(dest: *anyopaque) u128 {
    return asm volatile(
        \\ movups (%edi), %xmm0
        :[_] "={xmm0}" (-> u128)
        :[_] "{edi}" (dest)
    );
}

pub inline fn addps(xmm0: u128, xmm1: u128) u128 {
    return asm volatile(
        \\ addps %xmm0, %xmm1
        :[_] "={xmm1}" (-> u128)
        :[_] "{xmm0}" (xmm0),
         [_] "{xmm1}" (xmm1),
    );
}

