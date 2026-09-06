// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// TODO: Substituir list por stack

const list: type = @import("root").lib.kernel.linked_list;

pub const ListKTask: type = list.buildList(*KTask);
pub const ListKTaskErr: type = ListKTask.ListErr;

pub const ListKTaskChildFailed: type = list.buildList(*KTaskChild);
pub const ListKTaskChildFailedErr: type = ListKTaskChildFailed.ListErr;

pub const KTaskPriority: type = enum(u2) {
    low = 3,
    normal = 2,
    high = 1,
    highly = 0,
};

pub const KTaskErr: type = error {
    SchedFailed,
    SchedPriorityInitError,
};

pub const KTask: type = struct {
    param: ?*anyopaque align(@sizeOf(usize)),
    result: ?*anyopaque = null,
    task: *const fn(?*anyopaque) anyerror!?*anyopaque, // propria task
    exit: ?*const fn() void,
    childs: ?[]KTaskChild,
    flags: packed struct {
        control: packed struct {
            single: u1, // executa task apenas uma vez e depois a dropa
            pendent: u1, // task pendente
            stop: u1, // caso a task retorne erro ignora todos os filhos
            drop: u1, // dropa a task assim que passar por ela
        },
        internal: packed struct {
            done: u1 = 0, // task resolvida
            err: u1 = 0, // task retornou erro
            childs: packed struct {
                done: u1 = 0, // task de todos os filhos foram chamados
                err: u1 = 0, // algum filho retornou erro
            } = .{},
        } = .{},
    },
};

pub const KTaskChild: type = struct {
    task: *const fn(?*anyopaque) anyerror!void align(@sizeOf(usize)),
    exit: ?*const fn() void,
    flags: packed struct {
        control: packed struct {
            pendent: u1, // ignora task
            depend: u1, // so executa se a task pai nao retornar erro
        },
        internal: packed struct {
            done: u1 = 0, // task resolvida
            err: u1 = 0, // task retornou erro
        } = .{},
    },
};
