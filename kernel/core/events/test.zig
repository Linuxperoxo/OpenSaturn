// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const std: type = @import("std");
const main: type = @import("main.zig");
const types: type = @import("types.zig");

// === Teste Info ===
//
// OpenSaturn: 0.3.0
// OS: Gentoo Linux x86_64
// Zig: 0.15.2
// Tester: Linuxperoxo
// Status: MAYBE - Failed With -ODebug

var listeners_hits = [_]u2 {
    0
} ** 2;

test "Event" {
    var test_event: types.Event_T = .{
        .bus = 0,
        .line = 0,
        .who = 10,
        .listener_out = null,
        .flags = .{
            .control = .{
                .active = 1,
                .block = 0,
            },
        },
    };
    var test_listener0: types.EventListener_T = .{
        .listening = 10,
        .event = 0,
        .handler = &opaque {
            pub fn handler(_: types.EventOut_T) ?types.EventInput_T {
                listeners_hits[0] += 1;
                return null;
            }
        }.handler,
        .flags = .{
            .control = .{
                .satisfied = 0,
                .all = 1,
            },
            .internal = .{
                 .listen = 0,
            },
        },
    };
    var test_listener1: types.EventListener_T = .{
        .listening = 10,
        .event = 0,
        .handler = &opaque {
            pub fn handler(_: types.EventOut_T) ?types.EventInput_T {
                listeners_hits[1] += 1;
                return null;
            }
        }.handler,
        .flags = .{
            .control = .{
                .satisfied = 0,
                .all = 1,
            },
            .internal = .{
                .listen = 0,
            },
        },
    };
    try main.install_event(
        &test_event,
        null
    );
    _ = main.install_event(
        &test_event,
        null
    ) catch |err| switch(err) {
        types.EventErr_T.EventCollision => {},
        else => return error.ExpectEventCollision,
    };
    try main.install_listener_event(&test_listener0, .{
        .explicit = .{
            .bus = 0,
            .line = 0,
        },
    });
    try main.install_listener_event(&test_listener1, .{
        .explicit = .{
            .bus = 0,
            .line = 0,
        },
    });
    try main.send_event(&test_event, .{
        .data = 1,
        .event = 0,
        .flags = .{
            .data = 1,
            .event = 0,
        }
    });
    for(&listeners_hits) |*hit| {
        if(hit.* != 1) return error.NonHit;
        hit.* = 0;
    }
    try main.remove_listener_event(&test_listener1, .{
        .explicit = .{
            .bus = 0,
            .line = 0,
        },
    });
    try main.send_event(&test_event, .{
        .data = 1,
        .event = 0,
        .flags = .{
            .data = 1,
            .event = 0,
        }
    });
    if(listeners_hits[1] != 0 and listeners_hits[0] != 1) return error.UndefinedHit;
    listeners_hits[0] = 0;
    test_listener0.flags.control.satisfied = 1;
    try main.send_event(&test_event, .{
        .data = 1,
        .event = 0,
        .flags = .{
            .data = 1,
            .event = 0,
        }
    });
    if(listeners_hits[0] != 0) return error.UndefinedHit;
    try main.remove_event(&test_event);
    if(test_listener0.flags.internal.listen != 0) return error.ListernerInternalFlagError;
    main.send_event(&test_event, .{
        .data = 1,
        .event = 0,
        .flags = .{
            .data = 1,
            .event = 0,
        }
    }) catch |err| switch(err) {
        types.EventErr_T.NoNEvent => return,
        else => {},
    };
    return error.TestUnreachableCode;
}
