// clang-format off

#ifndef __ESPUINO_SETTINGS_OVERRIDE_H__
#define __ESPUINO_SETTINGS_OVERRIDE_H__
    #include "Arduino.h"
    #include "values.h"

	// Custom HAL 99 configuration for ESP32-S3-DevKitC-1-N16R8
	#ifndef HAL
		#define HAL 99
	#endif

	// Modules Configuration
	//#define PORT_EXPANDER_ENABLE          // Disabled: PCA9555 port expander is not used
	#define MDNS_ENABLE                     // Reach ESPuino via ESPuino.local
	#define MQTT_ENABLE                     // MQTT support
	#define FTP_ENABLE                      // Enables FTP server
	#define NEOPIXEL_ENABLE                 // Enable Neopixel RGB LED support
	#define NUM_LEDS 12                     // AZDelivery 12-bit Neopixel LED ring
	#define LANGUAGE EN                     // English language
	#define SHUTDOWN_IF_SD_BOOT_FAILS       // Put ESP to deepsleep if SD boot fails
	#define USEROTARY_ENABLE                // Rotary encoder enabled

	// SD Card Configuration
	//#define SD_MMC_1BIT_MODE              // Disabled for SPI SD Card reader

	// Runtime RFID Reader selection
	#define RFID_READER_TYPE_RUNTIME 0     // Auto-detect RFID reader

	// Button Action Mapping
	#define BUTTON_0_SHORT    CMD_NEXTTRACK
	#define BUTTON_1_SHORT    CMD_PREVTRACK
	#define BUTTON_2_SHORT    CMD_PLAYPAUSE
	#define BUTTON_3_SHORT    CMD_MEASUREBATTERY
	#define BUTTON_4_SHORT    CMD_SEEK_BACKWARDS
	#define BUTTON_5_SHORT    CMD_SEEK_FORWARDS

	#define BUTTON_0_LONG     CMD_LASTTRACK
	#define BUTTON_1_LONG     CMD_FIRSTTRACK
	#define BUTTON_2_LONG     CMD_PLAYPAUSE
	#define BUTTON_3_LONG     CMD_SLEEPMODE
	#define BUTTON_4_LONG     CMD_VOLUMEUP
	#define BUTTON_5_LONG     CMD_VOLUMEDOWN

	#define BUTTON_0_ROTARY_CW   CMD_SEEK_FORWARDS
	#define BUTTON_0_ROTARY_CCW  CMD_SEEK_BACKWARDS
	#define BUTTON_1_ROTARY_CW   CMD_NOTHING
	#define BUTTON_1_ROTARY_CCW  CMD_NOTHING
	#define BUTTON_2_ROTARY_CW   CMD_BRIGHTNESS_UP
	#define BUTTON_2_ROTARY_CCW  CMD_BRIGHTNESS_DOWN
	#define BUTTON_3_ROTARY_CW   CMD_NOTHING
	#define BUTTON_3_ROTARY_CCW  CMD_NOTHING
	#define BUTTON_4_ROTARY_CW   CMD_NOTHING
	#define BUTTON_4_ROTARY_CCW  CMD_NOTHING
	#define BUTTON_5_ROTARY_CW   CMD_NOTHING
	#define BUTTON_5_ROTARY_CCW  CMD_NOTHING

	#define BUTTON_MULTI_01   CMD_NOTHING
	#define BUTTON_MULTI_02   CMD_ENABLE_FTP_SERVER
	#define BUTTON_MULTI_03   CMD_NOTHING
	#define BUTTON_MULTI_04   CMD_NOTHING
	#define BUTTON_MULTI_05   CMD_NOTHING
	#define BUTTON_MULTI_12   CMD_TELL_IP_ADDRESS
	#define BUTTON_MULTI_13   CMD_NOTHING
	#define BUTTON_MULTI_14   CMD_NOTHING
	#define BUTTON_MULTI_15   CMD_NOTHING
	#define BUTTON_MULTI_23   CMD_NOTHING
	#define BUTTON_MULTI_24   CMD_NOTHING
	#define BUTTON_MULTI_25   CMD_NOTHING
	#define BUTTON_MULTI_34   CMD_NOTHING
	#define BUTTON_MULTI_35   CMD_NOTHING
	#define BUTTON_MULTI_45   CMD_NOTHING

	#define SERIAL_LOGLEVEL LOGLEVEL_DEBUG

	constexpr uint8_t buttonDebounceInterval = 50;
	constexpr uint16_t intervalToLongPress = 700;

	#define BUTTON_0_ACTIVE_STATE 0
	#define BUTTON_1_ACTIVE_STATE 0
	#define BUTTON_2_ACTIVE_STATE 0
	#define BUTTON_3_ACTIVE_STATE 0
	#define BUTTON_4_ACTIVE_STATE 0
	#define BUTTON_5_ACTIVE_STATE 0

	#define INCLUDE_ROTARY_IN_CONTROLS_LOCK
	#define RFID_SCAN_INTERVAL 100

	#ifdef SHUTDOWN_IF_SD_BOOT_FAILS
		constexpr uint32_t deepsleepTimeAfterBootFails = 20;
	#endif

#endif
