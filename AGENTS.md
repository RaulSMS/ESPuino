# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, OpenAI Codex, Gemini CLI/Antigravity,
and others that support the [AGENTS.md](https://agents.md/) convention) when working with code in
this repository. Tool-specific files (`CLAUDE.md`, `GEMINI.md`) are slim pointers that import this
file — add tool-specific instructions there, and everything else here.

## What this is

ESPuino is an ESP32 firmware project (PlatformIO, Arduino + ESP-IDF frameworks, C++17) implementing an
RFID-controlled audio player (open-source Toniebox/Phoniebox alternative). It plays audio from a
MicroSD card, streams webradio, supports Bluetooth A2DP sink/source, MQTT, FTP, a REST API, and a
browser-based Web UI, driven by RFID tags, physical buttons, and a rotary encoder. There is no host-side
test suite — `test/` is PlatformIO's unit-test scaffold, unused. Validation is: build all HAL targets,
clang-format check, and manual on-device testing.

## Communication standard

All documentation (this file, `CLAUDE.md`, `GEMINI.md`, `FirstSteps.md`, implementation plans,
walkthroughs), code comments, commit messages, and assistant responses must be written in English,
unless the user explicitly asks for another language for a specific piece of output. This doesn't
apply to intentionally-localized content that's non-English by design — `LogMessages_{DE,EN,FR,ES}.cpp`
and `html/locales/*.json` are supposed to contain German/French/Spanish strings.

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
builds `lolin_d32_pro`, `lolin_d32_pro_sdmmc_pe`, and `complete` for all four languages (DE/EN/FR/ES) by
sed-patching `#define LANGUAGE` in `src/settings.h` before each build — a change must compile cleanly
under all four language configs.

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
(dispatches the numeric command codes from `values.h`), `Log`/`logmessages.h`/`LogMessages_{DE,EN,FR,ES}.cpp`
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
2. If `settings-override.h` exists, it's included *instead of* the rest of `settings.h`'s defaults —
   the supported way to fully customize without touching tracked files. Upstream ESPuino gitignores
   this file (copy from `settings-override.h.sample`); **this fork tracks it in git instead**
   (`.gitignore` only excludes `platformio-override.ini`, not this file) — `src/settings-override.h`
   is a complete customized copy of `settings.h` (feature toggles, `LANGUAGE`, battery thresholds,
   `HAL` hardcoded to `99`) and *is* the live config for every build here, not an optional layer. Edit
   it directly for toggles/thresholds; it still ends in the same `#if (HAL == N)` chain as `settings.h`
   and includes `settings-custom.h` for HAL 99, so pin assignments still live there (see step 3).
3. Board/HAL files (selected by `-DHAL=N` build flag per PlatformIO environment): `settings-lolin_d32_pro.h`
   (HAL 4), `settings-ttgo_t8.h` (HAL 5), `settings-complete.h` (HAL 6),
   `settings-lolin_d32_pro_sdmmc_pe.h` (HAL 7), `settings-custom.h` (HAL 99, for boards not in the list —
   this repo's active environments, `esp32-s3-devkitc-1` and `esp32-wrover-devkitc-v4-8mb`, both use
   HAL 99). These files define pinouts: I2S DAC pins, SPI/SDMMC SD pins, RFID reader pins, Neopixel pin
   + count, rotary encoder pins, button GPIOs, power control pins. `PORT_EXPANDER_ENABLE` is
   auto-forced on only for HAL 6/7 (`settings.h`, mandatory there since PCA9555 is part of those
   boards); leave it undefined for HAL 99 setups without a port expander.

Numeric command codes (button actions, modification-card actions, playlist/playback modes, operation
modes) are all centralized in `src/values.h` and dispatched through `Cmd.cpp`. Adding a new command
(e.g. a maintenance action triggerable from the web UI) touches four places: the `CMD_*` numeric
constant in `values.h` (there's a free 156-169 gap in the 100s "system/modification" block); a
`case CMD_*:` in `Cmd_Action()` in `Cmd.cpp` — this is the single dispatcher every input source
(buttons, IR remote, RFID modification tags, MQTT, the generic websocket `{"controls":{"action": N}}`
message) funnels through, so one case makes it reachable from all of them; and, to make it
*discoverable* in the web UI rather than only callable by number, add the id to the `cmds` array
(physical-button assignment dropdowns) and/or `mods` array (RFID-modification-tag assignment + the
Control tab's "run a command now" dropdown/button) in `html/management.html`'s
`replaceCommandSelect`/`addOption` setup — both arrays feed the same generic select-population code,
and each option's label comes from the locale key `files.rfid.mod.cmd.<id>` (add it to all four of
`html/locales/{de,en,fr,es}.json`, not just `en.json`, or the label falls back to the raw i18next key).

### RFID reader auto-detection and the RST-pin hazard

`RfidConfig.cpp`'s `RfidConfig_AutoDetectReader()` probes for a PN5180 *first*, before ever checking
for an MFRC522, by constructing a real `PN5180` object on `RFID_CS`/`RFID_BUSY`/`RFID_RST` and
running its actual `begin()`/`reset()` sequence — this happens on every boot as a "is the previously
detected reader still there" sanity check, not just on first-ever boot. On the stock HALs (`settings-
complete.h`, `settings-lolin_d32_pro*.h`, `settings-ttgo_t8.h`) this is harmless because those boards
set the MFRC522's own `RST_PIN` to a dummy `99` (MFRC522 there relies purely on SPI soft-reset, per
their own comments — `RST_PIN` is *not* the library's `UNUSED_PIN` sentinel, which is `UINT8_MAX`/255,
so `99` still runs through `pinMode`/`digitalRead` on an invalid-but-harmless GPIO number every time,
just not a real one). A custom HAL that wires a *real* reset line to its MFRC522 and reuses that same
GPIO number for `RFID_RST` (the PN5180 slot) recreates a genuine hardware hazard: the PN5180 probe's
reset pulse and garbage PN5180-protocol SPI bytes land directly on the real MFRC522 chip before it's
ever properly initialized, intermittently wedging its SPI interface for that boot cycle (only a
hardware reset pulse reliably recovers it; a soft-reset command sent over an already-wedged SPI link
often doesn't). Fixed by skipping the PN5180 probe in `RfidConfig_AutoDetectReader()` whenever
`RFID_BUSY == 99` (this codebase's established "not wired" sentinel, same convention as
`IRLED_PIN`/`ROTARYENCODER_BUTTON`) — check this pin-sharing pattern first for any "RFID reader is
flaky/dead until reboot, but SPI itself is fine" report on a custom HAL. `RfidMfrc522.cpp`'s task now
also self-heals from a wedged reader regardless of cause: every ~5s while idle it verifies `VersionReg`
still reads as a valid MFRC522 signature (`IsValidMfrc522Version()`, exposed via `RfidConfig.h`) and
re-runs `PCD_Init()` if not, so a bad boot recovers in seconds rather than requiring a power cycle. A
manual trigger for the same recovery path is exposed as `CMD_RESET_RFID_READER` — the request is
just a `volatile bool` flag set by `RfidMfrc522_RequestReset()` and picked up by the reader's own
FreeRTOS task on its next idle poll, not performed from the calling context directly, since MFRC522's
library isn't safe to call into from two tasks at once.

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
(`de.json`, `en.json`, `fr.json`, `es.json`); language is auto-detected from `navigator.language`, user override
persisted in `localStorage`. The REST API surface is specified in `REST-API.yaml`.

### Filesystem access

`SanitizedFS` (`src/FileSystem.h`) wraps `fs::FS` to sanitize/reparse paths — SD card file access
should generally go through this wrapper rather than calling the underlying FS APIs directly, since
path sanitization matters for both correctness (SD.begin quirks) and security (FTP/web upload paths).

### Battery monitoring & the ESP32-S3 ADC constraint

`MEASURE_BATTERY_VOLTAGE` (`src/BatteryMeasureVoltage.cpp`) reads `VOLTAGE_READ_PIN` through a
resistor voltage-divider (`rdiv1`/`rdiv2`, in kΩ) with `inputAttenuation` (typically `ADC_11db`,
~0-2.5V usable range at the pin). On ESP32-S3 only `GPIO1-10` are ADC1 pins; `GPIO11-20` are ADC2
(unusable together with WiFi, since the driver shares the radio), and no other GPIO has any ADC
channel at all. Picking a `VOLTAGE_READ_PIN` outside `GPIO1-10` doesn't just read garbage — the
Arduino core's `adc_oneshot_io_to_channel()` call isn't error-checked, so it indexes an internal
handle array with an uninitialized `adc_unit` and crashes with `Guru Meditation Error:
LoadProhibited`. Always verify a proposed analog-input pin against that range before wiring it on an
S3 board (this repo's HAL 99 config uses GPIO9/`ADC1_CH8`, which is safe).

Threshold constants (`s_warningLowVoltage`, `s_warningCriticalVoltage`, `s_voltageIndicatorLow`,
`s_voltageIndicatorHigh`) only **seed NVS on first boot** — `Battery_InitInner()` reads NVS first and
falls back to these only if nothing is stored yet. Editing them later does nothing on a device that's
already booted once; change the values via the Web UI's battery-settings tab instead, or erase NVS to
re-seed.

`CMD_MEASUREBATTERY` (178) does an on-demand measurement (log + MQTT + LED flash, no speech).
`CMD_TELL_BATTERY_LEVEL` (157) additionally speaks the level via TTS (see below). Both are already
wired into `management.html`'s `cmds`/`mods` arrays — a working reference for the general pattern in
"Adding a new command" above, if adding another battery-related action.

Low-battery speech (`Battery_Cyclic()` in `src/Battery.cpp`) is edge-triggered (announces once per
low-battery episode via a `static bool` latch), unlike the LED/log warning which repeats every check
interval — a short check interval (the Web UI allows down to 1 minute) would otherwise make
every-cycle speech extremely naggy.

### Text-to-speech (TTS) announcements

`gPlayProperties.tellMode` (a 3-bit field in `src/AudioPlayer.h` — so at most 8 `TTS_*` values from
`src/values.h` before it needs widening) drives one-shot spoken announcements, consumed once per
`AudioPlayer_Loop()` iteration via the audio library's `connecttospeech(text, langCode)` — an
**online** TTS engine, so every announcement needs an active WiFi connection and silently no-ops (with
an error log) otherwise. Existing uses: IP address, current time, on-demand battery level, and the
automatic low-battery warning. Setting `tellMode` plus `currentSpeechActive`/`lastSpeechActive = true`
from anywhere in the cooperative main loop (not just `Cmd_Action()` — `Battery_Cyclic()` does it for
the low-battery warning) queues the announcement; it interrupts current playback and resumes the
previous RFID tag afterwards automatically.

### Memory constraints

Target hardware is memory-constrained (PSRAM strongly required — the firmware isn't considered safe
without it). `PSRAMAllocator` (`src/Playlist.h`) is a custom STL allocator that prefers `ps_malloc`
falling back to `malloc`; use it for larger heap containers (playlists) rather than default `new`/std
allocators. FTP is disabled by default after each boot specifically to keep heap free for webstream
buffering — see the `ENABLE_FTP_SERVER` command / FTP section in `README.md` before changing that
behavior.

The PSRAM-first policy above is aspirational, not fully enforced: `src/Web.cpp`'s `SpiRamAllocator`
(the `ArduinoJson` allocator backing most REST endpoints) is applied inconsistently — e.g.
`tagIdToJsonStr()` and `handleBluetoothResultsRequest()` construct a bare `JsonDocument` with no
allocator at all, so those specific responses build on the small internal heap despite being sized by
NVS/scan content. Also, `Playlist.h`'s `allocatePlaylist()`/`freePlaylist()` pair mismatches allocator
and deallocator on the non-PSRAM fallback path (`new Playlist()` freed via `free()`, not `delete`) —
undefined behavior per the standard even though it currently works with this toolchain. See
[raulsms/espuino#6](https://github.com/RaulSMS/ESPuino/issues/6) before assuming every `JsonDocument`
or `Playlist` allocation in this codebase is already PSRAM-safe; check the specific call site.

## Known reliability / memory-safety gaps (from an architecture review, Aug 2026)

A full-codebase review turned up several concrete, unfixed issues worth knowing about before touching
the related code — filed as GitHub issues on this repo (`RaulSMS/ESPuino#3`–`#7`) rather than fixed
inline, since fixing them wasn't in scope for that pass. Highlights, in case an issue gets closed/stale
and this context needs to survive independently:

- **`RfidCommon.cpp`'s file/URL parsing can produce an unterminated stack buffer.** `char _file[255]`
  is filled via `strncpy(_file, token, sizeof(_file) / sizeof(_file[0]))` — using the *full* buffer
  size instead of `sizeof(_file) - 1`, so a 255+ character path/URL (valid input — the web UI's source
  buffer is 275 bytes, `Web.cpp:1046`) leaves `_file` unterminated before it's used as a C-string in
  `AudioPlayer_SetPlaylist()`. `Web.cpp:2500`'s `tagIdToJSON()` parses the identical data correctly
  (zero-initialized, `sizeof(_file) - 1`) — that's the pattern to copy. (#3)
- **MFRC522's "don't accept the same RFID tag twice" is silently broken**: `RfidMfrc522.cpp` declares
  `byte lastValidcardId[cardIdSize]` *inside* the reader task's `for (;;)` loop, so it never persists
  across polls and the duplicate-tag comparison is always against garbage. `RfidPn5180.cpp` declares
  the equivalent variable outside the loop correctly — that's the reference implementation. (#4)
- **`gPlayProperties` (the core playback-state struct) is mutated from the RFID reader tasks and read
  from `AudioPlayer_Cyclic()` in the main loop with no mutex/atomics** — a plausible source of
  intermittent, long-uptime-only crashes via torn reads (e.g. an index read against one playlist size,
  checked against an already-swapped playlist pointer). (#4)
- **Several hardware paths have no timeout/recovery and can hang the device forever**, requiring a
  physical power cycle: `SdCard_Init()`'s SD-mount loop retries unbounded unless
  `SHUTDOWN_IF_SD_BOOT_FAILS` is set; `Port.cpp`'s I2C transactions to the port expander have no
  timeout and no bus-recovery on failure, and since `Port_Cyclic()` runs every main-loop iteration a
  wedged I2C bus can stall RFID/LED/web-server handling simultaneously; `Bluetooth_Init()` has a bare
  `while (1);` spin on I2S init failure with no watchdog-safe fallback. (#5)
- **Concurrent unsynchronized SD-card filesystem access**: the web file-explorer's delete/create/rename
  handlers (`Web.cpp`) call `gFSystem.remove/rmdir/mkdir` directly from the AsyncWebServer task while
  `AudioPlayer_Cyclic()` concurrently reads the same card from the main loop task — only the raw-upload
  path is guarded via `System_PauseTasksDuringUpload()`; delete/create/rename aren't.

## Build performance & binary-size notes

`sdkconfig.defaults` already sets `CONFIG_COMPILER_OPTIMIZATION_SIZE=y` (`-Os`) and `platformio.ini`
sets `-DCORE_DEBUG_LEVEL=0` — don't casually change either without checking the size impact. Beyond
that baseline, a few things are worth knowing if asked to reduce compile time or flash usage:

- `CONFIG_ESP_WIFI_CSI_ENABLED=y` and `CONFIG_FREERTOS_GENERATE_RUN_TIME_STATS=y` in
  `sdkconfig.defaults` are enabled but nothing under `src/` references CSI or FreeRTOS runtime-stats
  APIs (grepped and confirmed) — they look like leftover debug config, not something the app depends
  on. Likely safe to disable for a size/CPU-overhead win, but verify no library pulls them in
  transitively before flipping them.
- `platformio.ini`'s `board_build.embed_txtfiles` embeds `esp_insights`/`esp_rainmaker` server certs,
  which implies those Espressif managed components get built in via the `arduino-esp32` 3.x IDF
  component manifest even though nothing in `src/` calls into either SDK. This is unconfirmed (would
  need a from-scratch build + map-file diff to quantify), but is the most promising binary-size lead
  turned up so far — check whether they can be dropped via the component manager's exclude mechanism.
- `CONFIG_BT_SPP_ENABLED=y` is set but `BluetoothSerial`/SPP isn't used anywhere in `src/`; worth
  checking whether `ESP32-A2DP` needs it transitively before dropping it.
- No `-flto` in `build_flags`. Untried here, but cross-TU dead-code elimination under `-Os` often buys
  a further few percent on ESP32 — costs link time, so weigh against the point below.
- CI (`.github/workflows/firmware-builds.yml`) builds 3 envs × 4 languages = 12 full cold builds with no
  `ccache`/`sccache` configured anywhere. Since the four language variants differ only in the
  `LogMessages_{DE,EN,FR,ES}.cpp` translation units selected by the `LANGUAGE` define, a shared ccache
  directory across those jobs (restored via `actions/cache`, keyed on toolchain+flags) would likely
  turn most repeated-language rebuilds into cache hits — probably the highest-leverage CI-time win
  available, and lower-risk than touching sdkconfig feature flags.
- The pinned git-fork dependencies in `lib_deps` (`ESP32-audioI2S`, `ESP-FTP-Server-Lib`,
  `PN5180-Library`, `rfid.git`, `natsort.git`, `LogRingBuffer`) each carry an inline comment explaining
  why they're forked (warning fixes, timeout tuning, etc.) rather than pointing at upstream — this
  isn't a compile-time problem, but periodically diffing against upstream and upstreaming the fixes
  (where upstream is still maintained) would reduce the long-term burden of tracking forked commits.
  `ArduinoJson` (v7.4.3) and `ESPAsyncWebServer` (the actively-maintained `ESP32Async` fork) are
  already reasonably current and don't need this treatment.
