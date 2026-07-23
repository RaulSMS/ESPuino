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

```text
                           +------------------------+
                           |  ESP32-S3-DevKitC-1    |
                           +------------------------+
   MAX98357A (Audio I2S)   |                        |   MicroSD (SPI Bus 1)
   ---------------------   |                        |   -------------------
   LRC (WS)    <---------> | GPIO 45        GPIO 10 | <---------> CS (SS)
   BCLK        <---------> | GPIO 47        GPIO 11 | <---------> MOSI (CMD)
   DIN         <---------> | GPIO 21        GPIO 12 | <---------> SCK (CLK)
   GND         <---------> | GND            GPIO 13 | <---------> MISO (DAT0)
   VIN / VCC   <---------> | 5V / 3.3V      3.3V    | <---------> VCC
                           |                        |
   WS2812B LED Ring (12B)  |                        |   MFRC522 RFID (SPI Bus 2)
   ----------------------  |                        |   ------------------------
   DI (Data In) <--------> | GPIO 48        GPIO 14 | <---------> CS (SDA)
   VCC (5V)     <---------> | 5V             GPIO 9  | <---------> SCK
   GND          <---------> | GND            GPIO 3  | <---------> MOSI
                           |                GPIO 8  | <---------> MISO
   Buttons / Encoder       |                GPIO 4  | <---------> RST
   -----------------       |                        |
   Btn Play/Pause <------> | GPIO 1                 |
   Btn Next       <------> | GPIO 2                 |
   Btn Prev       <------> | GPIO 42                |
   Rotary CLK     <------> | GPIO 40                |
   Rotary DT      <------> | GPIO 41                |
   +5V / 3.3V / GND        | VIN / 3.3V / GND       |
                           +------------------------+
```

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
| RC522 Pin | ESP32-S3 Pin | Code Configuration (`settings-custom.h`) |
| :--- | :--- | :--- |
| **SDA / CS** | GPIO 14 | `#define RFID_CS 14` |
| **SCK** | GPIO 9 | `#define RFID_SCK 9` |
| **MOSI** | GPIO 3 | `#define RFID_MOSI 3` |
| **MISO** | GPIO 8 | `#define RFID_MISO 8` |
| **RST** | GPIO 4 | `#define RFID_RST 4` |
| **3.3V** | 3.3V | **IMPORTANT**: 3.3V ONLY |
| **GND** | GND | Common GND |

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

