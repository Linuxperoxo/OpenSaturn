// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: test.zig     │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const main: type = @import("main.zig");
const types: type = @import("types.zig");

test "Event" {
    var test_event: types.Event_T = .{
        .bus = 0,
        .line = 0,
        .listener_out = null,
        .flags = .{
            .control = .{
                .active = 1,
                .block = 0,
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
}

test "Event Listener" {

}
