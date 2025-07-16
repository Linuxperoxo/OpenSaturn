const idtEntry_T: type = @import("interfaces.zig").idtEntry_T;
const lidt_T: type = @import("interfaces.zig").lidt_T;

fn toString(comptime N: usize) []const u8 {
    const counter = sla: {
        var n: usize = N;
        var i: usize = 0;
        while(n != 0) : (i += 1) {
            n = n / 10;
        }
        break :sla i;
    };
    var string: [counter]u8 = undefined;
    var num: usize = N;
    for(0..counter) |i| {
        string[counter - (i + 1)] = (@as(u8, @intCast(num % 10))) + '0';
        num = num / 10;
    }
    return string[0..counter];
}

comptime {
    const exceptionsBaseName: []u8 = "exception";
    for(0..32) |i| {
        @export(fn() void, .{
            .name = exceptionsBaseName ++ toString(i),
        });
    }
}

const idtEntries: packed struct {cpuExceptions: [32]idtEntry_T, intRequest: [24]idtEntry_T} = .{
    .cpuExceptions = .{ // Interrupçoes do processador, erro de software
    },
    .intRequest = .{ // Vem do IOAPIC, gerado por IO
    },
};

