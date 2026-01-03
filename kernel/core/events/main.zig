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

// TODO: Adicionar prioridade para listeners

const aux: type = @import("aux.zig");
const types: type = @import("types.zig");
const allocators: type = @import("allocators.zig");

pub var event_buses = [_]types.EventBus_T {
    types.EventBus_T {
        .line = [_]?*types.EventInfo_T {
            null
        } ** 8,
    },
} ** 4;


pub fn install_event(event: *types.Event_T, comptime default: ?types.EventDefault_T) types.EventErr_T!void {
    const bus, const line = if(default != null) aux.default_bus(default.?) else .{
        event.bus,
        event.line
    };
    if(aux.check_path(bus, line)) return types.EventErr_T.EventCollision;
    event_buses[bus].line[line] = &(allocators.sba.allocator.alloc(
        types.EventInfo_T, 1
    ) catch return types.EventErr_T.AllocFailed)[0];
    if(default != null) {
        event.bus = bus;
        event.line = line;
    }
    event_buses[bus].line[line].?.event = event;
    event_buses[bus].line[line].?.listeners.private = null; // garantindo uma lista vazia
    event_buses[bus].line[line].?.listeners.init(&allocators.sba.allocator) catch
        return types.EventErr_T.ListInitFailed;
}

// quando tiver ktask, vamos ter um novo parametro, que vai enviar para todos de uma vez
// de 1 em 1, ou de metade em metade, quem vai gerenciar isso vai ser i ktask
pub fn send_event(event: *types.Event_T, out: types.EventOut_T) types.EventErr_T!void {
    if(!aux.check_path(event.bus, event.line)) return types.EventErr_T.NoNEvent;
    const event_info = aux.ret_event(event.bus, event.line);
    if(event_info.event.flags.control.active != 1) return types.EventErr_T.DisableEvent;
    const iterator_param: struct { ite_event: *types.EventInfo_T, event_out: types.EventOut_T } = .{
        .ite_event = event_info,
        .event_out = out,
    };
    _ = event_info.listeners.iterator_handler(
        iterator_param,
        &opaque {
            pub fn handler(listener: *types.EventListener_T, param: @TypeOf(iterator_param)) anyerror!void {
                // como no futuro teremos mais de 1 evento no bus_line, o listener precisa saber quem escutar
                if(listener.flags.control.satisfied == 0 and listener.listening == param.ite_event.event.who and (
                    // o listener pode escutar apenas um evento especifico ou todos
                    (listener.flags.control.all == 1 or listener.event == param.event_out.event)
                )) {
                    const listener_out = listener.handler(param.event_out);
                    if(param.ite_event.event.listener_out != null and listener_out != null) {
                        param.ite_event.event.listener_out.?(listener_out.?);
                    }
                }
                return error.Continue;
            }
        }.handler,
    ) catch |err| return switch(err) {
        @TypeOf(event_info.listeners).ListErr_T.EndOfIterator => {},
        else => return types.EventErr_T.ListenerInteratorFailed,
    };
}

pub fn remove_event(event: *types.Event_T) types.EventErr_T!void {
    if(!aux.check_path(event.bus, event.line)) return types.EventErr_T.NoNEvent;
    const event_info = aux.ret_event(event.bus, event.line);
    const iterator_param: void = {};
    _ = event_info.listeners.iterator_handler(
        iterator_param,
        &opaque {
            pub fn handler(listener: *types.EventListener_T, _: @TypeOf(iterator_param)) anyerror!void {
                listener.flags.internal.listen = 0;
                return error.Continue;
            }
        }.handler,
    ) catch |err| switch(err) {
        @TypeOf(event_info.listeners).ListErr_T.EndOfIterator => {},
        else => return types.EventErr_T.ListenerInteratorFailed,
    };
    const slice: []types.EventInfo_T = @as([*]types.EventInfo_T, @ptrCast(event_info))[0..1];
    allocators.sba.allocator.free(slice) catch return types.EventErr_T.FreeEventFailed;
    event_buses[event.bus].line[event.line] = null;
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
    if(!aux.check_path(bus, line)) return types.EventErr_T.NoNEvent;
    const event_info = aux.ret_event(bus, line);
    if((~event_info.event.flags.control.block & event_info.event.flags.control.active) != 1) return types.EventErr_T.InactiveEvent;
    event_info.listeners.push_in_list(&allocators.sba.allocator, listener)
        catch return types.EventErr_T.NoNListenerInstall;
    listener.flags.internal.listen = 1;
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
    if(!aux.check_path(bus, line)) return types.EventErr_T.NoNEvent;
    const event_info = aux.ret_event(bus, line);
    const iterator_param: struct { ite_event: *types.EventInfo_T, listener_to_found: *types.EventListener_T } = .{
        .ite_event = event_info,
        .listener_to_found = listener,
    };
    _ = event_info.listeners.iterator_handler(
        iterator_param,
        &opaque {
            pub fn handler(listener_iterator: *types.EventListener_T, param: @TypeOf(iterator_param)) anyerror!void {
                if(listener_iterator == param.listener_to_found) {
                    // o allocator passado libera o no da lista, nao o que tem nela
                    param.ite_event.listeners.drop_on_list(
                        (param.ite_event.listeners.iterator_index() catch unreachable) - 1,
                        &allocators.sba.allocator
                    ) catch {};
                    return;
                }
                return error.Continue;
            }
        }.handler,
    ) catch |err| return switch(err) {
        @TypeOf(event_info.listeners).ListErr_T.EndOfIterator => return types.EventErr_T.NoNListenerInstall,
        else => return types.EventErr_T.ListenerInteratorFailed,
    };
}
