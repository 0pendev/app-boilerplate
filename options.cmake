option(IS_PLUGIN "Is this a plugin?" OFF)

########################################
#     Application custom permissions   #
########################################
option(ALLOW_DERIVE_MASTER "Allow derive master permission" OFF)
option(ALLOW_GLOBAL_PIN "Allow global pin permission" OFF)
option(ALLOW_BOLOS_SETTINGS "Allow access to BOLOS settings" OFF)
option(ALLOW_LIBRARY "Allow library permission" OFF)

########################################
# Application communication interfaces #
########################################
option(ENABLE_BLUETOOTH "Enable Bluetooth communication" OFF)
option(ENABLE_NFC "Enable NFC communication" OFF)
option(ENABLE_SWAP "Enable swap feature" OFF)
option(ENABLE_APP_STORAGE "Enable app storage feature" OFF)

########################################
#         NBGL custom features         #
########################################
option(ENABLE_NBGL_FOR_NANO_DEVICES "Enable NBGL for nano devices" OFF)
option(ENABLE_NBGL_QRCODE "Enable NBGL QR code" OFF)
option(ENABLE_NBGL_KEYBOARD "Enable NBGL keyboard" OFF)
option(ENABLE_NBGL_KEYPAD "Enable NBGL keypad" OFF)

########################################
#          Features disablers          #
########################################
option(DISABLE_STANDARD_APP_DEFINES "Disable standard app defines" OFF)
option(DISABLE_STANDARD_SNPRINTF "Disable standard snprintf" OFF)
option(DISABLE_STANDARD_USB "Disable standard USB" OFF)
option(DISABLE_STANDARD_WEBUSB "Disable standard WebUSB" OFF)
option(DISABLE_STANDARD_BAGL_UX_FLOW "Disable standard BAGL UX flow" OFF)
option(DISABLE_STANDARD_SEPROXYHAL "Disable standard SEPROXYHAL" OFF)
option(DISABLE_STANDARD_APP_FILES "Disable standard app files" OFF)
option(DISABLE_STANDARD_APP_SYNC_RAPDU "Disable standard app sync RAPDU" OFF)
option(DISABLE_DEFAULT_IO_SEPROXY_BUFFER_SIZE "Disable default IO Seproxy buffer size" OFF)
option(DISABLE_DEBUG_LEDGER_ASSERT "Disable debug Ledger assert" OFF)
option(DISABLE_DEBUG_THROW "Disable debug throw" OFF)

# TODO
# APP_STACK_MIN_SIZE
# ENABLE_SDK_WERROR
# TARGET_NAME

# CMake migration
set(CUSTOM_APP_FLAGS 0x000 CACHE STRING "Custom app flags")
option(NOT_REVIEWED "Not reviewed" ON)
set(APP_WEBUSB_URL "" CACHE STRING "App WebUSB URL")
option(ENABLE_SDK_WERROR "Enable SDK Werror" OFF)
