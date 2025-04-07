const ports: type = @import("../../../lib/opensaturn/ports.zig");

const VgaCtrPort: u16 = 0x3D4;
const VgaDataPort: u16 = 0x3D5;
const VgaYLen: u8 = 25;
const VgaXLen: u8 = 80;

pub const VgaState: type = struct {
    Framebuffer: []u16 = undefined,
    XPos: u16 = 0,
    YPos: u16 = 0,
    CharColor: VgaCharColor = .White,
    BackColor: VgaBackColor = .Black,

    pub fn write(this: *const VgaState, char: u8) void {
        this.Framebuffer[VgaXLen * this.YPos + this.XPos] = @as(u16, (((@intFromEnum(this.BackColor) << 4) & 0x70) | @intFromEnum(this.CharColor))) << 8 | char;
    }

    pub fn resize(this: *const VgaState) void {
        for(0..comptime VgaYLen - 1) |y| {
            for(0..comptime VgaXLen - 1) |x| {
                this.Framebuffer[y * VgaXLen + x] = this.Framebuffer[(y + 1) * VgaXLen + x];
            }
        }

        for(0..comptime VgaXLen - 1) |i| {
            this.Framebuffer[VgaYLen * VgaXLen + i] = (((this.BackColor << 4) & 0b01110000) | this.CharColor) << 8 | 0;
        }

        this.XPos = 0;
        this.YPos = VgaYLen - 1;

        patt(this);
    }

    pub fn patt(this: *const VgaState) void {
        const offset: u16 = VgaXLen * this.YPos + this.XPos;
    
        ports.outb(VgaCtrPort, 0x0F); // NOTE: Selecionando o registrador 0x0F (Parte menos significativa da posição do cursor)
        ports.outb(VgaDataPort, offset & 0x00FF);

        ports.outb(VgaCtrPort, 0x0E); // NOTE: Selecionando o registrador 0x0E (Parte mais significativa da posição do cursor)
        ports.outb(VgaDataPort, (offset >> 8) & 0x00FF);
    }

    pub fn clear(this: *const VgaState) void {
        for(0..comptime VgaYLen * VgaXLen) |i| {
            this.Framebuffer[i] = (((this.BackColor << 4) & 0b01110000) | this.CharColor) << 8 | 0;
        }
    }
};

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
