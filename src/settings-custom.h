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
    #define RST_PIN                         4           // Reset pin for RFID reader
    #define RFID_CS                         14          // GPIO for chip select (RFID)
    #define RFID_MOSI                       3           // GPIO for master out slave in (RFID)
    #define RFID_MISO                       8           // GPIO for master in slave out (RFID)
    #define RFID_SCK                        9           // GPIO for clock-signal (RFID)

    #if defined(RFID_READER_TYPE_RUNTIME) 
        #define RFID_BUSY                   16          // PN5180 BUSY PIN
        #define RFID_RST                    4           // PN5180 RESET PIN
        #define RFID_IRQ                    39          // PN5180 IRQ PIN (only needed for low power card detection)
    #endif

    // I2S (DAC MAX98357A)
    #define I2S_DOUT                        21          // Digital out (I2S)
    #define I2S_BCLK                        47          // BCLK (I2S)
    #define I2S_LRC                         45          // LRC (I2S)

    // Rotary encoder
    #ifdef USEROTARY_ENABLE
        //#define REVERSE_ROTARY                        // To reverse encoder's direction
        #define ROTARYENCODER_CLK           40          // rotary encoder's CLK
        #define ROTARYENCODER_DT            41          // rotary encoder's DT
    #endif

    // Control-buttons (set to 99 to DISABLE; 0->48 for GPIO)
    #define NEXT_BUTTON                      2          // Button 0: GPIO to detect next
    #define PREVIOUS_BUTTON                 42          // Button 1: GPIO to detect previous
    #define PAUSEPLAY_BUTTON                 1          // Button 2: GPIO to detect pause/play
    #define ROTARYENCODER_BUTTON            43          // Rotary encoder push button (or set to 99 to disable)
    #define BUTTON_4                        99          // Button 4: unnamed optional button
    #define BUTTON_5                        99          // Button 5: unnamed optional button

    // Channels of port-expander can be read cyclic or interrupt-driven.
    #ifdef PORT_EXPANDER_ENABLE
        #define PE_INTERRUPT_PIN            99          // Disabled / Unused
    #endif

    // I2C-configuration (necessary for RC522 [only via i2c - not spi!] or port-expander)
    #ifdef I2C_2_ENABLE
        #define ext_IIC_CLK                 4           // i2c-SCL (clock)
        #define ext_IIC_DATA                2           // i2c-SDA (data)
    #endif

    // Wake-up button
    #define WAKEUP_BUTTON                   PAUSEPLAY_BUTTON // Defines the button used to wake up ESPuino from deepsleep.

    // (optional) Power-control
    #define POWER                           99          // Set to 99 if not using transistor power switch circuit
    #ifdef POWER
        //#define INVERT_POWER                          // If enabled, use inverted logic for POWER circuit
    #endif

    // (optional) Neopixel WS2812B
    #define LED_PIN                         48          // GPIO for Neopixel-signaling

    // (optional) Headphone-detection
    #ifdef HEADPHONE_ADJUST_ENABLE
        //#define DETECT_HP_ON_HIGH                       // Per default headphones are supposed to be connected if HP_DETECT is LOW.
        #define HP_DETECT                   99          // Disabled / Set to 99 if no headphone jack detect pin is used
    #endif

	// (optional) Monitoring of battery-voltage via ADC
	#ifdef MEASURE_BATTERY_VOLTAGE
		#define VOLTAGE_READ_PIN	6		        // GPIO used to monitor battery-voltage via ADC
		constexpr float offsetVoltage = 0.00;		// Correction value
		constexpr uint16_t rdiv1 = 100;			    // Rdiv1 of voltage-divider (kOhms)
		constexpr uint16_t rdiv2 = 100;			    // Rdiv2 of voltage-divider (kOhms)
		constexpr adc_attenuation_t inputAttenuation = ADC_11db;
	#endif

    // (optional) hallsensor
    #ifdef HALLEFFECT_SENSOR_ENABLE
        #define HallEffectSensor_PIN        99  	// Disabled
    #endif

    // (Optional) remote control via infrared
    #ifdef IR_CONTROL_ENABLE
        #define IRLED_PIN                   99              // Disabled
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
