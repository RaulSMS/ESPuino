# First Steps & Wiring Guide for Custom ESPuino (ESP32-S3)

This document describes how to configure and wire your specific hardware components for ESPuino without using the PCA9555 port expander.

---

## 1. Components Used

- **Microcontroller**: ESP32-S3-DevKitC-1-N16R8 (16MB Flash, 8MB PSRAM)
- **Audio DAC**: MAX98357A I2S 3W
- **LED Ring**: AZDelivery 3 x RGB LED Ring 5V compatible with WS2812B (12-Bit / 12 LEDs, 38mm)
- **Card Reader**: Micro SD Module 3.3V SPI
- **RFID Reader**: MFRC522 (SPI) or PN5180
- **Controls**: Direct GPIO Buttons and/or Rotary Encoder

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
   7    GPIO7   ───► RFID SCK                        7    GPIO41 ───► Rotary DT
   8    GPIO15  ───► RFID CS (SDA)                  8    GPIO40 ───► Rotary CLK
   9    GPIO16  (free)                              9    GPIO39 (JTAG MTCK — avoid)
   10   GPIO17  (free)                             10    GPIO38 (free)
   11   GPIO18  (free)                             11    GPIO37 * reserved (Octal PSRAM/Flash)
   12   GPIO8   (free)                              12    GPIO36 * reserved (Octal PSRAM/Flash)
   13   GPIO3   (free — strapping pin, best avoided) 13    GPIO35 * reserved (Octal PSRAM/Flash)
   14   GPIO46  (input-only, free)                  14    GPIO0  (strapping pin — avoid)
   15   GPIO9   (free)                              15    GPIO45 ───► I2S LRC (WS)
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
| **ROTARY CLK** | GPIO 40 | `#define ROTARYENCODER_CLK 40` |
| **ROTARY DT** | GPIO 41 | `#define ROTARYENCODER_DT 41` |

---

## 6. Web UI & Language Settings

The embedded ESPuino Web Interface (`management.html` & `accesspoint.html`) features internationalization (i18n):
- **Supported Languages**: German (`de`), English (`en`), and French (`fr`).
- **Language Detection**: Automatically defaults to the client browser language (`navigator.language`) with fallback to English (`en`).
- **Dynamic Switching**: Change the UI language at runtime via the dropdown selector (`#langSel`) in the top navigation header. The chosen language persists in browser `localStorage`.
- **Extending Languages**: Add a new translation file `html/locales/[lang].json` and add a matching `<option value="[lang]">` entry to `#langSel` in `management.html` & `accesspoint.html`.

---

## 7. Next Steps

1. **Create `settings-override.h`** with your module selection (disabling `PORT_EXPANDER_ENABLE`).
2. **Configure `settings-custom.h`** with the GPIOs listed above.
3. Build and test the project using PlatformIO corresponding to the ESP32-S3 target environment (`-DHAL=99`).