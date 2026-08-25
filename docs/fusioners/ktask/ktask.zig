// ktask é um fusioner default do opensaturn,
// sua principal tarefa é agendar tasks para serem
// executadas mais tarde. A ideia principal é criar
// uma task para tarefas que são pesadas, liberando
// assim a execução de tarefas que são mais importantes
// e possivelmente mais rápidas, para poder ser um
// ktask. Tenha em mente que o scheduler vai escolher
// quando executar as tarefas, então você não tem
// controle do tempo, mas você pode decidir a prioridade
// da task

// primeiramente, precisamos obter o fusioner ktask
const fusium: type = @import("root").interfaces.fusium;
const allocator: type = @import("allocator.zig");
const ktask: type = r: {
    const fusioner: type = fusium.fetchFusioner("ktask") orelse
        @compileError("need ktask");
    break :r fusioner.?;
};

var current_task: ?*ktask.KTask = null;

fn irqHandler() anyerror!void {
    // nao e muito correto irq chamar allocator, mas para exemplo
    // vai funcionar bem
    const new_task = &(try allocator.sba.allocator.alloc(ktask.KTask, 1))[0];
    errdefer allocator.sba.allocator.free(new_task) catch {};

    const childs: []ktask.KTaskChild = try allocator.sba.allocator.alloc(ktask.KTaskChild, 1);
    errdefer allocator.sba.allocator.free(childs) catch {};

    new_task.?.* = .{
        .param = null, // parâmetro repassado para taskFn()
        .result = null, // retorno de taskFn()
        .task = &taskFn, // task
        .exit = &taskExitFn, // chamado após task ser finalizada
        .childs = childs, // filhos da task, são chamados depois da task
        .flags = .{
            .control = .{
                // executa a task apenas uma vez, depois disso o sched
                // dropa ela, e você vai precisar agendar ela novamente
                .single = 1,
                // task pendente, sched só vai rodar caso seja 1, caso 0, nada da task vai rodar
                .pendent = 1,
                .stop = 0, // caso 1, se a task retornar erro, nem os childs nem o exit são chamados
                // maneira de tirar a task do sched, caso 1, assim que o sched chegar, ela vai ser dropada.
                // O sched não vai dar free na task, vai apenas remover sua referência internamente
                .drop = 0,
            },
            // essa struct não precisa ser inicializada, aqui
            // ficam os alertas do ktask sched
            .internal = .{
                .done = 0, // task resolvida, mesmo que tenha retornado erro
                .err = 0, // task retornou erro
                .childs = .{
                    .done = 0, // todos os filhos foram chamados
                    .err = 0, // algum filho retornou erro
                },
            },
        },
    };
    childs[0] = .{
        .task = &childTaskFn,
        .exit = null,
        .flags= .{
            .control = .{
                .pendent = 1,
                .depend = 1, // so executa se a task pai nao retornar erro
            },
            .internal = .{
                .done = 0,
                .err = 0,
            },
        },
    };
    try ktask.schedTask(
        new_task,
        ktask.KTaskPriority.highly // caso null, usa prioridade .normal
    );
    current_task = new_task;
}

fn taskFn(_: *anyopaque) anyerror!void {}

fn childTaskFn(_: ?*anyopaque) anyerror!void {}

fn taskExitFn() void {
    allocator.sba.allocator.free(
        current_task.?.childs.?
    ) catch {};
    allocator.sba.allocator.free(
        current_task.?
    ) catch {};
    current_task = null;
}
