# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ESPuino is an ESP32 firmware project (PlatformIO, Arduino + ESP-IDF frameworks, C++17) implementing an
RFID-controlled audio player (open-source Toniebox/Phoniebox alternative). It plays audio from a
MicroSD card, streams webradio, supports Bluetooth A2DP sink/source, MQTT, FTP, a REST API, and a
browser-based Web UI, driven by RFID tags, physical buttons, and a rotary encoder. There is no host-side
test suite — `test/` is PlatformIO's unit-test scaffold, unused. Validation is: build all HAL targets,
clang-format check, and manual on-device testing.

A `GEMINI.md` file in the repo root duplicates/overlaps parts of this file for another assistant;
keep the two in sync if you edit one and the other should still apply.

## Build / lint commands

This is a PlatformIO project — there is no plain `make`/`npm`. Common commands (run from repo root):

```sh
pio run -e esp32-s3-devkitc-1        # build one environment (see platformio.ini for the full list)
pio run                              # build whatever's listed in [platformio] default_envs
pio run -e <env> -t upload           # build + flash over USB
pio run -e <env> -t upload -t monitor
pio device monitor                   # serial monitor only (115200 baud, esp32_exception_decoder filter)
pio run -t clean
```

Environments defined in `platformio.ini`: `lolin_d32_pro`, `lolin_d32_pro_sdmmc_pe`, `ttgo_t8`,
`complete`, `esp32-wrover-devkitc-v4-8mb`, `esp32-s3-devkitc-1`. CI (`.github/workflows/firmware-builds.yml`)
builds `lolin_d32_pro`, `lolin_d32_pro_sdmmc_pe`, and `complete` for all three languages (DE/EN/FR) by
sed-patching `#define LANGUAGE` in `src/settings.h` before each build — a change must compile cleanly
under all three language configs.

Formatting is enforced by `.clang-format` (WebKit-based, tabs, 4-width) and checked in CI
(`clang-format-check.yml`) against everything under `src/`. Run clang-format on changed files before
committing; there's no separate lint step. `.git-blame-ignore-revs` hides historical mass-reformat
commits from blame — already wired up if you use the GitLens extension, otherwise run
`git config --local include.path ../.gitconfig` once.

`platformio-override.ini` (gitignored, copy from `platformio-override.ini.sample`) lets you override
build settings locally without touching `platformio.ini`.

Because envs use `framework = arduino, espidf`, source-file selection is delegated to
`src/CMakeLists.txt` (`FILE(GLOB_RECURSE app_sources ${CMAKE_SOURCE_DIR}/src/*.*)`), which globs
**every** file under `src/` into one component — PlatformIO's `build_src_filter`/`src_filter` has no
effect here (it warns `'src_filter' option cannot be used with ESP-IDF` and is silently ignored). This
means you can't isolate a single file/module in-tree for a minimal repro (e.g. to rule out a hardware
vs. software-interaction bug) by dropping an extra `.cpp` into `src/` with its own `setup()`/`loop()` —
it'll compile alongside `main.cpp` and fail with duplicate symbols in *every* environment. For that,
build a separate, standalone PlatformIO project elsewhere with plain `framework = arduino` (no
`espidf`) instead, copying over just the board/memory build flags you need from this file.

The `PLATFORM:` line `pio run` prints (e.g. `Espressif ESP32-S3-DevKitC-1-N8 (8 MB QD, No PSRAM)`) is a
static catalog label from the board's `name` field in `~/.platformio/platforms/.../boards/<board>.json`
— it does not reflect this project's `board_build.*`/`build_flags` overrides (16 MB flash, PSRAM, etc.
for `esp32-s3-devkitc-1`/N16R8). Trust the `HARDWARE:` line and later build output instead, and check
actual PSRAM presence at runtime via the serial monitor's `PSRAM: %u bytes` log line from `main.cpp`.

## Architecture

### Boot and main loop

`src/main.cpp` is the entry point. `setup()` initializes subsystems in a deliberate order driven by
hardware dependencies (documented inline) — e.g. buttons before RFID (wakeup sources must be armed
before anything can sleep), port-expander before power (power may be gated through it), audio init
before power-on (to avoid speaker pop), SD card only after power is stable. `loop()` is a large
cooperative round-robin calling each subsystem's `*_Cyclic()` function once per iteration, then
`vTaskDelay`s ~6 ticks. There is no RTOS scheduler abstraction beyond this — subsystems that need real
concurrency spin their own FreeRTOS task instead (see below).

### Module structure

Each subsystem is a flat pair of files at repo root `src/`: `Foo.h` / `Foo.cpp`, exposing
`Foo_Init()` / `Foo_Cyclic()` free functions (no classes/singletons for subsystems — global state
lives in file-scope statics, cross-module state in `extern` globals). Key subsystems: `AudioPlayer`,
`Rfid`/`RfidRuntime`/`RfidMfrc522`/`RfidPn5180`/`RfidConfig`/`RfidCommon` (reader abstraction — MFRC522
SPI/I2C and PN5180 are autodetected at boot), `Led` (Neopixel/FastLED status feedback), `Button`,
`RotaryEncoder`, `Bluetooth` (A2DP sink/source), `Mqtt`, `Ftp`, `Web` (async webserver + REST API +
web UI serving), `Wlan`, `SdCard`, `Battery`/`BatteryMeasureVoltage`, `Port` (I2C PCA9555 port
expander), `Power`, `System` (operation-mode state machine: normal / BT-sink / BT-source), `Cmd`
(dispatches the numeric command codes from `values.h`), `Log`/`logmessages.h`/`LogMessages_{DE,EN,FR}.cpp`
(compile-time-selected localized log strings).

Some subsystems that need true concurrency run a dedicated FreeRTOS task via
`xTaskCreatePinnedToCore` (grep for it in `RfidPn5180.cpp`, `RfidMfrc522.cpp`, `Led.cpp`, `Web.cpp`)
rather than being driven from the main loop. Cross-task handoff uses the two global queues in
`Queues.h`/`Queues.cpp`: `gRfidCardQueue` (RFID tag IDs, size 1) and `gLedQueue` (LED command bytes,
size 1) — both single-slot, i.e. "latest wins," not a buffered pipeline.

### Configuration / HAL layering

Configuration is a layered `#include` chain rooted at `src/settings.h`:
1. `settings.h` — feature toggles (`NEOPIXEL_ENABLE`, `MQTT_ENABLE`, `FTP_ENABLE`, `BLUETOOTH_ENABLE`,
   `PORT_EXPANDER_ENABLE`, ...), button-to-command mapping, `LANGUAGE` define, and (near the bottom) an
   `#if (HAL == N)` chain that pulls in the matching board file.
2. If `settings-override.h` exists (gitignored, copy from `settings-override.h.sample`), it's included
   *instead of* the rest of `settings.h`'s defaults — this is the supported way to fully customize
   without touching tracked files.
3. Board/HAL files (selected by `-DHAL=N` build flag per PlatformIO environment): `settings-lolin_d32_pro.h`
   (HAL 4), `settings-ttgo_t8.h` (HAL 5), `settings-complete.h` (HAL 6),
   `settings-lolin_d32_pro_sdmmc_pe.h` (HAL 7), `settings-custom.h` (HAL 99, for boards not in the list —
   this repo's active environments, `esp32-s3-devkitc-1` and `esp32-wrover-devkitc-v4-8mb`, both use
   HAL 99). These files define pinouts: I2S DAC pins, SPI/SDMMC SD pins, RFID reader pins, Neopixel pin
   + count, rotary encoder pins, button GPIOs, power control pins.

Numeric command codes (button actions, modification-card actions, playlist/playback modes, operation
modes) are all centralized in `src/values.h` and dispatched through `Cmd.cpp`.

### ESP-IDF config: `sdkconfig.defaults`

`sdkconfig.defaults` is the one ESP-IDF config baseline shared by every PlatformIO environment (it
sits alongside, not per-env). On first build, PlatformIO expands it into a per-env `sdkconfig.<env>`
file (e.g. `sdkconfig.esp32-s3-devkitc-1`), which is what's actually used afterwards. The
`pre:updateSdkConfig.py` extra_script compares `sdkconfig.defaults`' mtime against the last build and,
if it's newer, deletes all generated `sdkconfig.*` files so they regenerate from the edited defaults —
so editing `sdkconfig.defaults` and rebuilding is safe, but if a stale `sdkconfig.<env>` ever survives
a change unexpectedly, that script/timestamp logic is where to look.

Per-board hardware differences that aren't expressible as a simple `-D` build flag go here instead —
e.g. Octal- vs Quad-SPI PSRAM mode (`CONFIG_SPIRAM_MODE_OCT`) or disabling Classic Bluetooth
(`CONFIG_BT_CLASSIC_ENABLED`) on chips that lack that radio (ESP32-S3 is BLE-only). These settings and
the corresponding `platformio.ini` per-env settings are a matched pair, not independent knobs — e.g.
for `esp32-s3-devkitc-1` (an N16R8 module: 16 MB quad flash + 8 MB **octal** PSRAM),
`board_build.memory_type = qio_opi` in `platformio.ini` must agree with `CONFIG_SPIRAM_MODE_OCT=y` in
`sdkconfig.defaults`, and `lib_ignore = ESP32-A2DP` in that env must agree with
`CONFIG_BT_CLASSIC_ENABLED` being unset — changing one side without the other breaks PSRAM init or
leaves a library configured for a radio the chip doesn't have. When adding/reviewing a board env,
check both files together rather than assuming a flag added to one is redundant with something already
implied by the other; conversely, don't assume every flag in a board env is necessary — some
(`board_build.flash_mode` when it matches `[env]`'s default, or forcing a `-D` that a library/board
JSON already auto-detects for that chip, e.g. FastLED's `FASTLED_ESP32_HAS_RMT`) are copy-paste
leftovers worth dropping.

### LED driver: FastLED clockless backend (SPI vs. RMT)

`src/Led.h` includes `<FastLED.h>` after defining board-specific macros; on ESP32, FastLED picks one
clockless WS2812 backend at compile time (RMT by default, or a DMA/SPI-based one if
`FASTLED_ESP32_USE_CLOCKLESS_SPI` is defined — see `.pio/libdeps/*/FastLED/src/platforms/esp/32/README.md`).
This repo used to force the SPI backend unconditionally for every board (`FASTLED_ESP32_USE_CLOCKLESS_SPI`
defined with no chip guard). On `esp32-s3-devkitc-1` that caused a hard-to-reproduce abort during normal
operation — `ESP_ERROR_CHECK failed: ESP_ERR_TIMEOUT` in `SpiStripWs2812::waitDone()`
(`led_strip_refresh_wait_done`), always once WiFi + the web server were up, never in an isolated
LED-only sketch with no WiFi running. Root cause: that SPI/DMA path blocks on a single
completion-wait per `FastLED.show()`, which is much less tolerant of brief WiFi-driven interrupt
latency than RMT (RMT streams from a hardware ring buffer and only needs periodic refills). Fix:
`Led.h` now only forces the SPI backend when *not* building for `CONFIG_IDF_TARGET_ESP32S3` (checked
via `#include "sdkconfig.h"`), so `esp32-s3-devkitc-1` falls back to FastLED's default/recommended RMT
driver, which has 4 TX-capable RMT channels to spare on that chip. If a similar "works standalone,
aborts under load" LED symptom shows up on another board/HAL, this backend choice is the first place
to check — and remember the CMake src-globbing note above means an isolated repro sketch has to live
outside this repo, not in `src/`.

### Web UI

`html/` holds the static web UI (`management.html`, `accesspoint.html` + JS/CSS) served by `Web.cpp`'s
async webserver; `processHtml.py` (a `pre:` extra_script in `platformio.ini`) processes/embeds these at
build time. Localization is client-side `i18next` with per-locale JSON in `html/locales/`
(`de.json`, `en.json`, `fr.json`); language is auto-detected from `navigator.language`, user override
persisted in `localStorage`. The REST API surface is specified in `REST-API.yaml`.

### Filesystem access

`SanitizedFS` (`src/FileSystem.h`) wraps `fs::FS` to sanitize/reparse paths — SD card file access
should generally go through this wrapper rather than calling the underlying FS APIs directly, since
path sanitization matters for both correctness (SD.begin quirks) and security (FTP/web upload paths).

### Memory constraints

Target hardware is memory-constrained (PSRAM strongly required — the firmware isn't considered safe
without it). `PSRAMAllocator` (`src/Playlist.h`) is a custom STL allocator that prefers `ps_malloc`
falling back to `malloc`; use it for larger heap containers (playlists) rather than default `new`/std
allocators. FTP is disabled by default after each boot specifically to keep heap free for webstream
buffering — see the `ENABLE_FTP_SERVER` command / FTP section in `README.md` before changing that
behavior.
