// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vga.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const saturn: type = @import("saturn").ports;

const VgaCtrPort: u16 = 0x3D4;
const VgaDataPort: u16 = 0x3D5;
const VgaYLen: u8 = 25;
const VgaXLen: u8 = 80;

pub const VgaCharColor: type = enum(u8) {
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

pub const VgaBackColor: type = enum(u8) {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Purple,
    Brown,
    Gray,
};

pub const VgaState: type = struct {
    Framebuffer: []u16 = undefined,
    XPos: u16 = 0,
    YPos: u16 = 0,
    CharColor: VgaCharColor = .White,
    BackColor: VgaBackColor = .Black,

    pub fn write(this: *VgaState, char: u8) void {
        this.Framebuffer[VgaXLen * this.YPos + this.XPos] = @as(u16, (((@intFromEnum(this.BackColor) << 4) & 0x70) | @intFromEnum(this.CharColor))) << 8 | char;
        
        this.XPos = blockX: {
            if(this.XPos >= VgaXLen) {
                this.YPos = blockY: {
                    if(this.YPos >= VgaYLen) {
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

    pub fn resize(this: *const VgaState) void {
        for(0..comptime VgaYLen - 1) |y| {
            for(0..comptime VgaXLen - 1) |x| {
                this.Framebuffer[y * VgaXLen + x] = this.Framebuffer[(y + 1) * VgaXLen + x];
            }
        }

        for(0..comptime VgaXLen - 1) |i| {
            this.Framebuffer[VgaYLen * VgaXLen + i] = @as(u16, (((this.BackColor << 4) & 0b01110000) | this.CharColor) << 8 | 0);
        }

        this.XPos = 0;
        this.YPos = VgaYLen - 1;

        patt(this);
    }

    pub fn patt(this: *const VgaState) void {
        const offset: u16 = VgaXLen * this.YPos + this.XPos;

        saturn.outb(VgaCtrPort, 0x0F); // NOTE: Selecionando o registrador 0x0F (Parte menos significativa da posição do cursor)
        saturn.outb(VgaDataPort, @intCast(offset));

        saturn.outb(VgaCtrPort, 0x0E); // NOTE: Selecionando o registrador 0x0E (Parte mais significativa da posição do cursor)
        saturn.outb(VgaDataPort, @intCast((offset >> 8) & 0xFF));
    }

    pub fn clear(this: *const VgaState) void {
        for(0..comptime VgaYLen * VgaXLen) |i| {
            this.Framebuffer[i] = (((this.BackColor << 4) & 0b01110000) | this.CharColor) << 8 | 0;
        }
    }
};
