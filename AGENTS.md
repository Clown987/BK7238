# AGENTS.md

## Repository status

This repository currently contains only a `README.md` stub (`# BK7238`). There is no firmware source, SDK, build system, or automated tests checked in yet. Cloud agents should treat BK7238 firmware work as **greenfield** until application code is added.

## Cursor Cloud specific instructions

### Product context

BK7238 is a Beken Wi-Fi + Bluetooth LE combo SoC. Typical firmware development uses:

- An ARM GCC cross-toolchain (`arm-none-eabi-gcc`)
- A Beken SDK (for example `beken_freertos_sdk` via [OpenBK7231T_App](https://github.com/openshwprojects/OpenBK7231T_App))
- UART flashing tools and a serial console for bring-up

### Installed system dependencies

The VM update script installs:

- `gcc-arm-none-eabi`, `binutils-arm-none-eabi`
- `build-essential`, `git`, `cmake`, `xz-utils`
- `python3`, `python-is-python3`, `python3-venv`, `python3-pip`
- `minicom` (serial console)

The cross-compiler binary is `arm-none-eabi-gcc` (not `gcc-arm-none-eabi-gcc`).

### Verify the environment

Run the local smoke test from the repo root:

```bash
bash scripts/verify-toolchain.sh
```

This cross-compiles a tiny Cortex-M33 image and writes artifacts to `.cache/toolchain-test/`.

### Building real BK7238 firmware (external reference project)

Because this repo has no SDK yet, use OpenBeken as a reference build to validate the full BK7238 pipeline:

```bash
git clone --depth 1 https://github.com/openshwprojects/OpenBK7231T_App.git /tmp/OpenBK7231T_App
cd /tmp/OpenBK7231T_App
git submodule update --init --recursive --depth=1 sdk/beken_freertos_sdk libraries/berry
cd sdk/beken_freertos_sdk/toolchain && XZ_OPT="-T0" tar -xf *.tar.xz
cd /tmp/OpenBK7231T_App
make APP_VERSION=dev_demo APP_NAME=OpenBK7238 OpenBK7238 -j4
```

Expected outputs include `sdk/beken_freertos_sdk/out/bk7238.bin` and `bk7238_UA.bin`.

`python-is-python3` is required: the Beken packager step invokes `python`.

### Lint / test / run

| Task | Command | Notes |
|------|---------|-------|
| Toolchain smoke test | `bash scripts/verify-toolchain.sh` | Only in-repo automated check today |
| Lint | N/A | No source files or linters configured |
| Unit tests | N/A | No test suite in repository |
| Run firmware | N/A | Requires BK7238 hardware + UART flash tool |

### Gotchas

- The empty repo cannot produce firmware images by itself until an SDK and application tree are added.
- Full OpenBK7238 builds download large SDK submodules and a vendored GCC toolchain tarball on first run.
- Beken's official Armino SDK may require separate Beken account access; OpenBeken's `beken_freertos_sdk` fork is the practical community path for BK7238 today.
