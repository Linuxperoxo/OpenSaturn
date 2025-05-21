// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vga.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const libsat: type = @import("root").libsat;
const drivers: type = @import("root").drivers;
const video: type = @import("root").drivers.video;
const fs: type = @import("root").fs;

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

pub const BackgroundColor: type = enum(u3) {
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

const VGAAttributes: type = enum(u4) {
    @"XPos",
    @"YPos",
    @"ForegroundColor",
    @"BackgroundColor",
};

const VGA_CTRL_PORT: u16 = 0x3D4;
const VGA_DATA_PORT: u16 = 0x3D5;

const VGA_PIXELS_X_RESOLUTION: u16 = 640;
const VGA_PIXELS_Y_RESOLUTION: u16 = 400;

const VGA_FONT_8x16_X_LEN: u8 = VGA_FONT_8x16_X_LEN / 8;
const VGA_FONT_8x16_Y_LEN: u8 = VGA_FONT_8x16_Y_LEN / 16;

const VGA_ROW_LEN: u8 = 25;
const VGA_COL_LEN: u8 = 80;

const VGAContext: type = struct {
    Framebuffer: []u16,
    XPos: u8,
    YPos: u8,
    Foreground: ForegroundColor,
    Background: BackgroundColor,

    fn write(This: *@This(), Data: u8) void {
        This.Framebuffer[VGA_COL_LEN * This.YPos + This.XPos] = @as(u16, (((@as(u8, @intFromEnum(This.Background)) << 4) & 0b01110000) | @as(u16, @intFromEnum(This.Foreground))) << 8 | Data);
        This.XPos = This.XPos + 1;

        // TODO: Verificação de índice deve ser feita pelo tty
        //if(This.XPos >= VGA_COL_LEN) {
        //    This.XPos = 0;
        //    This.YPos = This.YPos + 1;
        //
        //    if(This.YPos >= VGA_ROW_LEN) {
        //        This.down();
        //        This.YPos = VGA_ROW_LEN - 1;
        //    }
        //}
        This.patt();
    }

    fn down(This: *@This()) void {
        for(0..comptime VGA_ROW_LEN - 1) |y| {
            for(0..comptime VGA_COL_LEN - 1) |x| {
                This.Framebuffer[y * VGA_COL_LEN + x] = This.Framebuffer[(y + 1) * VGA_COL_LEN + x];
            }
        }

        for(0..comptime VGA_COL_LEN - 1) |i| {
            This.Framebuffer[@as(u16, VGA_ROW_LEN) * @as(u16, VGA_COL_LEN) + i] = @as(u16, (((@as(u8, @intFromEnum(This.Background)) << 4) & 0b01110000) | @as(u16, @intFromEnum(This.Foreground))) << 8 | 0);
        }

        This.XPos = 0;
        This.YPos = VGA_ROW_LEN - 1;

        This.patt();
    }

    fn patt(This: *@This()) void {
        const offset: u16 = VGA_COL_LEN * This.YPos + This.XPos;

        libsat.io.ports.outb(VGA_CTRL_PORT, 0x0F); // NOTE: Selecionando o registrador 0x0F (Parte menos significativa da posição do cursor)
        libsat.io.ports.outb(VGA_DATA_PORT, @intCast(offset));

        libsat.io.ports.outb(VGA_CTRL_PORT, 0x0E); // NOTE: Selecionando o registrador 0x0E (Parte mais significativa da posição do cursor)
        libsat.io.ports.outb(VGA_DATA_PORT, @intCast((offset >> 8) & 0xFF));
    }

    fn clear(This: *@This()) void {
        for(0..comptime @as(u16, VGA_ROW_LEN) * @as(u16, VGA_COL_LEN) - 1) |i| {
            This.Framebuffer[i] = @as(u16, ((@as(u8, @intFromEnum(This.Background)) << 4) & 0b01110000) | @as(u8, @intFromEnum(This.Foreground))) << 8 | 0;
        }
    }

    fn color(This: *@This(), Foreground: ForegroundColor, Background: BackgroundColor) void {
        This.Foreground = Foreground;
        This.Background = Background;
    }
};

var VGADevice: VGAContext = .{
    .Framebuffer = @as([*]u16, @ptrFromInt(0xB8000))[0..@as(u16, VGA_ROW_LEN) * @as(u16, VGA_COL_LEN) - 1],
    .XPos = 0,
    .YPos = 0,
    .Foreground = .White,
    .Background = .Black,
};

fn send(Args: drivers.DriverCommand) drivers.DriverResponse {
    // OPTIMIZE: Fazer argumentos genericos para cada função
    //           para chmar elas usando array de ponteiros para
    //           funções do tipo (This: *VGAContext, Args: VGAArgs)

    return block0: {
        switch(@as(video.VideoCommand, @enumFromInt(Args.command))) {
            .@"write" => {
                var i: u32 = 0;
                while(Args.args[i] != 0) : (i += 1){
                    @call(.always_inline, &VGAContext.write, .{
                        &VGADevice, 
                        Args.args[i]}
                    );
                }
            },
        
            .@"down" => {
                @call(.never_inline, &VGAContext.down, .{
                    &VGADevice
                });
            },

            .@"clear" => {
                @call(.always_inline, &VGAContext.clear, .{
                    &VGADevice
                });
            },

            .@"attribute" => {
                // OPTIMIZE: Fazer array de ponteiros para funções aqui também,
                //           de preferencia usar funções inlines para ajudar no
                //           runtime

                switch(@as(VGAAttributes, @enumFromInt(Args.args[0]))) {
                    // OPTIMIZE: Também da para otimizar XPos e YPos usando ponteiros 
                    //           EXEMPLO:
                    //           var ptr: ?*u8 = switch(Args.args[0]) {
                    //              1 => &VGADevice.XPos,
                    //              2 => &VGADevice.YPos,
                    //              else => null,
                    //           }
                    //           ptr.* = Args.args[1];

                    .@"XPos" => {
                        if(Args.args[1] >= VGA_COL_LEN) {
                            break :block0 drivers.DriverResponse {
                                .err = .NotSupported,
                            };
                        }
                        VGADevice.XPos = Args.args[1];
                    },

                    .@"YPos" => {
                        if(Args.args[1] >= VGA_ROW_LEN) {
                            break :block0 drivers.DriverResponse {
                                .err = .NotSupported,
                            };
                        }
                    },

                    .@"ForegroundColor" => {
                        VGADevice.Foreground = @enumFromInt(Args.args[1] & 0x04);
                    },

                    .@"BackgroundColor" => {
                        VGADevice.Foreground = @enumFromInt(Args.args[1] & 0x03);
                    },
                }
            },
        }

        break :block0 drivers.DriverResponse {
            .err = .Noerror,
        };
    };
}

fn receive(Args: drivers.DriverCommand) drivers.DriverResponse {
    // OPTIMIZE: Fazer argumentos genericos para cada função
    //           para chamar elas usando array de ponteiros para
    //           funções do tipo (This: *VGAContext)

    return block0: {
        switch(@as(VGAAttributes, @enumFromInt(Args.args[0]))) {
            // OPTIMIZE: Aqui o XPos e o YPos também podem ser otimizados
            //           usando ponteiros, igual o write()

            .@"XPos" => {
                break :block0 drivers.DriverResponse {
                   .ret = @as(u32, VGADevice.XPos),
                };
            },

            .@"YPos" => {
                break :block0 drivers.DriverResponse {
                    .ret = @as(u32, VGADevice.YPos),
                };
            },

            .@"ForegroundColor" => {
                break :block0 drivers.DriverResponse {
                    .ret = @as(u32, @intFromEnum(VGADevice.Foreground)),
                };
            },

            .@"BackgroundColor" => {
                break :block0 drivers.DriverResponse {
                    .ret = @as(u32, @intFromEnum(VGADevice.Background)),
                };
            },
        }
    };
}

pub fn init() u32 {
    @call(.never_inline,
        &fs.mkdev,
        .{
            "/dev/fb0",
            fs.devfs.DeviceFilesystem {
                .type = .char,
                .device = .{ 
                    .driver = &drivers.DriverInterface {
                        .IOctrl = .{
                            .receive = &receive,
                            .send = &send,
                        }
                    }
                },
            }
        }
    );
}

pub fn exit() u32 {
    @call(
        .never_inline, 
        &fs.rmdev, 
        .{
            "/dev/fb0"
        }
    );
}
