// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: utils.zig    │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

const aux: type = @import("aux.zig");

/// converts a slice comptime known into an array
pub fn array_from_slice(comptime slice: anytype) [r: {
    // so precisamos verificar se e um slice aqui, ja que esse
    // bloco comptime e resolvido primeiro que o aux.slice_child_type.
    // Em funcoes a ordem e tipos dos parametros(executado na ordem dos parametros),
    // e o segundo e o tipo de retorno, para arrays primeiro tamanho e depois child type
    // do array
    if(!aux.is_slice(@TypeOf(slice))) @compileError(
        "expect a slice!"
    );
    break :r slice.len;
}]aux.slice_child_type(@TypeOf(slice)) {
    var array: [slice.len]aux.slice_child_type(@TypeOf(slice)) = undefined;
    for(slice, 0..) |value, i| {
        array[i] = value;
    }
    return array;
}
