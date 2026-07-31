# First Steps & Wiring Guide for Custom ESPuino (ESP32-S3)

This document describes how to configure and wire your specific hardware components for ESPuino without using the PCA9555 port expander.

---

## 1. Components Used

- **Microcontroller**: ESP32-S3-DevKitC-1-N16R8 (16MB Flash, 8MB PSRAM)
- **Audio DAC**: MAX98357A I2S 3W
- **LED Ring**: AZDelivery 3 x RGB LED Ring 5V compatible with WS2812B (12-Bit / 12 LEDs, 38mm)
- **Card Reader**: Micro SD Module 3.3V SPI
- **RFID Reader**: MFRC522 (SPI) or PN5180
- **Controls**: Direct GPIO Buttons only (no rotary encoder)
- **Battery Monitoring**: ADC + resistor voltage-divider (no fuel-gauge IC)

---

## 2. SPI Bus Architecture: MicroSD vs MFRC522 RFID

You will notice in the pinout section that the **MicroSD card** and **MFRC522 RFID reader** use separate SPI pins (`SPISD_...` vs `RFID_...`). 

> [!NOTE]
> **Why separate SPI buses/pins?**
> 1. **Dual Hardware SPI Controllers**: The ESP32 / ESP32-S3 features multiple hardware SPI peripherals. Assigning MicroSD and RFID to independent SPI buses isolates continuous high-speed audio streaming from periodic RFID tag polling.
> 2. **Audio Playback Stability**: Sharing an SPI bus between SD card reads and RFID scanning can cause latency spikes, bus contention, or audio stutter during playback.
> 3. **Hardware Compatibility**: Some cheap SD card modules or RFID boards fail to release (tri-state) the MISO line properly when their Chip Select (`CS`) line goes high, which interferes with other peripherals on a shared bus.

---

## 3. Where to Modify Code Configuration

To adapt ESPuino to your hardware setup without PCA9555:

1. **`platformio.ini`**:
   - Activate the build environment `esp32-s3-devkitc-1` or ensure `-DHAL=99` is configured to use the custom board header (`settings-custom.h`).

2. **`src/settings.h` / `src/settings-override.h`**:
   - Ensure `#define PORT_EXPANDER_ENABLE` is **commented out / disabled**.
   - Ensure `#define USEROTARY_ENABLE` is **commented out / disabled** (no rotary encoder in this build).
   - Ensure `#define MEASURE_BATTERY_VOLTAGE` is **enabled** (battery-voltage monitoring via ADC + voltage-divider).
   - Set `#define NUM_LEDS 12` for your 12-LED WS2812B ring.
   - You can create `src/settings-override.h` to override default settings without modifying base project files directly.

3. **`src/settings-custom.h`**:
   - Define the exact GPIO pins for your ESP32-S3 board for each peripheral module.

---

## 4. Proposed Wiring Diagram

> [!NOTE]
> The ESP32-S3 allows mapping SPI and I2S peripherals to almost any available GPIO pins. Below is a recommended clean, conflict-free pin mapping assignment.

### Pinout Diagram (ESP32-S3-DevKitC-1)

> [!IMPORTANT]
> **Revision note:** the original draft of this diagram scattered the MFRC522 RFID pins across the header (CS on pin 20, SCK on pin 15, MOSI on pin 13, MISO on pin 12, RST way up on pin 4). Electrically that's fine — the ESP32-S3 can route SPI to almost any GPIO — but physically it meant jumper wires criss-crossing the header and interleaving with the MicroSD wires. The layout below instead follows the **actual physical pin order** of the J1/J3 headers as published in the [ESP32-S3-DevKitC-1 v1.0 User Guide pin layout](https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32s3/_images/ESP32-S3_DevKitC-1_pinlayout.jpg), so all 5 RFID signals sit on **5 consecutive physical pins** (J1, positions 4-8), and the MicroSD SPI wires stay on their own consecutive run (J1, positions 16-19) right below them — no interleaving, no crossed wires.

```text
                      ESP32-S3-DevKitC-1 (top view, Micro-USB port at the bottom)

        J1 — left header                              J3 — right header
        ----------------                              ------------------
   1    3V3                                       1    GND
   2    3V3                                       2    GPIO43 (U0TXD)
   3    RST (EN, chip reset — not a free GPIO)     3    GPIO44 (U0RXD)
   4    GPIO4   ───► RFID RST                      4    GPIO1  ───► Btn PLAY/PAUSE
   5    GPIO5   ───► RFID MISO                      5    GPIO2  ───► Btn NEXT
   6    GPIO6   ───► RFID MOSI                      6    GPIO42 ───► Btn PREV
   7    GPIO7   ───► RFID SCK                        7    GPIO41 (free — no rotary encoder)
   8    GPIO15  ───► RFID CS (SDA)                  8    GPIO40 (free — no rotary encoder)
   9    GPIO16  (free)                              9    GPIO39 (JTAG MTCK — avoid)
   10   GPIO17  (free)                             10    GPIO38 (free — no ADC channel, see note below)
   11   GPIO18  (free)                             11    GPIO37 * reserved (Octal PSRAM/Flash)
   12   GPIO8   (free)                              12    GPIO36 * reserved (Octal PSRAM/Flash)
   13   GPIO3   (free — strapping pin, best avoided) 13    GPIO35 * reserved (Octal PSRAM/Flash)
   14   GPIO46  (input-only, free)                  14    GPIO0  (strapping pin — avoid)
   15   GPIO9   ───► Battery ADC (voltage-divider)   15    GPIO45 ───► I2S LRC (WS)
   16   GPIO10  ───► SD CS (SS)                     16    GPIO48 ───► WS2812B LED DIN
   17   GPIO11  ───► SD MOSI (CMD)                  17    GPIO47 ───► I2S BCLK
   18   GPIO12  ───► SD SCK (CLK)                   18    GPIO21 ───► I2S DIN
   19   GPIO13  ───► SD MISO (DAT0)                 19    GPIO20 (USB D+ — avoid)
   20   GPIO14  (free)                              20    GPIO19 (USB D- — avoid)
   21   5V                                          21    GND
   22   GND                                         22    GND
```

`*` On the N16R8 module (Octal SPI Flash + Octal PSRAM used in this build), GPIO35/36/37 are used internally and must not be wired to anything.

Power/GND for the RFID reader: pull 3.3V from **J1 pin 1 or 2** (right at the top of the same header the RFID signals live on) and GND from either **J1 pin 22** or **J3 pin 1** — whichever is more convenient for your wiring, since GND is common across the whole board.

---

## 5. Detailed Pin-by-Pin Wiring Table

### A. Audio DAC (MAX98357A I2S)
| MAX98357A Pin | ESP32-S3 Pin | Code Configuration (`settings-custom.h`) |
| :--- | :--- | :--- |
| **LRC (WS)** | GPIO 45 | `#define I2S_LRC 45` |
| **BCLK** | GPIO 47 | `#define I2S_BCLK 47` |
| **DIN** | GPIO 21 | `#define I2S_DOUT 21` |
| **GND** | GND | Common GND |
| **VIN** | 5V / 3.3V | Power supply |
| **GAIN** | GND | Default gain (12dB) or configured as needed |

### B. MicroSD Card Module (SPI Bus 1 - 3.3V)
| MicroSD Pin | ESP32-S3 Pin | Code Configuration (`settings-custom.h`) |
| :--- | :--- | :--- |
| **CS** | GPIO 10 | `#define SPISD_CS 10` |
| **MOSI** | GPIO 11 | `#define SPISD_MOSI 11` |
| **SCK** | GPIO 12 | `#define SPISD_SCK 12` |
| **MISO** | GPIO 13 | `#define SPISD_MISO 13` |
| **VCC** | 3.3V | 3.3V power supply |
| **GND** | GND | Common GND |

### C. Neopixel 12-Bit Ring (WS2812B)
| Neopixel Pin | ESP32-S3 Pin / Power | Code Configuration |
| :--- | :--- | :--- |
| **DI / DIN** | GPIO 48 | `#define LED_PIN 48` |
| **+5V** | 5V (USB / PSU) | Recommended 5V dedicated line |
| **GND** | GND | Common GND |

> [!IMPORTANT]
> Make sure to set `#define NUM_LEDS 12` in `settings.h` or `settings-override.h`.

### D. MFRC522 RFID Reader (SPI Bus 2)

All 5 signal pins now sit on **consecutive physical pins on header J1** (pins 4-8), right under the 3V3 pins at the top of that same header — so the whole module can be wired with short, parallel jumpers instead of reaching across the board.

| RC522 Pin | ESP32-S3 Pin | J1 Header Position | Code Configuration (`settings-custom.h`) |
| :--- | :--- | :--- | :--- |
| **RST** | GPIO 4 | J1-4 | `#define RFID_RST 4` |
| **MISO** | GPIO 5 | J1-5 | `#define RFID_MISO 5` |
| **MOSI** | GPIO 6 | J1-6 | `#define RFID_MOSI 6` |
| **SCK** | GPIO 7 | J1-7 | `#define RFID_SCK 7` |
| **SDA / CS** | GPIO 15 | J1-8 | `#define RFID_CS 15` |
| **3.3V** | 3.3V | J1-1 or J1-2 | **IMPORTANT**: 3.3V ONLY |
| **GND** | GND | J1-22 (or J3-1) | Common GND |

> These replace the previous assignment (CS=14, SCK=9, MOSI=3, MISO=8, RST=4), which was electrically valid but physically scattered across the header and interleaved with the MicroSD SPI wires. GPIO3 in particular is also a JTAG strapping pin, so moving off it is a nice side benefit — it's now free again.

### E. Direct Buttons (Without PCA9555)
| Button / Function | ESP32-S3 Pin | Code Configuration (`settings-custom.h`) |
| :--- | :--- | :--- |
| **PAUSE/PLAY** | GPIO 1 | `#define PAUSEPLAY_BUTTON 1` |
| **NEXT** | GPIO 2 | `#define NEXT_BUTTON 2` |
| **PREVIOUS** | GPIO 42 | `#define PREVIOUS_BUTTON 42` |

> [!NOTE]
> No rotary encoder in this build: `USEROTARY_ENABLE` is disabled in `settings-override.h`, so
> `ROTARYENCODER_CLK`/`ROTARYENCODER_DT` (GPIO40/GPIO41) are left unwired and free for other use.
> `WAKEUP_BUTTON` is set to `PAUSEPLAY_BUTTON`, so deep-sleep wakeup does not depend on the rotary
> encoder either.

### F. Battery Voltage Monitoring (ADC + Voltage-Divider)

No fuel-gauge IC — just a resistor divider into an ADC-capable GPIO.

> [!IMPORTANT]
> **The pin must be an ADC1 channel.** On the ESP32-S3, *only* GPIO1-10 have any ADC functionality at
> all (ADC1 = GPIO1-10, ADC2 = GPIO11-20). ADC2 is unusable here anyway since it's shared with the
> WiFi driver and reads become unreliable once WiFi is connected. Any other GPIO — including GPIO38,
> used in an earlier draft of this doc — has **no ADC channel whatsoever**; `analogReadMilliVolts()`
> on such a pin doesn't just read garbage, it crashes the firmware (`Guru Meditation Error:
> LoadProhibited` inside `__analogReadMilliVolts`), because the Arduino core doesn't check the error
> return from `adc_oneshot_io_to_channel()` before indexing an internal handle array with the
> (uninitialized) unit number. GPIO9 was chosen because it's the last free ADC1 pin — GPIO1/2/4/5/6/7/10
> are already used by buttons/RFID/SD, and GPIO3 is a strapping pin best left alone.

| Signal | ESP32-S3 Pin | Code Configuration (`settings-custom.h` / `settings-override.h`) |
| :--- | :--- | :--- |
| **Battery ADC** | GPIO 9 | `#define VOLTAGE_READ_PIN 9` |
| **Divider R1** (Battery+ → ADC node) | 100 kΩ | `constexpr uint16_t rdiv1 = 100;` |
| **Divider R2** (ADC node → GND) | 100 kΩ | `constexpr uint16_t rdiv2 = 100;` |
| **ADC attenuation** | — | `constexpr adc_attenuation_t inputAttenuation = ADC_11db;` |

Wiring: `Battery+` → `R1 (100k)` → **junction (also to GPIO9)** → `R2 (100k)` → `GND`. With a 1:1
divider the ADC sees half of battery voltage, so a fully-charged single-cell LiPo (~4.2V) reads as
~2.1V at the pin — safely inside the ESP32-S3's ADC input range. Enable the feature with
`#define MEASURE_BATTERY_VOLTAGE` in `settings-override.h`.

Thresholds in `settings-override.h` are tuned for a single-cell LiPo (full 4.2V / nominal 3.7V / safe
cutoff 3.2-3.3V / absolute minimum 3.0V / damage zone below 2.5V):

| Constant | Value | Meaning |
| :--- | :--- | :--- |
| `s_voltageIndicatorHigh` | 4.2V | LED indicator / charge-% reads 100% at or above this |
| `s_voltageIndicatorLow` | 3.2V | LED indicator / charge-% reads 0% at or below this |
| `s_warningLowVoltage` | 3.3V | `Battery_IsLow()` warning threshold |
| `s_warningCriticalVoltage` | 3.2V | `Battery_IsCritical()` threshold (top of the safe-cutoff range, well clear of the 2.5V damage zone) |

> [!NOTE]
> These four values are seeded into NVS (flash) on first boot only — `Battery_InitInner()` in
> `src/BatteryMeasureVoltage.cpp` reads them from NVS first and only falls back to the header constants
> if nothing is stored yet. If you already booted once with different defaults, editing the header
> won't change the running device; update the values on the Web UI's battery-settings tab instead
> (or erase NVS to re-seed from the header).

### On-Demand Measurement (Web UI / Logs)

`CMD_MEASUREBATTERY` (id `178`) triggers an immediate measurement: it logs the current voltage and
charge estimate (`Battery_LogStatus()`), publishes to MQTT if enabled, and flashes the LED voltage
indicator. It's reachable from:
- **Control tab** → **"Execute Modification"** section (below the track/progress display) → select
  **"🔋 Show battery voltage"** in the **Modification** dropdown → **Execute** button.
- A physical button (already mapped to `BUTTON_3_SHORT` in `settings-override.h`).
- An RFID modification tag assigned to command `178`.
- MQTT / the generic websocket `{"controls":{"action": 178}}` message.

The serial log line looks like:
```
I [xxxxx] Current battery-voltage: 3.87 V
I [xxxxx] Current battery charge: 64.29 %
```

### Spoken Battery-Level Announcement

`CMD_TELL_BATTERY_LEVEL` (id `157`) speaks the battery level out loud through the speaker, the same
way `CMD_TELL_IP_ADDRESS` (151, "Announce IP-Address") and `CMD_TELL_CURRENT_TIME` (152, "Announce
current time") already do — via the `connecttospeech()` online TTS engine (Google Translate TTS), so
**it requires an active WiFi connection**, independent of whether `MEASURE_BATTERY_VOLTAGE` is wired up.
It says something like *"Battery level: 82 percent, 3.97 volts"* (localized to DE/EN/FR based on the
firmware's `LANGUAGE` setting). Reachable the same way as above — select **"🔋 Announce battery
level"** instead of **"🔋 Show battery voltage"** in the same dropdown, or assign it to a button/RFID
tag/MQTT/websocket the same way (action id `157`).

### Automatic Low-Battery Warning (LED + Speech)

When a periodic measurement (`Battery_Cyclic()` in `src/Battery.cpp`, every `s_batteryCheckInterval`
minutes) finds the voltage below `s_warningLowVoltage`, ESPuino already flashed the LED voltage
warning and logged an error — it now **also speaks** *"Battery low: 82 percent, 3.97 volts"* the same
way as the on-demand announcement above, provided WiFi is connected (silently skipped otherwise; the
LED/log warning still fires regardless of WiFi).

This is edge-triggered, not repeated every check: it speaks once when voltage first drops below
`s_warningLowVoltage`, and won't speak again until the level recovers above that threshold and drops
below it again — otherwise, with a short check interval (some users set it to 1 minute via the Web
UI), it would nag every single cycle while low. The LED warning and log line still repeat every check
as before; only the speech is throttled to once per low-battery episode.

## 6. Web UI & Language Settings

The embedded ESPuino Web Interface (`management.html` & `accesspoint.html`) features internationalization (i18n):
- **Supported Languages**: German (`de`), English (`en`), and French (`fr`).
- **Language Detection**: Automatically defaults to the client browser language (`navigator.language`) with fallback to English (`en`).
- **Dynamic Switching**: Change the UI language at runtime via the dropdown selector (`#langSel`) in the top navigation header. The chosen language persists in browser `localStorage`.
- **Extending Languages**: Add a new translation file `html/locales/[lang].json` and add a matching `<option value="[lang]">` entry to `#langSel` in `management.html` & `accesspoint.html`.

---

## 7. Next Steps

1. **Create `settings-override.h`** with your module selection (disabling `PORT_EXPANDER_ENABLE` and
   `USEROTARY_ENABLE`, enabling `MEASURE_BATTERY_VOLTAGE`).
2. **Configure `settings-custom.h`** with the GPIOs listed above.
3. Build and test the project using PlatformIO corresponding to the ESP32-S3 target environment (`-DHAL=99`).