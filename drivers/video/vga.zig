// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vga.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const libsat: type = @import("root").libsat;
const drivers: type = @import("root").drivers;
const video: type = @import("root").video;

pub const ForegroundColor: type = enum(u4) {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Purple,
    Brown,
    LightGray,
    DarkGray,
    LightBlue,
    LightGreen,
    LightCyan,
    LightRed,
    LightMagenta,
    Yellow,
    White,
};

pub const BackgroundColor: type = enum(u4) {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Purple,
    Brown,
    LightGray,
};

const VGAArgs: type = struct {
    @"0": u8 = 0,
    @"1": u8 = 0,
};

const VGA_CTR_PORT: u16 = 0x3D4;
const VGA_DATA_PORT: u16 = 0x3D5;
const VGA_ROW_LEN: u8 = 25;
const VGA_COL_LEN: u8 = 80;

const VGAContext: type = struct {
    Framebuffer: [*]u16 = @as([*]u16, @ptrFromInt(0xB8000)),
    XPos: u16 = 0,
    YPos: u16 = 0,
    CharColor: ForegroundColor = .White,
    BackColor: BackgroundColor = .Black,

    fn write(this: *@This(), args: VGAArgs) void {
        this.Framebuffer[VGA_COL_LEN * this.YPos + this.XPos] = @as(u16, (((@as(u8, @intFromEnum(this.BackColor)) << 4) & 0b01110000) | @as(u16, @intFromEnum(this.CharColor))) << 8 | args.@"0");

        this.XPos = blockX: {
            if(this.XPos >= VGA_COL_LEN) {
                this.YPos = blockY: {
                    if(this.YPos >= VGA_ROW_LEN) {
                        this.down();
                    }
                    break :blockY this.YPos;
                };
                break :blockX 0;
            }
            break :blockX this.XPos + 1;
        };
        this.patt(.{.@"0" = @intCast(this.YPos), .@"1" = @intCast(this.XPos)});
    }

    fn down(this: *@This()) void {
        for(0..comptime VGA_ROW_LEN - 1) |y| {
            for(0..comptime VGA_COL_LEN - 1) |x| {
                this.Framebuffer[y * VGA_COL_LEN + x] = this.Framebuffer[(y + 1) * VGA_COL_LEN + x];
            }
        }

        for(0..comptime VGA_COL_LEN - 1) |i| {
            this.Framebuffer[@as(u16, VGA_ROW_LEN) * @as(u16, VGA_COL_LEN) + i] = @as(u16, (((@as(u8, @intFromEnum(this.BackColor)) << 4) & 0b01110000) | @as(u16, @intFromEnum(this.CharColor))) << 8 | 0);
        }

        this.XPos = 0;
        this.YPos = VGA_ROW_LEN - 1;

        this.patt(.{.@"0" = @intCast(this.YPos), .@"1" = @intCast(this.XPos)});
    }

    fn patt(_: *@This(), args: VGAArgs) void {
        const offset: u16 = VGA_COL_LEN * args.@"0" + args.@"1";

        libsat.io.ports.outb(VGA_CTR_PORT, 0x0F); // NOTE: Selecionando o registrador 0x0F (Parte menos significativa da posição do cursor)
        libsat.io.ports.outb(VGA_DATA_PORT, @intCast(offset));

        libsat.io.ports.outb(VGA_CTR_PORT, 0x0E); // NOTE: Selecionando o registrador 0x0E (Parte mais significativa da posição do cursor)
        libsat.io.ports.outb(VGA_DATA_PORT, @intCast((offset >> 8) & 0xFF));
    }

    fn clear(this: *@This()) void {
        for(0..comptime @as(u16, VGA_ROW_LEN) * @as(u16, VGA_COL_LEN) - 1) |i| {
            this.Framebuffer[i] = @as(u16, ((@as(u8, @intFromEnum(this.BackColor)) << 4) & 0b01110000) | @as(u8, @intFromEnum(this.CharColor))) << 8 | 0;
        }
    }

    fn color(this: *@This(), args: VGAArgs) void {
        this.CharColor = args.@"0";
        this.BackColor = args.@"1";
    }
};

var VGADevice: VGAContext = .{};

fn send(Args: drivers.DriverCommand) drivers.DriverResponse {
    switch(@as(video.VideoCommand, @enumFromInt(Args.command))) {
        .@"write" => {
            var i: u32 = 0;
            while(Args.args[i] != 0) : (i += 1){
                VGADevice.write(.{.@"0" = Args.args[i]});
            }
        },

        .@"clear" => VGADevice.clear(),
        .@"down" => VGADevice.down(),
        .@"setPtr" => VGADevice.patt(.{.@"0" = Args.args[0], .@"1" = Args.args[1]}),
        .@"setColor" => {
            VGADevice.CharColor = @enumFromInt(Args.args[0]);
            VGADevice.BackColor = @enumFromInt(Args.args[1]);
        }
    }

    return drivers.DriverResponse {
        .err = drivers.DriverError.Noerror,
    };
}

fn receive(Args: drivers.DriverCommand) drivers.DriverResponse {
    return drivers.DriverResponse {
        .ret = switch(@as(video.VideoQuery, @enumFromInt(Args.command))) { 
            .@"currentX" => @as(u32, VGADevice.XPos),
            .@"currentY" => @as(u32, VGADevice.YPos),
            .@"currentCColor" => @as(u32, @intFromEnum(VGADevice.CharColor)),
            .@"currentBColor" => @as(u32, @intFromEnum(VGADevice.BackColor)),
        },
    };
}

pub fn loadDriver() drivers.DriverInterface {
    return drivers.DriverInterface {
        .IOctrl = .{
            .send = &send,
            .receive = &receive,
        }
    };
}
