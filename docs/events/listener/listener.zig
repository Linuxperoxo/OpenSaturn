// o listener no opensaturn consiste em voce escutar
// algum evento especifico quem algum modulo, fusioner ou
// ate mesmo alguma parte do core como a arquitetura x86 faz.
// voce como listener tem que ter em mente que voce pode nao
// ser o unico que quer escutar aquele evento, entao, voce como
// listener tem 2 opcoes, ser rapido para diminuir a espera de outros
// listener, ou, caso suportado e possivel, usar o fusioner ktask para
// agentar uma task no scheduler e deixar ela ser executada depois, voce
// pode dar uma olhada de como funciona as task no docs/fusioners/ktask

const events: type = @import("root").interfaces.events;

// aqui devemos deixar como var, ja que que ele e modificado
// pelo gerenciador de eventos
var my_listener: events.EventListener_T = .{
    // funcao chamada cada vez que o evento acontecer
    .handler = &handler,
    // como no futuro vamos poder ter mais de uma interface de
    // evento por bus-line, aqui especificamos quem queremos escutar,
    // atualmente nao tem impacto nenhum
    .listening = 0,
    .event = 0, // evento especifico para escutar
    .flags = .{
        .control = .{
            // listener esta satisfeito, ou seja, qualquer evento
            // sera ignorado caso .satisfied = 1
            .satisfied = 0,
            // escuta todos os eventos
            .all = 0,
        },
    },
};

fn handler(out: events.EventOut_T) ?events.EventInput_T {
    // caso o evento aceite return vindo do listener,
    // voce pode retornar algo assim
    return events.EventInput_T {
        .data = 10,
        .flags = 0b0001,
        .sender = 0, // quem esta mandando
    };
}
