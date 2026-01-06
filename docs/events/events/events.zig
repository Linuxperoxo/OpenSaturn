// os eventos sao o principal barramento de conversa
// que temos no opensaturn, temos essa comunicacao, temos
// varias partes do kernel escutando escutando uma interface
// de eventos, uma interface de eventos pode conter 1 ou mais
// eventos, um exemplo que events que usamos no kernel fica em
// kernel/interrupts/i386/csi.zig. Nesse arquivos temos a definicao
// do csi(cpu software interrupts), para cada interrupcao de software
// temos um evento, por exemplo, o evento 0 significa uma divisao por
// zero, cada excecao temos um evento do mesmo numero, voce pode ver isso
// no arquivo kernel/interrupts/i386/idt.zig.

const events: type = @import("root").interfaces.events;
const config: type = @import("root").config.kernel;

var my_events: events.Event_T = .{
    // caso voce esteja fazendo um evento
    // que tem um padrao usado pelo kernel,
    // voce pode dessa maneira para deixar
    // compativel com modulos que usam o
    // caminho padrao, voce pode especificar
    // um unico tambem
    .bus = config.options.keyboard_event.bus, // barramento onde o evento vai ficar
    .line = config.options.keyboard_event.line, // linha do barramento do evento
    // isso vai ser mais importante no futuro, ja que vamos pode ter mais de um
    // evento no mesmo bus-line, e aqui, vai fazer o listener saber exatamente quem
    // escutar
    .who = config.options.keyboard_event.who,
};
