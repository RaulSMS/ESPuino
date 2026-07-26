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
pio run                              # build all default_envs (esp32-s3-devkitc-1, lolin_d32_pro_sdmmc_pe)
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
