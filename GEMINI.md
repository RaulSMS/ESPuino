# ESPuino Project Knowledge & Architecture Guide

## Communication & Documentation Standards
- **Language**: ALL documentation, markdown files (`GEMINI.md`, `FirstSteps.md`, implementation plans, walkthroughs), comments, commit notes, and assistant responses MUST BE WRITTEN IN ENGLISH FIRST AND EXCLUSIVELY unless explicitly requested otherwise by the user.

## Overview
ESPuino is an ESP32-based RFID audio player designed as an open-source alternative to Toniebox / Phoniebox. It supports local audio playback from MicroSD card, Web UI management, Bluetooth audio (A2DP sink/source), MQTT, FTP, Neopixel RGB LED feedback, and various RFID readers (MFRC522 SPI/I2C, PN5180).

## Environment & Build System
- **PlatformIO Framework**: Dual `arduino` + `espidf` using custom espressif32 platform toolchain (`pioarduino`).
- **Configuration Structure**:
  - `platformio.ini`: Defines build environments, platform parameters, flash partition schemes (`custom_16mb_ota.csv`, `custom_4mb_noota.csv`), and `HAL` defines.
  - `settings.h`: Global configuration, module toggles (`NEOPIXEL_ENABLE`, `MQTT_ENABLE`, `FTP_ENABLE`, `BLUETOOTH_ENABLE`, `PORT_EXPANDER_ENABLE`), button mapping to commands, and includes board-specific HAL configs.
  - `settings-override.h`: If present, overrides `settings.h` defaults.
  - HAL header files (`settings-custom.h`, `settings-lolin_d32_pro.h`, `settings-lolin_d32_pro_sdmmc_pe.h`, `settings-complete.h`, `settings-ttgo_t8.h`): Specify board pinouts for SD Card, I2S DAC, SPI RFID, Rotary Encoder, Buttons, Neopixel, Power controls, etc.

## Hardware Abstraction Levels (HAL)
- `HAL 4`: Wemos Lolin D32 pro (`settings-lolin_d32_pro.h`)
- `HAL 5`: Lilygo T8 V1.7 (`settings-ttgo_t8.h`)
- `HAL 6`: ESPuino complete board (`settings-complete.h`)
- `HAL 7`: Lolin D32 pro SDMMC + Port-Expander PCA9555 (`settings-lolin_d32_pro_sdmmc_pe.h`)
- `HAL 99`: Custom setup (`settings-custom.h`) - Target HAL for custom pin configurations without port expanders or custom boards.

## Key Hardware Subsystems & Pinout Considerations
1. **ESP32 Core / PSRAM**:
   - ESP32-S3 / ESP32 with PSRAM is recommended.
   - Strapping pins and input-only pins (GPIO 34-39 on classic ESP32) must be noted (GPIO 34-39 lack internal pull-ups).
2. **Audio Subsystem (I2S)**:
   - DACs used: MAX98357A, PCM5102A, AC101, PT2811.
   - Standard I2S pins: `I2S_DOUT`, `I2S_BCLK`, `I2S_LRC`.
   - Software: `ESP32-audioI2S` library by Joe91 / Earle F. Philhower foundation.
3. **Storage (MicroSD)**:
   - Modes: SD_MMC (1-bit / 4-bit) or SPI mode (`SPISD_CS`, `SPISD_MOSI`, `SPISD_MISO`, `SPISD_SCK`).
4. **RFID Readers**:
   - MFRC522 (SPI or I2C) or PN5180 (SPI).
   - Dedicated SPI bus or shared SPI bus (`RFID_CS`, `RFID_MOSI`, `RFID_MISO`, `RFID_SCK`).
5. **UI & Signaling**:
   - WS2812B / Neopixel ring (`LED_PIN`, `NUM_LEDS`).
   - Rotary Encoder (`ROTARYENCODER_CLK`, `ROTARYENCODER_DT`, `ROTARYENCODER_BUTTON`).
   - Physical Buttons / Port Expander (PCA9555 over I2C `0x20` if `PORT_EXPANDER_ENABLE` is set).

## Web UI & Localization Architecture
- **Web Interface Assets**: Web pages stored in `html/` (`management.html`, `accesspoint.html`, REST API specs).
- **Internationalization Engine**: Client-side `i18next` framework with `i18nextHttpBackend` and `loc-i18next`.
- **Supported Locales**: German (`de`), English (`en`), and French (`fr`), with JSON translation files located in `html/locales/` (`de.json`, `en.json`, `fr.json`).
- **Language Detection & Switching**:
  - Automatically selects `navigator.language` on first visit (defaults/fallbacks to English `en`).
  - Users can switch language dynamically via the `#langSel` dropdown selector in the Web UI navigation header.
  - User selection is saved in browser `localStorage` (`language`) to persist preference across sessions.

## Custom Configuration Workflow for User Hardware
To configure ESPuino for custom hardware (e.g. ESP32-S3-DevKitC-1-N16R8, MAX98357 I2S, 12-bit WS2812B Neopixel ring, SPI SD card, no PCA9555):
1. In `platformio.ini`, select or create a custom environment with `-DHAL=99`.
2. Disable `PORT_EXPANDER_ENABLE` in `settings.h` / `settings-custom.h`.
3. Set pin defines in `settings-custom.h`:
   - I2S pins (`I2S_DOUT`, `I2S_BCLK`, `I2S_LRC`) for MAX98357.
   - SPI SD pins (`SPISD_CS`, `SPISD_MOSI`, `SPISD_MISO`, `SPISD_SCK`).
   - Neopixel configuration (`LED_PIN`, `NUM_LEDS` set to 12).
   - RFID reader pins (SPI / I2C according to model used).
   - Direct GPIO button connections (`NEXT_BUTTON`, `PREVIOUS_BUTTON`, `PAUSEPLAY_BUTTON`, `ROTARYENCODER_BUTTON`).
