// ┌──────────────────────────────────────────────┐
// │  (c) 2025 Linuxperoxo  •  FILE: SOA.zig      │
// │            Author: Linuxperoxo               │
// └──────────────────────────────────────────────┘

// === Saturn Object Allocator ===
//      A SLUB-like allocator
// === === === === === === === ===

// TODO: Usar memoria dos objetos nao alocados para armazenar informacoes

pub const Align_T: type = enum(u5) {
    in2 = 2,
    in4 = 4,
    in8 = 8,
    in16 = 16,
};

pub const Hits_T: type = enum(u2) {
    frozen,
    chilled,
    heated,
    burning,
};

pub const Optimize_T: type = enum {
    dinamic, // Escolhe de forma dinamica qual otimizacao usar para um alloc
    linear, // Sempre mantem os alloc de forma linear, pensados para muitos alloc em sequencia
    optimized, // Priorizar otimizacao
};

pub const Cache_T: type = enum {
    PrioritizeHits,
    PrioritizeSpeed,
};

pub const CacheTry_T: type = enum {
    Insistent,
    Lazy,
};

pub const CacheSize_T: type = enum(u2) {
    auto,
    small, // 1 / 4 do tamanho
    large, // 2 / 4 do tamanho
    huge, // 4 / 4 do tamanho
};

pub fn buildObjAllocator(
    comptime T: type, // Tipo para os objetos
    comptime O: usize, // Quantidade de objetos
    comptime flood: ?CacheSize_T, // Maximo de andares para cache, usado pelo fast
    comptime max: ?usize, // Maximo de miss, quanto menor menos penalidade caso todas tentativas forem miss
    comptime range: ?usize, // Quantidade de busca para continuos em auto. Valores grander podem causar uma penalidade maior em caso de miss
    comptime _: ?Hits_T, // Frequencia de sync para o fast
    comptime alignment: ?Align_T, // Alinhamento de memoria para os objetos
    comptime optimize: ?Optimize_T, // Tipo de otimizacao para o alocador
    comptime cache: Cache_T,
    comptime action: CacheTry_T
) type {
    return if(O == 0) void else struct {
        // Por enquanto o allocador so vai trabalhar com numeros
        // pares para facilitar
        comptime {
            if((O % 2) != 0) {
                @compileError(
                    \\
                );
            }
        }
        pub const err_T: type = error {
            OutOfMemory,
            DoubleFree,
            IndexOutBounds,
            UndefinedAction,
            NonOptimize,
            Rangeless,
        };

        pub const State_T: type = enum(u1) {
            free,
            busy,
        };

        // * continuos: vai tentar alocar a memoria de forma continua, embora seja
        //              mais lenta, para casos em que temos muitos alloc e free, mas
        //              em caso de varios alloc em sequencia se torna extremamente
        //              eficiente
        //
        // * fast: quando possivel sempre vai tentar otimizar, recomendado para quando
        //         temos muitos alloc e free de forma continua, usar muitos alloc e depois
        //         apenas 1 free depois de muitos alloc pode causar uma penalidade muito grande
        //
        // * auto: aplica a otimizacao dependendo do estado atual, recomendado para a maioria
        //         dos casos
        pub const Alloc_T: type = enum(u2) {
            continuos,
            fast,
            auto,
        };

        const Ret_T: type = enum(u1) {
            force,
            optimize,
        };

        const self_T: type = @This();

        pub const BitMap: type = packed struct {
            b0: State_T,
            b1: State_T,
            b2: State_T,
            b3: State_T,
            b4: State_T,
            b5: State_T,
            b6: State_T,
            b7: State_T,
        };

        const Bit_T= switch(O) {
            0...255 => u8,
            256...65535 => u16,
            else => u32,
        };

        objs: [O]T align(@intFromEnum(alignment orelse Align_T.in16)), // Object Pool
        obja: Bit_T, // Quantidade de objetos alocados
        objf: if(optimize == .linear) void else [sw: switch(flood orelse CacheSize_T.auto) {
            .small => if(O <= 2) O else O / 4,
            .large => O / 2,
            .huge => O,
            .auto => {
                switch(@sizeOf(T)) {
                    1...2 => continue :sw if(O <= 64) .huge else .large,
                    4...32 => continue :sw if(O <= 32) .large else .small,
                    else => continue :sw .small,
                }
            },
        }]?Bit_T, // Cache para fast
        objo: if(optimize == .linear) void else ?Bit_T, // Index para fast
        objc: ?Bit_T, // Index para continuos
        objm: [r: { // Bitmap dos objetos
            const objPerBitMap: usize = @sizeOf(BitMap) * 8;
            // essa calculo garante que tenha a quantidade certa
            // de bitmap para objetos caso seja um numero impar
            // de objetos
            //
            // exemplo:
            //  caso tivessemos 17 objetos:
            //      17 / 8 = 2
            //  observe que ficou 1 elemento de fora, ou seja
            //  precisariamos de mais um bitmap para ele, entao
            //  esse calculo faz o seguinte
            //      ((17 % 8) + 17) / 8 = 3
            //  poderiamos por um if para ver se sobrou resto
            //  e caso tenha sobrado, voltariamos a divicao
            //  (17 / 8) + 1, mas com esse calculo tiramos essa
            //  necessidade de um if
            break :r ((O % objPerBitMap) + O) / objPerBitMap;
        }]BitMap,

        pub fn bit(self: *self_T, index: usize) err_T!State_T {
            return if(index >= O) return err_T.IndexOutBounds else r: {
                const bitmapIndex: usize = index / (@sizeOf(BitMap) * 8);
                const offset: usize = index - ((@sizeOf(BitMap) * 8) * bitmapIndex);
                break :r @enumFromInt((@as(u8, @bitCast(self.objm[bitmapIndex])) >> @intCast(offset)) & 0x01);
            };
        }

        pub fn set(self: *self_T, index: usize, state: State_T) err_T!void {
            return if(index >= O) err_T.IndexOutBounds else r: {
                const bitmapIndex: usize = index / (@sizeOf(BitMap) * 8);
                const offset: usize = index - ((@sizeOf(BitMap) * 8) * bitmapIndex);
                @as(*u8, @ptrCast(&self.objm[bitmapIndex])).* = if(state == .free)
                    @as(u8, @bitCast(self.objm[bitmapIndex])) & (~(@as(u8, 0x01) << @intCast(offset)))
                else
                    @as(u8, @bitCast(self.objm[bitmapIndex])) | (@as(u8, 0x01) << @intCast(offset));
                break :r {};
            };
        }

        pub const Cache: type = struct {
            pub fn sync(self: *self_T) void {
                // TODO: Deve fazer uma sincronizacao, para o fast, a ideia e que
                //       ja que acertamos o fast varias vezes em sequencias, podemos
                //       atualizar a tabela de cache para evitar possiveis miss para o
                //       fast futuramente
                _ = self;
            }

            var last: Bit_T = 0;
            pub fn add(self: *self_T, index: usize, block: ?usize) void {
                switch(comptime cache) {
                    .PrioritizeHits => {
                        if((@call(.never_inline, &self_T.bit, .{
                            self,
                            index
                        }) catch unreachable) == .busy) {
                            return {};
                        }
                        self.objf[r: {
                            if(block == null or block.? >= self.objf.len) {
                                const start: Bit_T, const end: Bit_T = se: {
                                    switch(comptime action) {
                                        .Insistent => break :se .{
                                            0,
                                            self.objf.len
                                        },

                                        .Lazy => break :se .{
                                            if(last + 1 < self.objf.len / 2) last + 1 else u: {
                                                last = if(last >= self.objf.len) 0 else self.objf.len / 2; break :u last;
                                            }, // EO U
                                            self.objf.len / @intFromBool(last < self.objf.len) + 1,
                                        },
                                    }
                                };
                                for(start..end) |i| {
                                    if((@call(.always_inline, &self_T.bit, .{
                                        self,
                                        self.objf[i] orelse {
                                            self.objo = @intCast(i);
                                            break :r i;
                                        },
                                    }) catch unreachable) == .free) {
                                        self.objo = @intCast(i);
                                        break :r i;
                                    }
                                }
                            }
                            return {};
                        }] = @intCast(index);
                    },

                    .PrioritizeSpeed => {
                        if(block == null or block.? >= self.objf.len) return {};
                        self.objf[block.?] = @intCast(index);
                    },
                }
                last = @intCast(index);
            }
        };

        fn auto(self: *self_T) err_T!*T {
            for(0..max orelse 2) |_| {
                return @call(.always_inline, &self_T.fast, .{
                    self, Ret_T.optimize
                }) catch |err| if(err == err_T.IndexOutBounds) return err else {
                    continue;
                };
            }
            r: {
                return @call(.never_inline, &self_T.continuos, .{
                    self,
                    self.objc orelse break :r {},
                    if(self.objs.len >= (range orelse 2) + self.objc.?) (range orelse 2) + self.objc.? else break :r {}
                }) catch break :r {};
            }
            return @call(.always_inline, &self_T.continuos, .{
                self, null, null
            }) catch unreachable;
        }

        fn fast(self: *self_T, ret: Ret_T) err_T!*T {
            r: {
                if(self.objo) |objo| {
                    const statePtr: State_T = @call(.always_inline, &self_T.bit, .{
                        self,
                        self.objf[self.objo.?] orelse break :r {}
                    }) catch unreachable;
                    if(statePtr == .free) {
                        self.objf[self.objo.?] = null;
                        self.objo = if(self.objo.? + 1 < self.objf.len) self.objo.? + 1 else null;
                        self.objc = self.objo;
                        self.obja += 1;
                        @call(.always_inline, &self_T.set, .{ self, objo, .busy }) catch unreachable;
                        return &self.objs[objo];
                    }
                }
            }
            return if(ret == .force) @call(.never_inline, &self_T.continuos, .{
                self, null, null
            }) else err_T.NonOptimize;
        }

        pub fn continuos(self: *self_T, start: ?usize, end: ?usize) err_T!*T {
            // OPTIMIZE: continuos deve atualizar o objf para maximizar acertos para o fast
            for(start orelse 0..end orelse O) |i| {
                const bitMap: State_T = @call(.always_inline, &self_T.bit, .{ self, i }) catch |err| return err;
                if(bitMap == .free) {
                    self.obja += 1;
                    self.objc = if(i < self.objs.len - 1) @intCast(i + 1) else null;
                    @call(.always_inline, &self_T.set, .{ self, i, .busy }) catch unreachable;
                    r: {
                        @call(.never_inline, &self_T.Cache.add, .{
                            self, self.objc orelse break :r {}, null
                        });
                    }
                    return &self.objs[i];
                }
            }
            return err_T.Rangeless;
        }

        pub fn init(comptime self: *self_T) void {
            comptime {
                self.obja = 0;
                self.objc = 0;
                if(optimize != .linear) {
                    const objfLen = self.objf.len;
                    const objsLen = self.objs.len;
                    for(0..objfLen / 2) |i| {
                        self.objf[i] = i;
                        self.objf[objfLen - i - 1] = objsLen - i - 1;
                    }
                    self.objo = 0;
                }
                for(&self.objm) |*objm| {
                    @as(*u8, @ptrCast(objm)).* = @intFromEnum(State_T.free);
                }
            }
        }

        pub const alloc = switch(optimize orelse .optimized) {
            .dinamic => struct {
                pub fn alloc(self: *self_T, comptime how: Alloc_T) err_T!*T {
                    return if(self.obja >= O) return err_T.OutOfMemory else r: {
                        switch(comptime how) {
                            .auto => break :r @call(.never_inline, &self_T.auto, .{
                                self
                            }),
                            .fast => break :r @call(.never_inline, &self_T.fast, .{
                                self, Ret_T.force
                            }),
                            .continuos => break :r @call(.never_inline, &self_T.continuos, .{
                                self, self.objc, null
                            }),
                        }
                    };
                }
            }.alloc,

            .linear, .optimized => |t| struct {
                pub fn alloc(self: *self_T) err_T!*T {
                    return if(self.obja >= O) return err_T.OutOfMemory else r: {
                        break :r if(t == .linear) @call(.always_inline, &self_T.continuos, .{
                            self, self.objc, null
                        }) else @call(.always_inline, &self_T.auto, .{
                            self
                        });
                    };
                }
            }.alloc,
        };

        pub fn free(self: *self_T, I: usize) err_T!void {
            return if((@call(.never_inline, &self_T.bit, .{ self, I }) catch |err| return err) == .free) return err_T.DoubleFree else r: {
                @call(.always_inline, &self_T.set, .{ self, I, .free }) catch unreachable;
                @call(.always_inline, &Cache.add, .{
                    self, I, null
                });
                self.obja -= 1; break :r {};
            };
        }
    };
}
