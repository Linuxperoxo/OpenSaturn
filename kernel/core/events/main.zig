// ┌─────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: main.zig    │
// │            Author: Linuxperoxo              │
// └─────────────────────────────────────────────┘

// TODO: ter a possibilidade de juntar 2 ou mais events no mesmo bus-line,
// o iterator iria chamar todos os listener de cada um, mandando um identificador,
// no caso, o identificador de qual evento esta mandando aquilo, e o dado, assim
// poderiamos fazer em vez de um para keyboard_event e outros para mouse_event,
// poderiamos fazer IO_event. O listener so iria precisar colocar na sua struct
// qual o identificador ele deve escutar, e todos os outros sao ignorados

const aux: type = @import("aux.zig");
const types: type = @import("types.zig");
const allocators: type = @import("allocators.zig");

var event_buses = [_]types.EventBus_T {
    types.EventBus_T {
        .line = [_]?*types.EventInfo_T {
            null
        } ** 8,
    },
} ** 4;

inline fn check_path(bus: u2, line: u3) bool {
    return if(event_buses[bus].line[line] != null) true else false;
}

inline fn ret_event(bus: u2, line: u3) *types.EventInfo_T {
    return event_buses[bus].line[line].?;
}

inline fn listeners_iterator(
    event_info: *types.EventInfo_T,
    comptime handler: *const fn(*types.EventListener_T, usize) anyerror!void
) types.EventErr_T!void {
    var i: usize = 0;
    while(event_info.listeners.iterator()) |listener| {
        @call(.always_inline, handler, .{
            listener, i
        }) catch return types.EventErr_T.IteratorForceExit;
        i += 1;
    } else |err| {
        switch(err) {
            @TypeOf(event_info.listeners).ListErr_T.EndOfInterator => {},
            else => return types.EventErr_T.ListenerInteratorFailed,
        }
    }
}

pub fn install_event(event: *types.Event_T, comptime default: ?types.EventDefault_T) types.EventErr_T!void {
    const bus, const line = if(default != null) aux.default_bus(default.?) else .{
        event.bus,
        event.line
    };
    if(check_path(bus, line)) return types.EventErr_T.EventCollision;
    event_buses[bus].line[line] = &(allocators.sba.allocator.alloc(
        types.EventInfo_T, 1
    ) catch return types.EventErr_T.AllocFailed)[0];
    event_buses[bus].line[line].?.event = event;
    event_buses[bus].line[line].?.listeners.private = null; // garantindo uma lista vazia
}

// quando tiver ktask, vamos ter um novo parametro, que vai enviar para todos de uma vez
// de 1 em 1, ou de metade em metade, quem vai gerenciar isso vai ser i ktask
pub fn send_event(event: *types.Event_T, out: types.EventOut_T) types.EventErr_T!void {
    if(!check_path(event.bus, event.line)) return types.EventErr_T.NoNEvent;
    const event_info = ret_event(event.bus, event.line);
    try listeners_iterator(
        event_info,
        &opaque {
            pub fn handler(listener: *types.EventListener_T, _: usize) anyerror!void {
                const listener_out = listener.handler(out);
                if(event_info.event.listener_out != null) {
                    event_info.event.listener_out.?(listener_out);
                }
            }
        }.handler,
    );
}

pub fn remove_event(event: *types.Event_T) types.EventErr_T!void {
    if(!check_path(event.bus, event.line)) return types.EventErr_T.NoNEvent;
    const event_info = ret_event(event.bus, event.line);
    try listeners_iterator(
        event_info,
        &opaque {
            pub fn handler(listener: *types.EventListener_T, _: usize) anyerror!void {
                listener.flags.listen = 0;
            }
        }.handler,
    );
    allocators.sba.allocator.free(event_info)
        catch return types.EventErr_T.FreeEventFailed;
}

pub fn install_listener_event(
    listener: *types.EventListener_T,
    comptime bus_line: union(enum(u1)) {
        default: types.EventDefault_T,
        explicit: struct {
            bus: u2,
            line: u3,
        },
    }
) types.EventErr_T!void {
    const bus, const line = switch(bus_line) {
        .default => aux.default_bus(bus_line.default),
        .explicit => .{
            bus_line.explicit.bus,
            bus_line.explicit.line
        },
    };
    if(!check_path(bus, line)) return types.EventErr_T.NoNEvent;
    const event_info = ret_event(bus, line);
    event_info.listeners.push_in_list(&allocators.sba.allocator, listener)
        catch return types.EventErr_T.NoNListenerInstall;
}

pub fn remove_listener_event(
    listener: *types.EventListener_T,
    comptime bus_line: union(enum(u1)) {
        default: types.EventDefault_T,
        explicit: struct {
            bus: u2,
            line: u3,
        },
    }
) types.EventErr_T!void {
    const bus, const line = switch(bus_line) {
        .default => aux.default_bus(bus_line.default),
        .explicit => .{
            bus_line.explicit.bus,
            bus_line.explicit.line
        },
    };
    if(!check_path(bus, line)) return types.EventErr_T.NoNEvent;
    const event_info = ret_event(bus, line);
    listeners_iterator(
        event_info,
        &opaque {
            pub fn handler(listener_iterator: *types.EventListener_T, index: usize) anyerror!void {
                if(listener_iterator == listener) {
                    // o allocator passado libera o no da lista, nao o que tem nela
                    event_info.listeners.drop_on_list(index, &allocators.sba.allocator);
                    return error.Found;
                }
            }
        }.handler,
    ) catch |err| switch(err) {
        types.EventErr_T.IteratorForceExit => return,
        else => return types.EventErr_T.RemoveListenerInternalError
    };
    return types.EventErr_T.NoNListenerInstall;
}
