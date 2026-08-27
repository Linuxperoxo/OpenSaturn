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

pub var event_buses = [_]types.EventBus {
    types.EventBus {
        .line = [_]?*types.EventInfo {
            null
        } ** 8,
    },
} ** 4;


pub fn installEvent(event: *types.Event, comptime default: ?types.EventDefault) types.EventErr!void {
    const bus, const line = if(default != null) aux.defaultBus(default.?) else .{
        event.bus,
        event.line
    };
    if(aux.checkPath(bus, line)) return types.EventErr.EventCollision;
    event_buses[bus].line[line] = &(allocators.sba.allocator.alloc(
        types.EventInfo, 1
    ) catch return types.EventErr.AllocFailed)[0];
    if(default != null) {
        event.bus = bus;
        event.line = line;
    }
    event_buses[bus].line[line].?.event = event;
    event_buses[bus].line[line].?.listeners.private = null; // garantindo uma lista vazia
    event_buses[bus].line[line].?.listeners.init(&allocators.sba.allocator) catch
        return types.EventErr.ListInitFailed;
}

// quando tiver ktask, vamos ter um novo parametro, que vai enviar para todos de uma vez
// de 1 em 1, ou de metade em metade, quem vai gerenciar isso vai ser i ktask
pub fn sendEvent(event: *types.Event, out: types.EventOut) types.EventErr!void {
    if(!aux.checkPath(event.bus, event.line)) return types.EventErr.NoNEvent;
    const event_info = aux.retEvent(event.bus, event.line);
    if(event_info.event.flags.control.active != 1) return types.EventErr.DisableEvent;
    const iterator_param: struct { ite_event: *types.EventInfo, event_out: types.EventOut } = .{
        .ite_event = event_info,
        .event_out = out,
    };
    _ = event_info.listeners.iteratorHandler(
        iterator_param,
        &opaque {
            pub fn handler(listener: *types.EventListener, param: @TypeOf(iterator_param)) anyerror!void {
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
        @TypeOf(event_info.listeners).ListErr.EndOfIterator => {},
        else => return types.EventErr.ListenerInteratorFailed,
    };
}

pub fn removeEvent(event: *types.Event) types.EventErr!void {
    if(!aux.checkPath(event.bus, event.line)) return types.EventErr.NoNEvent;
    const event_info = aux.retEvent(event.bus, event.line);
    const iterator_param: void = {};
    _ = event_info.listeners.iteratorHandler(
        iterator_param,
        &opaque {
            pub fn handler(listener: *types.EventListener, _: @TypeOf(iterator_param)) anyerror!void {
                listener.flags.internal.listen = 0;
                return error.Continue;
            }
        }.handler,
    ) catch |err| switch(err) {
        @TypeOf(event_info.listeners).ListErr.EndOfIterator => {},
        else => return types.EventErr.ListenerInteratorFailed,
    };
    const slice: []types.EventInfo = @as([*]types.EventInfo, @ptrCast(event_info))[0..1];
    allocators.sba.allocator.free(slice) catch return types.EventErr.FreeEventFailed;
    event_buses[event.bus].line[event.line] = null;
}

pub fn installListener(
    listener: *types.EventListener,
    comptime bus_line: union(enum(u1)) {
        default: types.EventDefault,
        explicit: struct {
            bus: u2,
            line: u3,
        },
    }
) types.EventErr!void {
    const bus, const line = switch(bus_line) {
        .default => aux.defaultBus(bus_line.default),
        .explicit => .{
            bus_line.explicit.bus,
            bus_line.explicit.line
        },
    };
    if(!aux.checkPath(bus, line)) return types.EventErr.NoNEvent;
    const event_info = aux.retEvent(bus, line);
    if((~event_info.event.flags.control.block & event_info.event.flags.control.active) != 1) return types.EventErr.InactiveEvent;
    event_info.listeners.pushInList(&allocators.sba.allocator, listener)
        catch return types.EventErr.NoNListenerInstall;
    listener.flags.internal.listen = 1;
}

pub fn removeListener(
    listener: *types.EventListener,
    comptime bus_line: union(enum(u1)) {
        default: types.EventDefault,
        explicit: struct {
            bus: u2,
            line: u3,
        },
    }
) types.EventErr!void {
    const bus, const line = switch(bus_line) {
        .default => aux.defaultBus(bus_line.default),
        .explicit => .{
            bus_line.explicit.bus,
            bus_line.explicit.line
        },
    };
    if(!aux.checkPath(bus, line)) return types.EventErr.NoNEvent;
    const event_info = aux.retEvent(bus, line);
    const iterator_param: struct { ite_event: *types.EventInfo, listener_to_found: *types.EventListener } = .{
        .ite_event = event_info,
        .listener_to_found = listener,
    };
    _ = event_info.listeners.iteratorHandler(
        iterator_param,
        &opaque {
            pub fn handler(listener_iterator: *types.EventListener, param: @TypeOf(iterator_param)) anyerror!void {
                if(listener_iterator == param.listener_to_found) {
                    // o allocator passado libera o no da lista, nao o que tem nela
                    param.ite_event.listeners.dropOnList(
                        (param.ite_event.listeners.iteratorIndex() catch unreachable) - 1,
                        &allocators.sba.allocator
                    ) catch {};
                    return;
                }
                return error.Continue;
            }
        }.handler,
    ) catch |err| return switch(err) {
        @TypeOf(event_info.listeners).ListErr.EndOfIterator => return types.EventErr.NoNListenerInstall,
        else => return types.EventErr.ListenerInteratorFailed,
    };
}
