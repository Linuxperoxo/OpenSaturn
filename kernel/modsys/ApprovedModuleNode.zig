// ┌─────────────────────────────────────────────────────────┐
// │  (c) 2026 Linuxperoxo  •  FILE: ApprovedModuleNode.zig  │
// │                  Author: Linuxperoxo                    │
// └─────────────────────────────────────────────────────────┘

const lib: type = @import("root").lib;
const interfaces: type = @import("root").interfaces;

const Module: type = interfaces.module.Module;
const SinglyLinkedList: type = lib.kernel.SinglyLinkedList;

module: *const Module,
node: SinglyLinkedList.Node,
