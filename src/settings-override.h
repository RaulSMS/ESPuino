// clang-format off

#ifndef __ESPUINO_SETTINGS_OVERRIDE_H__
    #define __ESPUINO_SETTINGS_OVERRIDE_H__
        #include "Arduino.h"
        #include "values.h"

	//######################### INFOS ####################################
	// Custom override for ESP32-S3-DevKitC-1-N16R8 with:
	//   - MAX98357A I2S DAC
	//   - 12-LED WS2812B Neopixel ring
	//   - SPI SD card (no SD_MMC)
	//   - Rotary encoder
	//   - No PCA9555 port expander

	//################## HARDWARE-PLATFORM ###############################
	#ifndef HAL
		#define HAL 99
	#endif

	//########################## MODULES #################################
	//#define PORT_EXPANDER_ENABLE          // Disabled: PCA9555 port expander is not used
	//#define I2S_COMM_FMT_LSB_ENABLE       // Enables FMT instead of MSB for I2S-communication-format. Used e.g. by PT2811. Don't enable for MAX98357a, AC101 or PCM5102A)
	#define MDNS_ENABLE                     // Reach ESPuino via ESPuino.local
	#define MQTT_ENABLE                     // MQTT support
	#define FTP_ENABLE                      // Enables FTP server
	#define NEOPIXEL_ENABLE                 // Enable Neopixel RGB LED support
	//#define NEOPIXEL_REVERSE_ROTATION     // Some Neopixels are addressed/soldered counter-clockwise
	#define LANGUAGE EN                     // EN = english; DE = deutsch
	//#define STATIC_IP_ENABLE              // DEPRECATED: static IP
	//#define HEADPHONE_ADJUST_ENABLE       // Headphone detection disabled (HP_DETECT=99 in custom HAL)
	//#define PLAY_MONO_SPEAKER
	#define SHUTDOWN_IF_SD_BOOT_FAILS       // Put ESP to deepsleep if SD boot fails
	//#define MEASURE_BATTERY_VOLTAGE       // Battery measurement disabled for now
	//#define SHUTDOWN_ON_BAT_CRITICAL
	//#define PLAY_LAST_RFID_AFTER_REBOOT
	#define USEROTARY_ENABLE                // Rotary encoder enabled
	//#define BLUETOOTH_ENABLE              // Bluetooth disabled to save resources
	//#define IR_CONTROL_ENABLE
	//#define PAUSE_WHEN_RFID_REMOVED
	//#define DONT_ACCEPT_SAME_RFID_TWICE
	//#define RESUME_ON_SAME_RFID
	//#define HALLEFFECT_SENSOR_ENABLE

	//################## set PAUSE_WHEN_RFID_REMOVED behaviour ######################
	#ifdef PAUSE_WHEN_RFID_REMOVED
		#define ACCEPT_SAME_RFID_AFTER_TRACK_END
	#endif

	//################## select SD card mode #############################
	// Disable SD_MMC to use SPI SD card module
	//#define SD_MMC_1BIT_MODE
	//#define SINGLE_SPI_ENABLE
	//#define NO_SDCARD

	//################## select RFID reader ##############################
	// Runtime RFID Reader selection (Auto-detect)
	#define RFID_READER_TYPE_RUNTIME 0

	#if defined(RFID_READER_TYPE_MFRC522_I2C) || defined(RFID_READER_TYPE_RUNTIME)
		#define MFRC522_ADDR 0x28           // default I2C-address of MFRC522
	#endif

	#ifdef RFID_READER_TYPE_PN5180
		//#define PN5180_ENABLE_LPCD
	#endif

	#if defined(RFID_READER_TYPE_MFRC522_I2C) || defined(RFID_READER_TYPE_MFRC522_SPI) || defined(RFID_READER_TYPE_RUNTIME)
		constexpr uint8_t rfidGain = 0x07 << 4;
	#endif

	//############# Port-expander-configuration ######################
	#ifdef PORT_EXPANDER_ENABLE
		constexpr uint8_t expanderI2cAddress = 0x20;
	#endif

	//################## BUTTON-Layout ##################################
	// *****BUTTON*****        *****ACTION*****
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

	// Rotary gestures: hold the button, turn the encoder
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

	//#################### Various settings ##############################

	// Serial-logging-configuration
	#define SERIAL_LOGLEVEL LOGLEVEL_DEBUG

	// Buttons (better leave unchanged if in doubts :-))
	constexpr uint8_t buttonDebounceInterval = 50;                // Interval in ms to software-debounce buttons
	constexpr uint16_t intervalToLongPress = 700;                 // Interval in ms to distinguish between short and long press of buttons

	// Buttons active state: Default 0 for active LOW, 1 for active HIGH
	#define BUTTON_0_ACTIVE_STATE 0
	#define BUTTON_1_ACTIVE_STATE 0
	#define BUTTON_2_ACTIVE_STATE 0
	#define BUTTON_3_ACTIVE_STATE 0
	#define BUTTON_4_ACTIVE_STATE 0
	#define BUTTON_5_ACTIVE_STATE 0

	//#define CONTROLS_LOCKED_BY_DEFAULT
	#define INCLUDE_ROTARY_IN_CONTROLS_LOCK

	// RFID-RC522
	#define RFID_SCAN_INTERVAL 100

	// Automatic restart
	#ifdef SHUTDOWN_IF_SD_BOOT_FAILS
		constexpr uint32_t deepsleepTimeAfterBootFails = 20;
	#endif

	// timezone
	constexpr const char timeZone[] = "CET-1CEST,M3.5.0,M10.5.0/3"; // Europe/Berlin

	// Bluetooth
	constexpr const char nameBluetoothSinkDevice[] = "ESPuino";

	// Where to store the backup-file for NVS-records
	constexpr const char backupFile[] = "/backup.txt";

	//#################### Settings for optional Modules ##############################
	// (optional) Neopixel
	#ifdef NEOPIXEL_ENABLE
		#define NUM_INDICATOR_LEDS		12          	// 12-LED AZDelivery Neopixel ring
		#define NUM_CONTROL_LEDS		0
		#define CONTROL_LEDS_COLORS		{}
		#define CHIPSET					WS2812B     	// type of Neopixel
		#define COLOR_ORDER				GRB
		#define NUM_LEDS_IDLE_DOTS		4
		#define OFFSET_PAUSE_LEDS		false
		#define PROGRESS_HUE_START		85
		#define PROGRESS_HUE_END		-1
		#define ATMO_HUE				10
		#define ATMO_SATURATION			180
		#define DIMMABLE_STATES			50
		//#define LED_OFFSET			0
	#endif

	#ifdef MEASURE_BATTERY_VOLTAGE
		#define BATTERY_MEASURE_ENABLE
		constexpr uint8_t s_batteryCheckInterval = 10;

		constexpr float s_warningLowVoltage = 3.0;
		constexpr float s_warningCriticalVoltage = 2.9;
		constexpr float s_voltageIndicatorLow = 2.9;
		constexpr float s_voltageIndicatorHigh = 3.3;
	#endif

	// enable I2C if necessary
	#if defined(RFID_READER_TYPE_RUNTIME) || defined(RFID_READER_TYPE_MFRC522_I2C) || defined(PORT_EXPANDER_ENABLE)
		#define I2C_2_ENABLE
	#endif

	// (optional) Headphone-detection
	#ifdef HEADPHONE_ADJUST_ENABLE
		constexpr uint16_t headphoneLastDetectionDebounce = 1000;
	#endif

	// Seekmode-configuration
	constexpr uint8_t jumpOffset = 30;
	#define JUMP_OFFSET_ROTARY 10

	// MQTT
	#ifdef MQTT_ENABLE
		constexpr const char base_topic[] = "";
		constexpr const char device_id[] = "ESPuino-<MAC>";
		constexpr const char setter_token[] = "set";
		// Topics (settable)
		constexpr const char topicSleep[] = "sleep";
		constexpr const char topicRfid[] = "rfid";
		constexpr const char topicTrackControl[] = "trackcontrol";
		constexpr const char topicLoudness[] = "loudness";
		constexpr const char topicSleepTimer[] = "sleep_timer";
		constexpr const char topicLockControls[] ="lock_controls";
		constexpr const char topicRepeatMode[] = "repeatmode";
		constexpr const char topicLedBrightness[] = "led_brightness";
		constexpr const char topicAmbientLight[] = "ambient_light";

		// Topics (state only)
		constexpr const char topicTrack[] = "track";
		constexpr const char topicCoverChanged[] = "cover_changed";
		constexpr const char topicState[] = "state";
		constexpr const char topicCurrentIPv4IP[] = "ipv4";
		constexpr const char topicPausePlay[] = "pauseplay";
		constexpr const char topicPlaymode[] = "playmode";
		constexpr const char topicWiFiRssi[] = "wifi_rssi";
		constexpr const char topicSRevision[] = "software_revision";
		#ifdef BATTERY_MEASURE_ENABLE
		constexpr const char topicBatteryVoltage[] = "battery_voltage";
		constexpr const char topicBatterySOC[]     = "battery_soc";
		#endif
	#endif

	// !!! MAKE SURE TO EDIT PLATFORM SPECIFIC settings-****.h !!!
	#if (HAL == 4)
		#include "settings-lolin_d32_pro.h"
	#elif (HAL == 5)
		#include "settings-ttgo_t8.h"
	#elif (HAL == 6)
		#include "settings-complete.h"
	#elif (HAL == 7)
		#include "settings-lolin_d32_pro_sdmmc_pe.h"
	#elif (HAL == 99)
		#include "settings-custom.h"
	#endif

#endif //settings_override
