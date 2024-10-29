cmake_minimum_required(VERSION 3.11)

project(Boilerplate C ASM)

set(CMAKE_C_STANDARD 99)

# Some usefull list that helps with readability
set(WITH_TOUCHSCREEN flex stax)
set(WITH_BLUETOOTH flex nanox stax)
set(WITH_NFC flex stax)
set(WITH_BAGL nanos nanosplus nanox)
set(WITH_ARMV8 flex nanosplus stax)

# Loading BOLOS_SDK paths and definitions
set(SDK "" CACHE STRING "Path to the ledger-secure-sdk")
if(SDK STREQUAL "")
    message(FATAL_ERROR "SDK variable is required to build the app")
endif()
message("Using sdk path: " ${SDK})

# Defining the target device
set(TARGET_DEVICE "nanos" CACHE STRING "Target device")
set_property(CACHE TARGET_DEVICE PROPERTY STRINGS "flex" "nanos" "nanosplus" "nanox" "stax")
message("Using target: " ${TARGET_DEVICE})

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

# CMake migration
set(CUSTOM_APP_FLAGS 0x000 CACHE STRING "Custom app flags")
option(NOT_REVIEWED "Not reviewed" ON)
set(ICON_NAME "" CACHE STRING "Icon name")
set(APP_WEBUSB_URL "" CACHE STRING "App WebUSB URL")
option(ENABLE_SDK_WERROR "Enable SDK Werror" OFF)

# Application configuration
set(APP_NAME Boilerplate)
set(APP_VERSION_MAJOR 2)
set(APP_VERSION_MINOR 1)
set(APP_VERSION_PATCH 0)
set(APP_VERSION "${APP_VERSION_MAJOR}.${APP_VERSION_MINOR}.${APP_VERSION_PATCH}")

# Applicationr graphical resources
file(GLOB ICONS ${CMAKE_CURRENT_SOURCE_DIR}/icons/*.gif)
file(GLOB APP_GLYPHS ${CMAKE_CURRENT_SOURCE_DIR}/glyphs/*.gif)

# Application allowed derivation curves and paths
set(CURVE_APP_LOAD_PARAMS secp256k1)
set(PATH_APP_LOAD_PARAMS 44'/1')

# Variant configuration (optional)
set(VARIANT_PARAM COIN)
set(VARIANT_VALUES 'BOL')

find_program(GREP grep REQUIRED)
find_program(FIND find REQUIRED)
find_program(OBJCOPY objcopy REQUIRED)
find_package(Git REQUIRED)
# CMake module handling more use cases like virtualenv
find_package(Python3 REQUIRED)

# SDK properties
# Define a function to extract a value based on a grep pattern from a header file
function(get_value_from_header header_file grep_pattern split_index target_var)
    # Run the grep command with the provided pattern and capture its output
    execute_process(
        COMMAND ${GREP} -E ${grep_pattern} ${header_file}
        OUTPUT_VARIABLE grep_output
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    string(STRIP "${grep_output}" stripped_output)
    string(REPLACE " " ";" split_output "${stripped_output}")
    list(GET split_output ${split_index} extracted_value)
    set(${target_var} "${extracted_value}" PARENT_SCOPE)
endfunction()

cmake_path(APPEND TARGET_PATH ${SDK} target ${TARGET_DEVICE} include)
cmake_path(APPEND BOLOS_TARGET_H ${TARGET_PATH} bolos_target.h)

set(API_LEVEL 21)
set(SDK_NAME ledger-secure-sdk)
get_value_from_header(${BOLOS_TARGET_H} "^\#define\\s*TARGET_ID" 2 TARGET_ID)
get_value_from_header(${BOLOS_TARGET_H} "^\#define\\s*TARGET_[^I]" 1 TARGET_NAME)
execute_process(
    COMMAND ${GIT_EXECUTABLE} -C ${SDK} describe --tags --exact-match --match v[0-9]* --dirty
    OUTPUT_VARIABLE SDK_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
execute_process(
    COMMAND ${GIT_EXECUTABLE} -C ${SDK} describe --always --dirty --exclude * --abbrev=40
    OUTPUT_VARIABLE SDK_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
if(SDK_VERSION STREQUAL "")
    set(SDK_VERSION "None")
endif()
if(SDK_HASH STREQUAL "")
    set(SDK_HASH "None")
endif()

#####################################################################
#                            BLUETOOTH                              #
#####################################################################
if(ENABLE_BLUETOOTH AND TARGET_DEVICE IN_LIST WITH_BLUETOOTH)
    set(HAVE_APPLICATION_FLAG_BOLOS_SETTINGS ON)
    set(DEFINES ${DEFINES} HAVE_BLE BLE_COMMAND_TIMEOUT_MS=2000 HAVE_BLE_APDU BLE_SEGMENT_SIZE=32 )
endif()

#####################################################################
#                               NFC                                 #
#####################################################################
if(ENABLE_NFC AND TARGET_DEVICE IN_LIST WITH_NFC)
    set(HAVE_APPLICATION_FLAG_BOLOS_SETTINGS ON)
    set(DEFINES ${DEFINES} HAVE_NFC)
endif()

#####################################################################
#                               SWAP                                #
#####################################################################
if(ENABLE_SWAP)
    set(HAVE_APPLICATION_FLAG_LIBRARY ON)
    set(DEFINES ${DEFINES} HAVE_SWAP)
endif()

#####################################################################
#                              APP STORAGE                          #
#####################################################################
if(ENABLE_APP_STORAGE)
    set(HAVE_APP_STORAGE ON)
    set(DEFINES ${DEFINES} HAVE_APP_STORAGE)
endif()

#####################################################################
#                               DEBUG                               #
#####################################################################
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(DEFINES ${DEFINES} HAVE_PRINTF)
    if(TARGET_DEVICE STREQUAL "nanos")
        set(DEFINES ${DEFINES} PRINTF=screen_printf)
    else()
        set(DEFINES ${DEFINES} PRINTF=mcu_usb_printf)
    endif()
    if(DISABLE_DEBUG_LEDGER_ASSERT)
        set(DEFINES ${DEFINES} HAVE_LEDGER_ASSERT_DISPLAY LEDGER_ASSERT_CONFIG_FILE_INFO)
    endif()
    if(DISABLE_DEBUG_THROW)
        set(DEFINES ${DEFINES} HAVE_DEBUG_THROWS)
    endif()
endif()

#####################################################################
#                        IO SEPROXY BUFFER SIZE                     #
#####################################################################
if(NOT DISABLE_DEFAULT_IO_SEPROXY_BUFFER_SIZE)
    if(TARGET_DEVICE STREQUAL "nanos")
        set(DEFINES ${DEFINES} IO_SEPROXYHAL_BUFFER_SIZE_B=128)
    else()
        set(DEFINES ${DEFINES} IO_SEPROXYHAL_BUFFER_SIZE_B=300)
    endif()
endif()

#####################################################################
#                              NBGL                                 #
#####################################################################
if (TARGET_DEVICE IN_LIST WITH_BAGL)
    set(USE_NBGL ${ENABLE_NBGL_FOR_NANO_DEVICES})
else()
    set(USE_NBGL ON)
endif()

if(ENABLE_NBGL_QRCODE AND TARGET_DEVICE IN_LIST WITH_TOUCHSCREEN)
    set(DEFINES ${DEFINES} NBGL_QRCODE)
endif()

if(ENABLE_NBGL_KEYBOARD)
    set(DEFINES ${DEFINES} NBGL_KEYBOARD)
endif()

if(ENABLE_NBGL_KEYPAD)
    set(DEFINES ${DEFINES} NBGL_KEYPAD)
endif()


#####################################################################
#                          STANDARD defines                         #
#####################################################################
# WARNING, removed support for DEFINES_LIB
# USE CFLAGS instead
set(DEFINES ${DEFINES} MAJOR_VERSION=${APP_VERSION_MAJOR} MINOR_VERSION=${APP_VERSION_MINOR} PATCH_VERSION=${APP_VERSION_PATCH} IO_HID_EP_LENGTH=64)

if(NOT DISABLE_STANDARD_APP_DEFINES)
    if(NOT DISABLE_STANDARD_SNPRINTF)
        set(DEFINES ${DEFINES} HAVE_SPRINTF HAVE_SNPRINTF_FORMAT_U)
    endif()
    if(NOT DISABLE_STANDARD_USB)
        set(DEFINES ${DEFINES} HAVE_IO_USB HAVE_L4_USBLIB IO_USB_MAX_ENDPOINTS=4 HAVE_USB_APDU USB_SEGMENT_SIZE=64)
    endif()
    if(NOT DISABLE_STANDARD_WEBUSB)
        string(LENGTH "${APP_WEBUSB_URL}" WEBUSB_URL_SIZE_B)
        # Convert the URL into a comma-separated list of characters
        string(REGEX REPLACE "." "'\\0'," WEBUSB_URL "${APP_WEBUSB_URL}")
        # Remove the trailing comma (if needed, for correct formatting)
        string(REGEX REPLACE ",$" "" WEBUSB_URL "${WEBUSB_URL}")
        # Add preprocessor definitions for the compiler
        set(DEFINES ${DEFINES} HAVE_WEBUSB WEBUSB_URL_SIZE_B=${WEBUSB_URL_SIZE_B} WEBUSB_URL=${WEBUSB_URL})
    endif()
    if(NOT DISABLE_STANDARD_BAGL_UX_FLOW AND USE_NBGL)
        set(DEFINES ${DEFINES} HAVE_UX_FLOW)
    endif()
    if(NOT DISABLE_STANDARD_SEPROXYHAL)
        set(DEFINES ${DEFINES} OS_IO_SEPROXYHAL)
    endif()
endif()

if(NOT DISABLE_STANDARD_APP_SYNC_RAPDU AND USE_NBGL)
    # On LNS only activate it by default if using NBGL.
    # This impact stack usage and shouldn't be activated on all apps silently
    set(DEFINES ${DEFINES} STANDARD_APP_SYNC_RAPDU)
endif()

#####################################################################
#                          APP_LOAD_PARAMS                          #
#####################################################################
set(STANDARD_APP_FLAGS 0x000)
if(ALLOW_DERIVE_MASTER)
    math(EXPR STANDARD_APP_FLAGS "${STANDARD_APP_FLAGS} + 0x010" OUTPUT_FORMAT HEXADECIMAL)
endif()
if(ALLOW_GLOBAL_PIN)
    math(EXPR STANDARD_APP_FLAGS "${STANDARD_APP_FLAGS} + 0x040" OUTPUT_FORMAT HEXADECIMAL)
endif()
if(ALLOW_BOLOS_SETTINGS)
    math(EXPR STANDARD_APP_FLAGS "${STANDARD_APP_FLAGS} + 0x200" OUTPUT_FORMAT HEXADECIMAL)
endif()
if(ALLOW_LIBRARY)
    math(EXPR STANDARD_APP_FLAGS "${STANDARD_APP_FLAGS} + 0x800" OUTPUT_FORMAT HEXADECIMAL)
endif()
if(NOT_REVIEWED)
    math(EXPR STANDARD_APP_FLAGS "${STANDARD_APP_FLAGS} + 0x20000" OUTPUT_FORMAT HEXADECIMAL)
endif()
math(EXPR APP_FLAGS_APP_LOAD_PARAMS "${CUSTOM_APP_FLAGS} + ${STANDARD_APP_FLAGS}" OUTPUT_FORMAT HEXADECIMAL)

#####################################################################
#                         COMPILER SETTINGS                         #
#####################################################################

#####################################################################
#                               MISC                                #
#####################################################################

#####################################################################
#                               GLYPHS                              #
#####################################################################
if(NOT USE_NBGL)
    message(FATAL_ERROR "bagl not supported yet")
endif()

set(GLYPH_PATHS ${CMAKE_CURRENT_SOURCE_DIR}/glyphs/*)
if (TARGET_DEVICE IN_LIST WITH_TOUCHSCREEN)
    set(GLYPH_PATHS ${GLYPH_PATHS} ${SDK}/lib_nbgl/glyphs/wallet/*)
    set(GLYPH_PATHS ${GLYPH_PATHS} ${SDK}/lib_nbgl/glyphs/64px/*)
    if(TARGET_DEVICE STREQUAL "flex")
        set(GLYPH_PATHS ${GLYPH_PATHS} ${SDK}/lib_nbgl/glyphs/40px/*)
    elseif(TARGET_DEVICE STREQUAL "stax")
        set(GLYPH_PATHS ${GLYPH_PATHS} ${SDK}/lib_nbgl/glyphs/32px/*)
    endif()
else()
   set(GLYPH_PATHS ${GLYPH_PATHS} ${SDK}/lib_nbgl/glyphs/nano/*)
   set(GLYPH_OPT --reverse)
endif()
file(GLOB_RECURSE GLYPH_FILES ${GLYPH_PATHS})

#####################################################################
#                               MAKEFILE.defines                    #
#####################################################################
# TODO TARGET_NAME is wrong here
set(DEFINES ${DEFINES} API_LEVEL="${API_LEVEL}" APPNAME="${APP_NAME}" APPVERSION="${APP_VERSION}" SDK_HASH="${SDK_HASH}" SDK_NAME="${SDK_NAME}" SDK_VERSION="${SDK_VERSION}" TARGET="${TARGET_DEVICE}" TARGET_NAME="${TARGET_DEVICE}" __IO=volatile gcc NDEBUG)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} -Og -g1)
    set(LEDGER_ASM_FLAGS ${LEDGER_ASM_FLAGS} -Og -g1)
else()
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} -Oz -g0)
    set(LEDGER_ASM_FLAGS ${LEDGER_ASM_FLAGS} -Oz -g0)
endif()

set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} -Wall -Werror=int-to-pointer-cast -Wextra -Wextra -Wformat-security -Wformat-security -Wformat=2 -Wimplicit-fallthrough -Wno-error=int-conversion -Wno-main -Wshadow -Wundef -Wvla -Wwrite-strings -fdata-sections -ffunction-sections -fno-common -fno-jump-tables -fomit-frame-pointer -fropi -fshort-enums -funsigned-char -mlittle-endian -mno-unaligned-access -momit-leaf-frame-pointer)

if(ENABLE_SDK_WERROR)
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} -Werror)
endif()

set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -Wall -Wl,--gc-sections -fdata-sections -ffunction-sections -fno-common -fomit-frame-pointer -fwhole-program -mno-unaligned-access)

if(TARGET_DEVICE STREQUAL nanos)
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} --target=armv6m-none-eabi -mcpu=cortex-m0plus -frwpi -mthumb)
    set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -mcpu=cortex-m0plus -mthumb -nostartfiles --specs=nano.specs)
endif()

if(TARGET_DEVICE STREQUAL nanox)
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} --target=armv6m-none-eabi -frwpi -mthumb)
    set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} --target=armv6m-none-eabi -mcpu=cortex-m0plus -mlittle-endian -mno-movt -momit-leaf-frame-pointer -mthumb -mtune=cortex-m0plus -nodefaultlibs -nostdlib)
endif()

if(TARGET_DEVICE IN_LIST WITH_ARMV8)
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} ${TARGET_C_FLAGS})
    set(LEDGER_ASM_FLAGS ${LEDGER_ASM_FLAGS} ${TARGET_ASM_FLAGS})
    set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} ${TARGET_LD_FLAGS})
endif()

if(TARGET_DEVICE STREQUAL stax)
    set(DEFINES ${DEFINES} HAVE_BAGL_FONT_INTER_MEDIUM_32PX HAVE_BAGL_FONT_INTER_REGULAR_24PX HAVE_BAGL_FONT_INTER_SEMIBOLD_24PX HAVE_INAPP_BLE_PAIRING HAVE_NBGL HAVE_PIEZO_SOUND HAVE_SE_EINK_DISPLAY HAVE_SE_TOUCH NBGL_PAGE NBGL_USE_CASE SCREEN_SIZE_WALLET)
endif()

if(TARGET_DEVICE STREQUAL flex)
    set(DEFINES ${DEFINES} HAVE_BAGL_FONT_INTER_MEDIUM_36PX HAVE_BAGL_FONT_INTER_REGULAR_28PX HAVE_BAGL_FONT_INTER_SEMIBOLD_28PX HAVE_FAST_HOLD_TO_APPROVE HAVE_INAPP_BLE_PAIRING HAVE_NBGL HAVE_PIEZO_SOUND HAVE_SE_EINK_DISPLAY HAVE_SE_TOUCH NBGL_PAGE NBGL_USE_CASE SCREEN_SIZE_WALLET)
endif()

if(TARGET_DEVICE IN_LIST WITH_BAGL)
    set(DEFINES ${DEFINES} -DBAGL_HEIGHT=64 -DBAGL_WIDTH=128 -DHAVE_BAGL_ELLIPSIS -DHAVE_BAGL_FONT_OPEN_SANS_EXTRABOLD_11PX -DHAVE_BAGL_FONT_OPEN_SANS_LIGHT_16PX -DHAVE_BAGL_FONT_OPEN_SANS_REGULAR_11PX -DSCREEN_SIZE_NANO)
    if(USE_NBGL)
        set(DEFINES ${DEFINES} HAVE_NBGL NBGL_STEP NBGL_USE_CASE)
    else()
        set(DEFINES ${DEFINES} HAVE_BAGL HAVE_UX_FLOW)
    endif()
endif()

if(TARGET_DEVICE STREQUAL nanos)
    set(DEFINES ${DEFINES} BAGL_HEIGHT=32 BAGL_WIDTH=128 HAVE_BAGL SCREEN_SIZE_NANO)
endif()

set(WITH_SE_SCREEN nanox nanosp)
if(TARGET_DEVICE IN_LIST WITH_SE_SCREEN)
    set(DEFINES ${DEFINES} HAVE_SE_SCREEN HAVE_SE_BUTTON HAVE_BATTERY HAVE_BATTERY HAVE_FONTS HAVE_INAPP_BLE_PAIRING HAVE_MCU_SERIAL_STORAGE)
endif()

# Enable the use of ledger-pki bolos' syscalls
set(DEFINES ${DEFINES} HAVE_LEDGER_PKI)

set(GEN_GLYPHS_CMD "${SDK}/lib_nbgl/tools/icon2glyph.py")
set(GEN_GLYPHS_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated)
add_custom_target(
    genglyphs
    COMMAND mkdir -p  ${GEN_GLYPHS_DIR}
    COMMAND ${Python3_EXECUTABLE} ${GEN_GLYPHS_CMD} ${GLYPH_OPT} --glyphcheader ${GEN_GLYPHS_DIR}/glyphs.h --glyphcfile ${GEN_GLYPHS_DIR}/glyphs.c ${GLYPH_FILES}
    BYPRODUCTS ${GEN_GLYPHS_DIR}/glyphs.h ${GEN_GLYPHS_DIR}/glyphs.c
    SOURCES ${GLYPH_FILES}
)
add_library(glyphs INTERFACE)
target_include_directories(glyphs INTERFACE ${GEN_GLYPHS_DIR})
add_dependencies(glyphs genglyphs)

set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -L${SDK}/target/${TARGET_DEVICE})
if(IS_PLUGIN)
    set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -T${SDK}/target/${TARGET_DEVICE}/plugin_script.ld)
else()
    set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -T${SDK}/target/${TARGET_DEVICE}/script.ld)
endif()

add_library(osinterface INTERFACE)
target_include_directories(osinterface INTERFACE ${SDK}/include ${TARGET_PATH})

file(GLOB_RECURSE BAGL_SOURCES ${SDK}/lib_bagl/*.c)
add_library(bagl STATIC ${BAGL_SOURCES})
target_link_libraries(bagl PUBLIC osinterface)
target_include_directories(bagl PUBLIC ${SDK}/lib_bagl/include)
target_compile_options(bagl PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(bagl PRIVATE ${DEFINES})

add_library(printf STATIC ${SDK}/src/os_printf.c)
target_link_libraries(printf PUBLIC osinterface)
target_compile_options(printf PRIVATE ${LEDGER_C_FLAGS})
message("PRINTF defines: ${DEFINES}")
target_compile_definitions(printf PRIVATE ${DEFINES})

add_library(cxnginterface INTERFACE)
target_include_directories(cxnginterface INTERFACE ${SDK}/lib_cxng/include)

file(GLOB_RECURSE CXNG_SOURCES ${SDK}/lib_cxng/*.c)
add_library(cxng STATIC ${CXNG_SOURCES})
target_link_libraries(cxng PUBLIC osinterface cxnginterface)
target_compile_options(cxng PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(cxng PRIVATE ${DEFINES})

file(GLOB_RECURSE BLEWBXX_SOURCES ${SDK}/lib_blewbxx/*.c ${SDK}/lib_blewbxx_impl/*.c)
add_library(blewbxx STATIC ${BLEWBXX_SOURCES})
target_include_directories(blewbxx PUBLIC ${SDK}/lib_blewbxx/core ${SDK}/lib_blewbxx/core/auto ${SDK}/lib_blewbxx/core/template ${SDK}/lib_blewbxx_impl/include)
target_link_libraries(blewbxx PUBLIC osinterface cxnginterface)
target_compile_options(blewbxx PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(blewbxx PRIVATE ${DEFINES})

file(GLOB_RECURSE NBGL_SOURCES ${SDK}/lib_nbgl/src/*.c ${SDK}/lib_ux_nbgl/*.c)
add_library(nbgl STATIC ${NBGL_SOURCES})
target_include_directories(nbgl PUBLIC ${SDK}/lib_nbgl/include ${SDK}/lib_ux_nbgl ${SDK}/lib_ux_nbgl/include)
target_link_libraries(nbgl PUBLIC osinterface glyphs cxnginterface)
target_compile_options(nbgl PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(nbgl PRIVATE ${DEFINES})

file(GLOB_RECURSE STUSB_SOURCES ${SDK}/lib_stusb/*.c ${SDK}/lib_stusb_impl/*.c)
add_library(stusb STATIC ${STUSB_SOURCES})
target_include_directories(stusb PUBLIC ${SDK}/lib_stusb ${SDK}/lib_stusb_impl ${SDK}/lib_stusb/STM32_USB_Device_Library/Core/Inc ${SDK}/lib_stusb/STM32_USB_Device_Library/Class/CCID/inc ${SDK}/lib_stusb/STM32_USB_Device_Library/Class/HID/Inc)
target_link_libraries(stusb PUBLIC osinterface cxnginterface)
target_compile_options(stusb PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(stusb PRIVATE ${DEFINES})

file(GLOB_RECURSE STANDARD_SOURCES ${SDK}/lib_standard_app/*.c)
add_library(standard STATIC ${STANDARD_SOURCES})
target_link_libraries(standard PUBLIC osinterface cxnginterface nbgl)
target_include_directories(standard PUBLIC ${SDK}/lib_standard_app)
target_compile_options(standard PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(standard PRIVATE ${DEFINES})

file(GLOB_RECURSE OS_SOURCES ${SDK}/src/*.c)
add_library(os OBJECT ${OS_SOURCES})
target_include_directories(os PUBLIC ${SDK})
target_link_libraries(os PUBLIC osinterface cxnginterface nbgl stusb blewbxx)
target_compile_options(os PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(os PRIVATE ${DEFINES})

file(GLOB_RECURSE STUB_SOURCES ${SDK}/src/*.S ${SDK}/src/*.s)
add_library(stub STATIC ${STUB_SOURCES})
target_link_libraries(stub PRIVATE osinterface)
target_compile_options(stub PRIVATE ${LEDGER_ASM_FLAGS})

file(GLOB_RECURSE APP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)
add_executable(app ${APP_SOURCES} ${GEN_GLYPHS_DIR}/glyphs.c)
target_include_directories(app PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_directories(app PRIVATE ${ST_NEWLIB_PATH})
target_link_libraries(app PRIVATE glyphs printf os standard stub nbgl gcc c)
target_link_options(app PUBLIC ${LEDGER_LD_FLAGS})
target_compile_options(app PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(app PRIVATE ${DEFINES})
