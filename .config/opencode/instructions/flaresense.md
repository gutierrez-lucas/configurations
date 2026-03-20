# FlareSense — IoT Environmental Monitoring Firmware
**Repo:** `/home/lucas/Work/FlareSense`
**Stack:** C/C++ (gnu++17), ESP-IDF v5.4.2, FreeRTOS, CMake
**Author:** @GutierrezJLucas

## 1. What is FlareSense?

FlareSense is an ESP32-based IoT firmware for environmental monitoring stations. Devices wake from deep sleep, read sensors, upload data to the cloud, then return to deep sleep. Multiple deployed stations exist in the field.

**Hardware target:** ESP32 (primary board: LilyGO SIM7000G)
**Flash layouts:**
- Standard: 8 MB flash, dual-OTA partitions (`partitions.csv`)
- Lite: 4 MB flash, no OTA (`partitions_lite.csv`) — enabled via `CONFIG_FLS_PARTITION_LITE`

**Current version:** v3.20.x (see `version.env`)
**Deployed stations:** `config/deployed/` — each `.cfg` is a per-station sdkconfig fragment (SSID, node ID, sensor mix, etc.): Abrojitos, El_Sauce, Mar_del_sur_G2, miramar

## 2. Repository Structure

```
/home/lucas/Work/FlareSense/
├── main/
│   ├── main.c                  # app_main() — wakeup dispatch, task init, deep sleep
│   ├── Kconfig.projbuild       # Top-level Kconfig: partition layout, PRODUCTION_BUILD
│   ├── config_checks.h         # Compile-time safety guards (_FLS_FATAL/_FLS_HAZARD/_FLS_NOTICE)
│   ├── sync_bits.h             # FreeRTOS EventGroup bit definitions for task sync
│   └── server_root_cert.pem    # TLS root cert for HTTPS OTA / cloud endpoints
├── component/
│   ├── fls-sensors/            # Sensor abstraction layer + all sensor drivers
│   ├── fls-cloud/              # Firebase HTTP upload + OTA manifest header
│   ├── fls-storage/            # SPIFFS + SD card persistence (system state, sensor data, SMS)
│   ├── fls-network/            # Network FSM: WiFi / GSM modem / satellite / SMS
│   ├── fls-time/               # NTP sync + sleep timer logic
│   ├── fls-util/               # Shared utilities (deep sleep, watchdog, factory reset)
│   ├── fls-poma/               # POMA local management API (WiFi socket or BLE)
│   ├── fls-display/            # Optional e-ink/display support
│   └── fls-ota/                # GitHub Releases OTA client (fls_github_ota.h)
├── config/
│   ├── default.cfg             # Base sdkconfig for local dev builds
│   ├── default-ota.cfg         # Base sdkconfig for OTA-enabled production builds
│   ├── ota_poma_ble.cfg        # OTA + POMA via BLE
│   ├── deployed/               # Per-station configs: Abrojitos, El_Sauce, Mar_del_sur_G2, miramar
│   └── development/            # Dev/test configs: p2p_main, p2p_sensor, flare_lite, fail_test, ps_test1
├── CMakeLists.txt              # Build system: version generation, component registration
├── version.env                 # MAJOR=3 MINOR=20 — source and export for shell/CI
├── partitions.csv              # 8 MB dual-OTA partition table (standard)
├── partitions_lite.csv         # 4 MB no-OTA partition table (lite)
├── sdkconfig.default           # Default sdkconfig committed to repo
├── docs/
│   └── used_pins.md            # LilyGO SIM7000G pin assignments
└── .github/workflows/
    ├── ota-build.yml           # CI: build firmware, create GitHub Release, post to Firebase
    └── manual-ota-trigger.yml  # CI: manually trigger OTA push to devices
```

## 3. Wakeup Sources & Boot Flow

`app_main()` in `main/main.c` dispatches on `sys_status.wakeup_source`:

| Wakeup Source | Behaviour |
|---------------|-----------|
| `WAKEUP_DEFAULT` | Normal cycle: init network, read sensors, upload, deep sleep |
| `WAKEUP_POMA` | Init network + POMA session (WiFi socket or BLE) for configuration |
| `WAKEUP_DISPLAY` | Update display only |
| `WAKEUP_FACTORY_RESTORE` | Wipe SPIFFS config + restart |
| `WAKEUP_AND_RESET` | Basic reset — call `esp_restart()` |

**Initialization order:** `InitSPIFF()` → `fls_network_init()` → `display_init()` (if enabled) → `storage_init()` → `utils_init()` → `sensor_init()` → network task → wait on `MEMORY_LOG_DONE_EVENT` → `force_deep_sleep()`

## 4. Component Reference

### fls-sensors
- All sensors implement a uniform `sensor_t` vtable: `init`, `get`, `post`, `encode`, `decode`, `show`, `list`, `configure`, `clear`
- Sensor registration is Kconfig-driven — `active_sensors.h` calls `*_register()` for each enabled sensor
- Use `DECLARE_SENSOR_METHODS()` and `REFERENCE_SENSORS_METHODS()` macros when implementing a new driver

**Supported sensors:**

| Sensor | Config Flag | Interface | Measurement |
|--------|------------|-----------|-------------|
| DS18B20 | `CONFIG_USE_DS18B20` | 1-Wire | Temperature |
| DS18B20 (aux) | `CONFIG_USE_AUX_DS18B20` | 1-Wire | Temperature (secondary) |
| SHT3x | `CONFIG_USE_SHT3x` | I2C | Temperature + Humidity |
| BH1750 | `CONFIG_USE_BH1750` | I2C | Light (lux) |
| Battery | `CONFIG_USE_BATT` | ADC1 | Voltage (mV), thresholds: detection 1000 mV, low 3000 mV, hibernation 3500 mV |
| NiuBoL Weather Station | `CONFIG_USE_WEATHER_STATION` | RS-485 (UART) | Full weather data |
| Rain Gauge WS | `CONFIG_USE_RAING_WS` | RS-485 (UART) | Rainfall |
| RTC (DS1307) | `CONFIG_USE_RTC` | I2C | Timestamp |

**Firebase field names** (from `fls-sensors.h` comments): `timestamp`, `deviceId`, `temperature`, `temperature_aux`, `humidity`, `humidity_aux`, `pressure`, `dew_point`, `uvi`, `wind_direction`, `wind_gust`, `wind_speed`, `cloud_cover`, `rain`, `rtc`

### fls-network
- Communication modes: `COM_MODE_WIFI`, `COM_MODE_MOBILE`, `COM_MODE_SATELLITE`, `COM_MODE_SMS`, `COM_MODE_UNIQUE`
- Network FSM states: `CLOSED → INIT_OK/FAIL → UPLOAD_OK/FAIL → RETRY_OK/FAIL → TOGGLE_OK/FAIL → END`
- Upload modes: `UPLOAD_WIFI`, `UPLOAD_MODEM`, `UPLOAD_SMS`
- **WiFi:** up to 4 SSIDs (`CONFIG_FLS_WIFI_SSID` through `_4`); optional probe-by-signal-strength (`CONFIG_FLS_WIFI_PROBE_NETWORKS`); reconnect via WiFi attempted every N hours when modem is primary
- **Modem:** SIM7000G or SIM800; UART-based PPP; Argentine carrier APNs pre-configured (Conecty Flex/Personal/Movistar, Personal, Movistar, Claro); optional SMS fallback
- **Satellite:** Myriota Flex or HyperPulse; GNSS-assisted with configurable max attempts; suspension mode; saves config to ROM
- **SMS:** secondary fallback channel (`CONFIG_FLS_NETWORK_MODEM_USE_SMS`); configurable phone number
- When both WiFi and Modem are enabled, `CONFIG_FLS_PRIORITY_WIFI` or `CONFIG_FLS_PRIORITY_MODEM` selects the primary

### fls-storage
- **SPIFFS:** Primary non-volatile storage — system state (`sys_status`), sensor readings, config
- **SD card:** Secondary data log (`CONFIG_FLS_USE_SD`) — FAT, requires `CONFIG_FATFS_LFN_HEAP` for long filenames
- Sub-modules: `fls-storage_system.h` (sys_status), `fls-storage_sensors.h`, `fls-storage_sd.h`, `fls-storage_sms.h`
- `storage_init()` failing causes `force_deep_sleep(SLEEP_ONE_PERIOD)` immediately

### fls-poma
- Local management API for field configuration without reflashing
- **Transport options:** WiFi AP mode (device creates `FS_POMA` hotspot), WiFi Station mode (device joins existing WiFi), BLE (NimBLE stack)
- **Default AP:** SSID `FS_POMA`, password `stream123123456`, gateway IP `1.0.0.1`, port `666`
- **Authentication:** user + password challenge; system is locked by default (`get(system,lock)` → `1`); unlock with `set(system,lock,0)`
- **Watchdog** is refreshed on every command received during a POMA session
- **Commands:** `get(type,element)`, `set(type,element,value1[,value2])`, `restart()`, `exit()`, `deepsleep()`, `help()`
- **Types/elements:** `time.(period|cycle)`, `system.(lock|factoryrestore|firmware|id|battery)`, `sensors.(fulljson|list)`, `comm.(user|password|mode|signal|IMEI)`

### fls-ota
- OTA client fetches firmware binary from a GitHub Releases URL
- TLS with `server_root_cert.pem` embedded at build time
- Requires 8 MB flash + dual-OTA partition layout (`partitions.csv`)
- Incompatible with `CONFIG_FLS_PARTITION_LITE`

### fls-cloud
- `firebase.h` — HTTPS POST of sensor JSON to Firebase Realtime Database
- `ota.h` — OTA manifest parsing helpers

## 5. Build System & Versioning

**Version format:** `v{MAJOR}.{MINOR}.{COMMIT_COUNT}-{BRANCH}-{SHA}[-dirty]`
- Example: `v3.20.277-main-a050ed7`
- `MAJOR` and `MINOR` come from `version.env`; patch is the git commit count; `-dirty` appended if working tree has changes
- Embedded into the binary as the `FLARESENSE_FW_VERSION` compile definition

**Build commands:**
```bash
# Standard dev build
idf.py build

# OTA-enabled build
FLARE_SENSE_TARGET=default-ota idf.py build

# Custom version override
idf.py build -DFLARESENSE_VERSION_MAJOR=3 -DFLARESENSE_VERSION_MINOR=21

# Flash + monitor
idf.py -p /dev/ttyUSB0 flash monitor

# Menuconfig
idf.py menuconfig
```

**Per-station build:**
```bash
cp config/deployed/El_Sauce.cfg sdkconfig.defaults
rm -f sdkconfig
idf.py build
```

**Initial flash (esptool):**
```bash
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 460800 \
  --before default_reset --after hard_reset write_flash \
  --flash_mode dio --flash_freq 40m --flash_size 4MB \
  0x1000 bootloader.bin \
  0x8000 partition-table.bin \
  0x10000 main.bin
```

## 6. CI/CD Pipeline

**`ota-build.yml`** (manual `workflow_dispatch` only):
- Target: `esp32`, ESP-IDF `v5.4.2`
- Injects `CONFIG_PRODUCTION_BUILD=y` — any `_FLS_HAZARD` flag becomes a build error that aborts CI
- Steps: checkout → remove cached sdkconfig → apply selected config → `idf.py reconfigure` → `idf.py build` → SHA256 hash → GitHub Release → post metadata JSON to Firebase
- Config selection: dropdown of all known `.cfg` files + `custom` option
- Artifacts: `FlareSense-OTA-{version}` (90-day retention), `FlareSense-Complete-{version}` (60-day retention), build logs on failure (7-day)
- Build summary includes: version, size, SHA256, cache hit stats, config check errors parsed from build log

**`manual-ota-trigger.yml`:** Sends OTA push command to specific devices after a release is ready.

**GitHub Secrets required:** `FIREBASE_FUNCTION_URL`, `FIREBASE_TOKEN`

## 7. Compile-Time Config Safety (`main/config_checks.h`)

Three tiers enforced via `#include "config_checks.h"` in `main/main.c`:

| Macro | Dev build | Production build (`CONFIG_PRODUCTION_BUILD=y`) | When to use |
|-------|-----------|------------------------------------------------|-------------|
| `_FLS_FATAL(msg)` | Error | Error | Hardware invariants that are never correct |
| `_FLS_HAZARD(msg)` | Warning | **Error** (blocks CI) | Debug/test flags that must be stripped before release |
| `_FLS_NOTICE(msg)` | Warning | Warning | Unusual-but-valid configurations |

**Flags that block production builds (`_FLS_HAZARD`):**
`CONFIG_ESP_SYSTEM_PANIC_GDBSTUB`, `CONFIG_ENDPOINT_TEST`, `CONFIG_TEST_PENDING`, `CONFIG_FLS_SATELLITE_TEST`, `CONFIG_FLS_NETWORK_MODEM_TEST_POMA_SMS`, `CONFIG_FLS_NETWORK_MODEM_SMS_DISPLAY_MSG`, `CONFIG_MANIFEST_DEBUG`, `CONFIG_PRINT_STORED_DATA`, `CONFIG_FLS_SATELLITE_DEBUG`, `CONFIG_RTC_TEST`, `CONFIG_BATT_TEST`, `CONFIG_SHT3x_TEST`, `CONFIG_WEATHER_STATION_TEST`, `CONFIG_RAING_WS_TEST`, `CONFIG_DS18B20_TEST`, `CONFIG_BH1750_TEST`, `CONFIG_REMOTE_SENSOR_TEST`, `CONFIG_WIFI_FORCE_FAIL`, `CONFIG_MODEM_FORCE_FAIL`, missing `CONFIG_USE_WATCHDOG`, missing `CONFIG_FLS_USE_SD`

**Fatal invariants (`_FLS_FATAL`):**
- Flash must be 8 MB unless `CONFIG_FLS_PARTITION_LITE=y` (then 4 MB); mismatch is always an error
- `CONFIG_FLS_PARTITION_LITE` and `CONFIG_USE_OTA` cannot both be set
- `CONFIG_PARTITION_TABLE_CUSTOM` must be set
- `CONFIG_FATFS_LFN_HEAP` must be set
- Modem requires `CONFIG_LWIP_PPP_SUPPORT`
- `CONFIG_POMA_WIFI` requires `CONFIG_FLS_NETWORK_USE_WIFI`
- `CONFIG_POMA_BLE` requires `CONFIG_BT_ENABLED` + `CONFIG_BT_NIMBLE_ENABLED`
- Both `CONFIG_DS18B20_IS_AUX` and `CONFIG_SHT3x_IS_AUX` cannot be set simultaneously

## 8. Pin Assignments (LilyGO SIM7000G)

| Pins | Function |
|------|----------|
| 18, 19, 5 | Rain Gauge / Weather Station RS-485 |
| 21, 22 | I2C bus |
| 13, 14, 15, 2 | SD card (SPI) |
| 35 | Battery ADC |
| 12 | Reset pin |
| 25, 26, 27 | RGB LEDs |

## 9. Instructions for OpenCode (FlareSense-specific)

- This is an embedded C/C++ firmware project. All source is C or C++. Never suggest npm, yarn, pip, or web-stack tooling.
- Build system is ESP-IDF / CMake. The build command is `idf.py build`. Do not use `make` directly.
- Sensor drivers follow the `sensor_t` vtable pattern — new sensors must implement all vtable methods and register in `active_sensors.h` under an appropriate `#ifdef CONFIG_USE_*` guard.
- All feature flags are Kconfig-controlled. Use `menuconfig` or `.cfg` fragment files, never bare `#define` in source.
- `CONFIG_PRODUCTION_BUILD=y` is injected by CI for every OTA build. Any `_FLS_HAZARD` flag left ON will break the CI build. Always check `config_checks.h` when adding debug flags.
- When adding new compile-time checks, add them to `main/config_checks.h` using `_FLS_FATAL`, `_FLS_HAZARD`, or `_FLS_NOTICE` as appropriate.
- SPIFFS is the primary storage; SD card is optional. Do not assume SD is present unless `CONFIG_FLS_USE_SD` is set.
- Deep sleep is the normal terminal state of every run. All tasks must complete and signal their EventGroup bits before `force_deep_sleep()` is called. Never block the main task indefinitely.
- Per-station configs live in `config/deployed/`. When working on station-specific behaviour, check these files first — do not hardcode station values in source.
- The POMA API is the field configuration interface. Do not break backward POMA command compatibility without explicit instruction from the user.
