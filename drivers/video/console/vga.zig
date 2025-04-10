// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vga.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const libsat: type = @import("saturn/lib");

const CtrPort: u16 = 0x3D4;
const DataPort: u16 = 0x3D5;
const YLen: u8 = 25;
const XLen: u8 = 80;
const Framebuffer: []u16 = undefined;

comptime {
    Framebuffer.ptr = @ptrFromInt(0xB8000);
    Framebuffer.len = 80 * 25;
}

pub const CharColor: type = enum(u4) {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Purple,
    Brown,
    Gray,
    DarkGray,
    Yellow = 0x0E,
    White = 0x0F,
};

pub const BackColor: type = enum(u4) {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Purple,
    Brown,
    Gray,
};

pub const State: type = struct {
    Framebuffer: []u16 = undefined,
    XPos: u16 = 0,
    YPos: u16 = 0,
    CharColor: CharColor = .White,
    BackColor: BackColor = .Black,

    pub fn write(this: *State, char: u8) void {
        this.Framebuffer[XLen * this.YPos + this.XPos] = @as(u16, (((@intFromEnum(this.BackColor) << 4) & 0x70) | @intFromEnum(this.CharColor))) << 8 | char;

        this.XPos = blockX: {
            if(this.XPos >= XLen) {
                this.YPos = blockY: {
                    if(this.YPos >= YLen) {
                        this.resize();
                    }
                    break :blockY this.YPos;
                };
                break :blockX 0;
            }
            break :blockX this.XPos + 1;
        };
        this.patt();
    }

    pub fn resize(this: *const State) void {
        for(0..comptime YLen - 1) |y| {
            for(0..comptime XLen - 1) |x| {
                this.Framebuffer[y * XLen + x] = this.Framebuffer[(y + 1) * XLen + x];
            }
        }

        for(0..comptime XLen - 1) |i| {
            this.Framebuffer[YLen * XLen + i] = @as(u16, (((this.BackColor << 4) & 0b01110000) | this.CharColor) << 8 | 0);
        }

        this.XPos = 0;
        this.YPos = YLen - 1;

        this.patt();
    }

    pub fn patt(this: *const State) void {
        const offset: u16 = XLen * this.YPos + this.XPos;

        libsat.io.ports.outb(CtrPort, 0x0F); // NOTE: Selecionando o registrador 0x0F (Parte menos significativa da posição do cursor)
        libsat.io.ports.outb(DataPort, @intCast(offset));

        libsat.io.ports.outb(CtrPort, 0x0E); // NOTE: Selecionando o registrador 0x0E (Parte mais significativa da posição do cursor)
        libsat.io.ports.outb(DataPort, @intCast((offset >> 8) & 0xFF));
    }

    pub fn clear(this: *const State) void {
        for(0..comptime YLen * XLen) |i| {
            this.Framebuffer[i] = (((this.BackColor << 4) & 0b01110000) | this.CharColor) << 8 | 0;
        }
    }
};
