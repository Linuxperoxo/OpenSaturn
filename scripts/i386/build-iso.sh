#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/zig-out"
ISO_ROOT="$BUILD_DIR/iso"
ISO_IMAGE="$BUILD_DIR/OpenSaturn.iso"
KERNEL="$BUILD_DIR/bin/sImage.elf"
GRUB_CONFIG="$ROOT_DIR/grub/grub.cfg"
GRUB_PC_DIR="${GRUB_PC_DIR:-/usr/lib/grub/i386-pc}"

usage() {
    printf 'Usage: %s [build|run|debug]\n' "$(basename "$0")"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing command: %s\n' "$1" >&2
        exit 1
    }
}

for command in zig grub-file grub-script-check grub-mkrescue xorriso mformat; do
    require_command "$command"
done

if [[ ! -d "$GRUB_PC_DIR" ]]; then
    printf 'Missing GRUB BIOS platform: %s\n' "$GRUB_PC_DIR" >&2
    printf 'Enable GRUB_PLATFORMS="pc" and rebuild sys-boot/grub.\n' >&2
    exit 1
fi

mode="${1:-build}"
if [[ "$mode" != "build" && "$mode" != "run" && "$mode" != "debug" ]]; then
    usage >&2
    exit 2
fi

cd "$ROOT_DIR"

build_args=(saturn)
if [[ "$mode" == "debug" ]]; then
    build_args+=("-Ddebug=true")
fi

zig build "${build_args[@]}"
grub-file --is-x86-multiboot "$KERNEL"
grub-script-check "$GRUB_CONFIG"

rm -rf "$ISO_ROOT"
mkdir -p "$ISO_ROOT/boot/grub" "$ISO_ROOT/zig-out/bin"

cp "$GRUB_CONFIG" "$ISO_ROOT/boot/grub/grub.cfg"
cp "$KERNEL" "$ISO_ROOT/zig-out/bin/sImage.elf"

grub-mkrescue -d "$GRUB_PC_DIR" -o "$ISO_IMAGE" "$ISO_ROOT"

printf 'ISO: %s\n' "$ISO_IMAGE"

case "$mode" in
    build)
        ;;
    run)
        require_command qemu-system-i386
        exec qemu-system-i386 -cdrom "$ISO_IMAGE" -boot d
        ;;
    debug)
        require_command qemu-system-i386
        exec qemu-system-i386 -cdrom "$ISO_IMAGE" -boot d -S -s
        ;;
esac
