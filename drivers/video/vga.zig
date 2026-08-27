// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: vga.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const libsat: type = @import("root").libsat;
const drivers: type = @import("root").drivers;
const video: type = @import("root").drivers.video;
const fs: type = @import("root").fs;

pub const ForegroundColor: type = enum(u4) {
    black,
    blue,
    green,
    cyan,
    red,
    purple,
    brown,
    light_gray,
    dark_gray,
    light_blue,
    light_green,
    light_cyan,
    light_red,
    light_magenta,
    yellow,
    white,
};

pub const BackgroundColor: type = enum(u3) {
    black,
    blue,
    green,
    cyan,
    red,
    purple,
    brown,
    light_gray,
};

const VGAArgs: type = struct {
    arg_0: u8 = 0,
    arg_1: u8 = 0,
};

const VGAAttributes: type = enum(u4) {
    x_pos,
    y_pos,
    foreground_color,
    background_color,
};

const vga_ctrl_port: u16 = 0x3D4;
const vga_data_port: u16 = 0x3D5;

const vga_pixels_x_resolution: u16 = 640;
const vga_pixels_y_resolution: u16 = 400;

const vga_font_8x16_x_len: u8 = vga_font_8x16_x_len / 8;
const vga_font_8x16_y_len: u8 = vga_font_8x16_y_len / 16;

const vga_row_len: u8 = 25;
const vga_col_len: u8 = 80;

const VGAContext: type = struct {
    framebuffer: []u16,
    x_pos: u8,
    y_pos: u8,
    foreground: ForegroundColor,
    background: BackgroundColor,

    fn write(self: *@This(), data: u8) void {
        self.framebuffer[vga_col_len * self.y_pos + self.x_pos] = @as(u16, (((@as(u8, @intFromEnum(self.background)) << 4) & 0b01110000) | @as(u16, @intFromEnum(self.foreground))) << 8 | data);
        self.x_pos = self.x_pos + 1;

        // TODO: Verificação de índice deve ser feita pelo tty
        //if(self.x_pos >= vga_col_len) {
        //    self.x_pos = 0;
        //    self.y_pos = self.y_pos + 1;
        //
        //    if(self.y_pos >= vga_row_len) {
        //        self.down();
        //        self.y_pos = vga_row_len - 1;
        //    }
        //}
        self.patt();
    }

    fn down(self: *@This()) void {
        for(0..comptime vga_row_len - 1) |y| {
            for(0..comptime vga_col_len - 1) |x| {
                self.framebuffer[y * vga_col_len + x] = self.framebuffer[(y + 1) * vga_col_len + x];
            }
        }

        for(0..comptime vga_col_len - 1) |i| {
            self.framebuffer[@as(u16, vga_row_len) * @as(u16, vga_col_len) + i] = @as(u16, (((@as(u8, @intFromEnum(self.background)) << 4) & 0b01110000) | @as(u16, @intFromEnum(self.foreground))) << 8 | 0);
        }

        self.x_pos = 0;
        self.y_pos = vga_row_len - 1;

        self.patt();
    }

    fn patt(self: *@This()) void {
        const offset: u16 = vga_col_len * self.y_pos + self.x_pos;

        libsat.io.ports.outb(vga_ctrl_port, 0x0F); // NOTE: Selecionando o registrador 0x0F (Parte menos significativa da posição do cursor)
        libsat.io.ports.outb(vga_data_port, @intCast(offset));

        libsat.io.ports.outb(vga_ctrl_port, 0x0E); // NOTE: Selecionando o registrador 0x0E (Parte mais significativa da posição do cursor)
        libsat.io.ports.outb(vga_data_port, @intCast((offset >> 8) & 0xFF));
    }

    fn clear(self: *@This()) void {
        for(0..comptime @as(u16, vga_row_len) * @as(u16, vga_col_len) - 1) |i| {
            self.framebuffer[i] = @as(u16, ((@as(u8, @intFromEnum(self.background)) << 4) & 0b01110000) | @as(u8, @intFromEnum(self.foreground))) << 8 | 0;
        }
    }

    fn color(self: *@This(), foreground: ForegroundColor, background: BackgroundColor) void {
        self.foreground = foreground;
        self.background = background;
    }
};

var vga_device: VGAContext = .{
    .framebuffer = @as([*]u16, @ptrFromInt(0xB8000))[0..@as(u16, vga_row_len) * @as(u16, vga_col_len) - 1],
    .x_pos = 0,
    .y_pos = 0,
    .foreground = .white,
    .background = .black,
};

fn send(args: drivers.DriverCommand) drivers.DriverResponse {
    // OPTIMIZE: Fazer argumentos genericos para cada função
    //           para chmar elas usando array de ponteiros para
    //           funções do tipo (This: *VGAContext, Args: VGAArgs)

    return block0: {
        switch(@as(video.VideoCommand, @enumFromInt(args.command))) {
            .@"write" => {
                var i: u32 = 0;
                while(args.args[i] != 0) : (i += 1){
                    @call(.always_inline, &VGAContext.write, .{
                        &vga_device,
                        args.args[i]}
                    );
                }
            },
        
            .@"down" => {
                @call(.never_inline, &VGAContext.down, .{
                    &vga_device
                });
            },

            .@"clear" => {
                @call(.always_inline, &VGAContext.clear, .{
                    &vga_device
                });
            },

            .@"attribute" => {
                // OPTIMIZE: Fazer array de ponteiros para funções aqui também,
                //           de preferencia usar funções inlines para ajudar no
                //           runtime

                switch(@as(VGAAttributes, @enumFromInt(args.args[0]))) {
                    // OPTIMIZE: Também da para otimizar XPos e YPos usando ponteiros 
                    //           EXEMPLO:
                    //           var ptr: ?*u8 = switch(Args.args[0]) {
                    //              1 => &VGADevice.XPos,
                    //              2 => &VGADevice.YPos,
                    //              else => null,
                    //           }
                    //           ptr.* = Args.args[1];

                    .x_pos => {
                        if(args.args[1] >= vga_col_len) {
                            break :block0 drivers.DriverResponse {
                                .err = .NotSupported,
                            };
                        }
                        vga_device.x_pos = args.args[1];
                    },

                    .y_pos => {
                        if(args.args[1] >= vga_row_len) {
                            break :block0 drivers.DriverResponse {
                                .err = .NotSupported,
                            };
                        }
                    },

                    .foreground_color => {
                        vga_device.foreground = @enumFromInt(args.args[1] & 0x04);
                    },

                    .background_color => {
                        vga_device.foreground = @enumFromInt(args.args[1] & 0x03);
                    },
                }
            },
        }

        break :block0 drivers.DriverResponse {
            .err = .Noerror,
        };
    };
}

fn receive(args: drivers.DriverCommand) drivers.DriverResponse {
    // OPTIMIZE: Fazer argumentos genericos para cada função
    //           para chamar elas usando array de ponteiros para
    //           funções do tipo (This: *VGAContext)

    return block0: {
        switch(@as(VGAAttributes, @enumFromInt(args.args[0]))) {
            // OPTIMIZE: Aqui o XPos e o YPos também podem ser otimizados
            //           usando ponteiros, igual o write()

            .x_pos => {
                break :block0 drivers.DriverResponse {
                   .ret = @as(u32, vga_device.x_pos),
                };
            },

            .y_pos => {
                break :block0 drivers.DriverResponse {
                    .ret = @as(u32, vga_device.y_pos),
                };
            },

            .foreground_color => {
                break :block0 drivers.DriverResponse {
                    .ret = @as(u32, @intFromEnum(vga_device.foreground)),
                };
            },

            .background_color => {
                break :block0 drivers.DriverResponse {
                    .ret = @as(u32, @intFromEnum(vga_device.background)),
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
