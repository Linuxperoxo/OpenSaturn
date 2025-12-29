// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: types.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// TODO: Substituir list por stack

const list: type = @import("root").kernel.utils.list;

pub const ListKTask_T: type = list.BuildList(*KTask_T);
pub const ListKTaskErr_T: type = ListKTask_T.ListErr_T;

pub const ListKTaskChildFailed_T: type = list.BuildList(*KTaskChild_T);
pub const ListKTaskChildFailedErr_T: type = ListKTaskChildFailed_T.ListErr_T;

pub const KTaskPriority_T: type = enum(u2) {
    low = 3,
    normal = 2,
    high = 1,
    highly = 0,
};

pub const KTaskErr_T: type = error {
    SchedFailed,
};

pub const KTask_T: type align(@sizeOf(usize)) = struct {
    hooks: packed struct {
        // alerta que a task vai rodar, em caso de erro
        // task e abortada
        start: ?*const fn() anyerror!void,
        // alerta finalizacao da task
        exit: ?*const fn() void,
        childs: packed struct {
            // alerta que os childs vao comecar a rodar
            // em caso de erro aqui, a chamada e abortada
            start: ?*const fn() anyerror!void,
            // alerta de finalizacao dos filhos
            exit: ?*const fn() void,
        },
    },
    param: ?*anyopaque,
    task: *const fn(?*anyopaque) anyerror!?*anyopaque, // propria task
    childs: ?[]KTaskChild_T,
    failed: ?*ListKTaskChildFailed_T, // filhos com erro
    flags: packed struct {
        control: packed struct {
            block: u1, // ignora task
            overflow: u1, // retorna algo que pode ir para os filhos
            single: u1, // executa task apenas uma vez e depois a dropa
        },
        internal: packed struct {
            done: u1, // task resolvida
            err: u1, // task retornou erro
            abort: u1, // init da task retornou erro
            childs: packed struct {
                done: u1, // task de todos os filhos foram chamados
                err: u1, // algum filho retornou erro
            },
        },
    },
};

pub const KTaskChild_T: type align(@sizeOf(usize)) = struct {
    start: ?*const fn() anyerror!void,
    task: *const fn(anytype) anyerror!void,
    exit: ?*const fn() void,
    flags: packed struct {
        control: packed struct {
            block: u1, // ignora task
            allow: u1, // aceita parametro do parent
        },
        internal: packed struct {
            done: u1, // task resolvida
            err: u1, // task retornou erro
        },
    },
};
