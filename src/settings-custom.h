// clang-format off

#ifndef __ESPUINO_SETTINGS_CUSTOM_H__
#define __ESPUINO_SETTINGS_CUSTOM_H__
    #include "Arduino.h"

    //######################### INFOS ####################################
    /* Custom HAL (HAL 99) tailored for ESP32-S3-DevKitC-1-N16R8.
       Configured without PCA9555 port expander.
    */

    //################## GPIO-configuration ##############################
    #ifdef SD_MMC_1BIT_MODE
        // uSD-card-reader (via SD-MMC 1Bit)
        // SD_MMC uses fixed pins
        //  (MOSI)    15  CMD
        //  (SCK)     14  SCK
        //  (MISO)     2  D0
    #else
        // uSD-card-reader (via SPI)
        #define SPISD_CS                    10          // GPIO for chip select (SD)
        #ifndef SINGLE_SPI_ENABLE
            #define SPISD_MOSI              11          // GPIO for master out slave in (SD)
            #define SPISD_MISO              13          // GPIO for master in slave out (SD)
            #define SPISD_SCK               12          // GPIO for clock-signal (SD)
        #endif
    #endif

    // RFID (via SPI - MFRC522 / PN5180)
    #define RST_PIN                         4           // GPIO4  ───► RFID RST
    #define RFID_CS                         15          // GPIO15 ───► RFID CS (SDA)
    #define RFID_MOSI                       6           // GPIO6  ───► RFID MOSI
    #define RFID_MISO                       5           // GPIO5  ───► RFID MISO
    #define RFID_SCK                        7           // GPIO7  ───► RFID SCK

    #if defined(RFID_READER_TYPE_RUNTIME) 
        #define RFID_BUSY                   99          // Avoid GPIO39 (JTAG MTCK)
        #define RFID_RST                    4           // GPIO4  ───► RFID RST
        #define RFID_IRQ                    99          // Unused / Dummy
    #endif

    // I2S (DAC MAX98357A)
    #define I2S_DOUT                        21          // GPIO21 ───► I2S DIN
    #define I2S_BCLK                        47          // GPIO47 ───► I2S BCLK
    #define I2S_LRC                         45          // GPIO45 ───► I2S LRC (WS)

    // Rotary encoder
    #ifdef USEROTARY_ENABLE
        //#define REVERSE_ROTARY                        // To reverse encoder's direction
        #define ROTARYENCODER_CLK           40          // GPIO40 ───► Rotary CLK
        #define ROTARYENCODER_DT            41          // GPIO41 ───► Rotary DT
    #endif

    // Control-buttons (set to 99 to DISABLE; 0->48 for GPIO)
    #define NEXT_BUTTON                      2          // GPIO2  ───► Btn NEXT
    #define PREVIOUS_BUTTON                 42          // GPIO42 ───► Btn PREV
    #define PAUSEPLAY_BUTTON                 1          // GPIO1  ───► Btn PLAY/PAUSE
    #define ROTARYENCODER_BUTTON            99          // Set to 99 (GPIO43 is mapped to U0TXD)
    #define BUTTON_4                        99          // Button 4: unnamed optional button
    #define BUTTON_5                        99          // Button 5: unnamed optional button

    // Channels of port-expander can be read cyclic or interrupt-driven.
    #ifdef PORT_EXPANDER_ENABLE
        #define PE_INTERRUPT_PIN            99          // Disabled / Unused
    #endif

    // I2C-configuration (necessary for RC522 [only via i2c - not spi!] or port-expander)
    #ifdef I2C_2_ENABLE
        #define ext_IIC_CLK                 16          // Assigned to free GPIO16
        #define ext_IIC_DATA                17          // Assigned to free GPIO17
    #endif

    // Wake-up button
    #define WAKEUP_BUTTON                   PAUSEPLAY_BUTTON // Defines the button used to wake up ESPuino from deepsleep.

    // (optional) Power-control
    #define POWER                           99          // Set to 99 if not using transistor power switch circuit
    #ifdef POWER
        //#define INVERT_POWER                          // If enabled, use inverted logic for POWER circuit
    #endif

    // (optional) Neopixel WS2812B
    #define LED_PIN                         48          // GPIO48 ───► WS2812B LED DIN

    // (optional) Headphone-detection
    #ifdef HEADPHONE_ADJUST_ENABLE
        //#define DETECT_HP_ON_HIGH                       // Per default headphones are supposed to be connected if HP_DETECT is LOW.
        #define HP_DETECT                   99          // Disabled / Set to 99 if no headphone jack detect pin is used
    #endif

    // (optional) Monitoring of battery-voltage via ADC
    #ifdef MEASURE_BATTERY_VOLTAGE
        // Must be an ADC1 pin (GPIO1-10 on ESP32-S3): ADC2 is unusable while WiFi is active, and no
        // other GPIO has any ADC channel at all (e.g. GPIO38 silently crashes analogReadMilliVolts()).
        #define VOLTAGE_READ_PIN            9           // Assigned to free GPIO9 (ADC1_CH8)
        constexpr float offsetVoltage = 0.00;       // Correction value
        constexpr uint16_t rdiv1 = 100;             // Rdiv1 of voltage-divider (kOhms)
        constexpr uint16_t rdiv2 = 100;             // Rdiv2 of voltage-divider (kOhms)
        constexpr adc_attenuation_t inputAttenuation = ADC_11db;
    #endif

    // (optional) hallsensor
    #ifdef HALLEFFECT_SENSOR_ENABLE
        #define HallEffectSensor_PIN        99          // Disabled
    #endif

    // (Optional) remote control via infrared
    #ifdef IR_CONTROL_ENABLE
        #define IRLED_PIN                   99          // Disabled
        #define IR_DEBOUNCE                 200
        #define RC_PLAY                     0x68
        #define RC_PAUSE                    0x67
        #define RC_NEXT                     0x6b
        #define RC_PREVIOUS                 0x6a
        #define RC_FIRST                    0x6c
        #define RC_LAST                     0x6d
        #define RC_VOL_UP                   0x1a
        #define RC_VOL_DOWN                 0x1b
        #define RC_MUTE                     0x1c
        #define RC_SHUTDOWN                 0x2a
        #define RC_BLUETOOTH                0x72
        #define RC_FTP                      0x65
    #endif
#endif