#!/usr/bin/env bash
# Verify BK7238-oriented firmware development toolchain on Linux.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT}/.cache/toolchain-test"
SRC="${BUILD_DIR}/main.c"
ELF="${BUILD_DIR}/bk7238-hello.elf"
BIN="${BUILD_DIR}/bk7238-hello.bin"

required_cmds=(arm-none-eabi-gcc arm-none-eabi-objcopy make git python3)
missing=()
for cmd in "${required_cmds[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("$cmd")
  fi
done

if ((${#missing[@]} > 0)); then
  echo "Missing required commands: ${missing[*]}"
  exit 1
fi

mkdir -p "${BUILD_DIR}"
cat >"${SRC}" <<'EOF'
/* Minimal Cortex-M33 image for toolchain smoke test (BK7238-class SoC). */
typedef unsigned int uint32_t;

void Reset_Handler(void) __attribute__((noreturn));
void Default_Handler(void) { for (;;) { } }

uint32_t vectors[] __attribute__((section(".isr_vector"))) = {
    0x20020000u,
    (uint32_t)Reset_Handler,
};

void Reset_Handler(void) {
    volatile uint32_t *gpio = (volatile uint32_t *)0x44000400u;
    *gpio = 0x2Du; /* BK7238-style GPIO write used by many Beken samples */
    for (;;) { }
}
EOF

CFLAGS=(
  -mcpu=cortex-m33
  -mthumb
  -mfloat-abi=soft
  -nostdlib
  -ffreestanding
  -Os
  -Wall
  -Wextra
)

arm-none-eabi-gcc "${CFLAGS[@]}" -T "${ROOT}/scripts/toolchain-test.ld" -o "${ELF}" "${SRC}"
arm-none-eabi-objcopy -O binary "${ELF}" "${BIN}"

echo "Toolchain: $(arm-none-eabi-gcc --version | head -n1)"
echo "Built ELF: ${ELF}"
echo "Built BIN: ${BIN} ($(wc -c <"${BIN}") bytes)"
arm-none-eabi-size "${ELF}"
echo "BK7238 toolchain verification passed."
