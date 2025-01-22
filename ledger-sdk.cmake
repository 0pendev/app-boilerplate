set(CMAKE_C_STANDARD 99)

# Loading BOLOS_SDK paths and definitions
set(SDK "" CACHE STRING "Path to the ledger-secure-sdk")

if(NOT API_TAG STREQUAL "") 
    include(FetchContent)
    FetchContent_Declare(
        ledgersecuresdk
        GIT_REPOSITORY https://github.com/LedgerHQ/ledger-secure-sdk
        GIT_TAG        ${API_TAG}
    )
    FetchContent_MakeAvailable(ledgersecuresdk)
    FetchContent_GetProperties(ledgersecuresdk SOURCE_DIR SDK)
    message("Content: ${SDK}")
endif() 

if(SDK STREQUAL "")
message(FATAL_ERROR "SDK variable is required to build the app")
endif()
message("Using sdk path: " ${SDK})
message("Using git path: " ${API_TAG})
message("Using target: " ${TARGET_DEVICE})

# List used to query target features
set(WITH_TOUCHSCREEN flex stax)
set(WITH_BLUETOOTH flex nanox stax)
set(WITH_NFC flex stax)
set(WITH_BAGL nanos nanosplus nanox)
set(WITH_ARMV8 flex nanosplus stax)

# Program used during the build process
find_program(GREP_EXECUTABLE grep REQUIRED)
find_program(CAT_EXECUTABLE cat REQUIRED)
find_program(MKDIR_EXECUTABLE mkdir REQUIRED)
find_program(OBJCOPY_EXECUTABLE objcopy REQUIRED)
find_package(Git REQUIRED)
# CMake module handling more use cases like virtualenv
find_package(Python3 REQUIRED)

# SDK properties
# Define a function to extract a value based on a grep pattern from a header file
function(get_value_from_header header_file grep_pattern split_index target_var)
    # Run the grep command with the provided pattern and capture its output
    execute_process(
        COMMAND ${GREP_EXECUTABLE} -E ${grep_pattern} ${header_file}
        OUTPUT_VARIABLE grep_output
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    string(STRIP "${grep_output}" stripped_output)
    string(REPLACE " " ";" split_output "${stripped_output}")
    list(GET split_output ${split_index} extracted_value)
    set(${target_var} "${extracted_value}" PARENT_SCOPE)
endfunction()

cmake_path(APPEND TARGET_PATH ${SDK} target ${TARGET_SDKNAME} include)
cmake_path(APPEND BOLOS_TARGET_H ${TARGET_PATH} bolos_target.h)

get_value_from_header(${BOLOS_TARGET_H} "^\#define\\s*TARGET_ID" 2 TARGET_ID)
get_value_from_header(${BOLOS_TARGET_H} "^\#define\\s*TARGET_[^I]" 1 TARGET_NAME)
set(TARGET_VERSION "")
execute_process(
    COMMAND ${GIT_EXECUTABLE} -C ${SDK} describe --tags --exact-match --match v[0-9]* --dirty
    OUTPUT_VARIABLE SDK_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
    COMMAND ${GIT_EXECUTABLE} -C ${SDK} describe --always --dirty --exclude * --abbrev=40
    OUTPUT_VARIABLE SDK_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
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
#                               GLYPHS                              #
#####################################################################
if(NOT USE_NBGL)
    set(GLYPH_PATHS ${CMAKE_CURRENT_SOURCE_DIR}/glyphs/* ${SDK}/lib_ux/glyphs/*)
else()
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
endif()
file(GLOB_RECURSE GLYPH_FILES ${GLYPH_PATHS})

#####################################################################
#                               MAKEFILE.defines                    #
#####################################################################
set(DEFINES ${DEFINES} API_LEVEL=${API_LEVEL} APPNAME="${APP_NAME}" APPVERSION="${APP_VERSION}" SDK_HASH="${SDK_HASH}" SDK_NAME="${SDK_NAME}" SDK_VERSION="${SDK_VERSION}" TARGET="${TARGET_DEVICE}" TARGET_NAME="${TARGET_DEVICE}" __IO=volatile gcc NDEBUG)

if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR ENABLE_FUZZ)
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} -Og -g3)
    set(LEDGER_ASM_FLAGS ${LEDGER_ASM_FLAGS} -Og -g3)
else()
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} -Oz -g0)
    set(LEDGER_ASM_FLAGS ${LEDGER_ASM_FLAGS} -Oz -g0)
endif()

set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} -Wall -Werror=int-to-pointer-cast -Wextra -Wextra -Wformat-security -Wformat-security -Wformat=2 -Wimplicit-fallthrough -Wno-error=int-conversion -Wno-main -Wshadow -Wundef -Wvla -Wwrite-strings -fdata-sections -ffunction-sections -fno-common -fno-jump-tables -fomit-frame-pointer -fshort-enums -funsigned-char -mlittle-endian -momit-leaf-frame-pointer)

if(ENABLE_SDK_WERROR)
    set(LEDGER_C_FLAGS ${LEDGER_C_FLAGS} -Werror)
endif()

set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -Wall LINKER:--gc-sections -fdata-sections -ffunction-sections -fno-common -fomit-frame-pointer -fwhole-program -mno-unaligned-access)

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

set(WITH_SE_SCREEN nanox nanosplus)
if(TARGET_DEVICE IN_LIST WITH_SE_SCREEN)
    set(DEFINES ${DEFINES} HAVE_SE_SCREEN HAVE_SE_BUTTON HAVE_BATTERY HAVE_BATTERY HAVE_FONTS HAVE_INAPP_BLE_PAIRING HAVE_MCU_SERIAL_STORAGE)
endif()

#########
# There is no need to check for NANOS as it is not supported anymore
#########

set(ICON_HEX_FILE ${CMAKE_CURRENT_BINARY_DIR}/icon.hex)
if(TARGET_DEVICE IN_LIST WITH_TOUCHSCREEN)
    execute_process(COMMAND ${Python3_EXECUTABLE} ${SDK}/lib_nbgl/tools/icon2glyph.py --hexbitmap ${ICON_HEX_FILE} ${ICON_NAME})
else()
    execute_process(COMMAND ${Python3_EXECUTABLE} ${SDK}/lib_nbgl/tools/icon2glyph.py --reverse --hexbitmap ${ICON_HEX_FILE} ${ICON_NAME})
endif()
execute_process(
    COMMAND ${CAT_EXECUTABLE} ${ICON_HEX_FILE}
    OUTPUT_VARIABLE ICON_HEX
)

#########################################
#         Parse APP_LOAD_PARAMS         #
#########################################
# This is necessary when makefile.standard_app is not completely used.
# Correctly implemented apps should not set anything in APP_LOAD_PARAMS anymore
# Potential presents info are:
# --appFlags
# --curve
# --path
# --path_slip21
# --tlvraw
# --dep
# --nocrc
# Other info are considered an error and will be silently discarded.
if(DEFINED APP_LOAD_PARAMS)
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${SDK}/extract_param.py --appFlags ${APP_LOAD_PARAMS}
        OUTPUT_VARIABLE EXTRACTED_APP_FLAGS
    )
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${SDK}/extract_param.py --curve ${APP_LOAD_PARAMS}
        OUTPUT_VARIABLE EXTRACTED_CURVE
    )
    set(CURVE_APP_LOAD_PARAMS ${CURVE_APP_LOAD_PARAMS} ${EXTRACTED_CURVE})
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${SDK}/extract_param.py --path ${APP_LOAD_PARAMS}
        OUTPUT_VARIABLE EXTRACTED_PATH
    )
    set(PATH_APP_LOAD_PARAMS ${PATH_APP_LOAD_PARAMS} ${EXTRACTED_PATH})
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${SDK}/extract_param.py --path_slip21 ${APP_LOAD_PARAMS}
        OUTPUT_VARIABLE EXTRACTED_PATH_SLIP21
    )
	set(PATH_SLIP21_APP_LOAD_PARAMS ${PATH_SLIP21_APP_LOAD_PARAMS} ${EXTRACTED_PATH_SLIP21})
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${SDK}/extract_param.py --tlvraw ${APP_LOAD_PARAMS}
        OUTPUT_VARIABLE EXTRACTED_TLVRAW
    )
	set(TLVRAW_APP_LOAD_PARAMS ${TLVRAW_APP_LOAD_PARAMS} ${EXTRACTED_TLVRAW})
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${SDK}/extract_param.py --dep ${APP_LOAD_PARAMS}
        OUTPUT_VARIABLE EXTRACTED_DEP
    )
	set(DEP_APP_LOAD_PARAMS ${DEP_APP_LOAD_PARAMS} ${EXTRACTED_DEP})

    string(FIND "${APP_LOAD_PARAMS}" "--nocrc" INDEX_PARAM_NOCRC)
    if(INDEX_PARAM_NOCRC GREATER -1)
        set(ENABLE_NOCRC_APP_LOAD_PARAMS On)
    endif()
endif()

set(APP_INSTALL_PARAMS ${APP_INSTALL_PARAMS}
    --appName ${APP_NAME}
    --appVersion ${APP_VERSION}
    --icon ${ICON_HEX}
)

foreach(CURVE IN LISTS CURVE_APP_LOAD_PARAMS)
    set(APP_INSTALL_PARAMS ${APP_INSTALL_PARAMS} --curve ${CURVE})
endforeach()
foreach(PATH IN LISTS PATH_APP_LOAD_PARAMS)
    set(APP_INSTALL_PARAMS ${APP_INSTALL_PARAMS} --path ${PATH})
endforeach()

#TOOD TEST PARAMETER
if(DEFINED PATH_SLIP21_APP_LOAD_PARAMS)
    set(APP_INSTALL_PARAMS ${APP_INSTALL_PARAMS} --path_slip21 ${PATH_SLIP21_APP_LOAD_PARAMS})
endif()

foreach(TLVRAW IN LISTS TLVRAW_APP_LOAD_PARAMS)
    set(APP_INSTALL_PARAMS ${APP_INSTALL_PARAMS} --tlvraw ${TLVRAW})
endforeach()
foreach(DEP IN LISTS DEP_APP_LOAD_PARAMS)
    set(APP_INSTALL_PARAMS ${APP_INSTALL_PARAMS} --dep ${DEP})
endforeach()

# Compute install_params tlv binary blob then expose it via a define to
# src/app_metadata.c so that it is inserted in the binary at link time
execute_process(
    COMMAND ${Python3_EXECUTABLE} ${SDK}/install_params.py ${APP_INSTALL_PARAMS}
    OUTPUT_VARIABLE APP_INSTALL_PARAMS_DATA
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(DEFINES ${DEFINES} APP_INSTALL_PARAMS_DATA=${APP_INSTALL_PARAMS_DATA})

#########################################
#        Generate APP_LOAD_PARAMS       #
#########################################
# Rewrite APP_LOAD_PARAMS with params needed for generating the sideloading
# APDUs.
# This variable is then used in some Makefiles target as Ledgerblue.loadapp
# script parameters.
set(APP_LOAD_PARAMS
    --targetId ${TARGET_ID}
    --targetVersion=${TARGET_VERSION}
    --apiLevel ${API_LEVEL}
    --fileName ${CMAKE_CURRENT_BINARY_DIR}/app.hex
    --appName ${APP_NAME}
    --delete
    --tlv
)

if(DEFINED APP_FLAGS_APP_LOAD_PARAMS)
	set(APP_LOAD_PARAMS ${APP_LOAD_PARAMS} --appFlags ${APP_FLAGS_APP_LOAD_PARAMS})
endif()

# Define the debug directory and map file
set(DEBUG_DIR "${CMAKE_CURRENT_BINARY_DIR}/debug")

if(ENABLE_NOCRC_APP_LOAD_PARAMS)
    set(APP_LOAD_PARAMS ${APP_LOAD_PARAMS} --nocrc)
endif()

set(COMMON_DELETE_PARAMS --targetId ${TARGET_ID} --appName ${APPNAME})
# Extra load parameters for loadApp script
if(DEFINED SCP_PRIVKEY)
	set(PARAM_SCP ${PARAM_SCP} --rootPrivateKey ${SCP_PRIVKEY})
	set(APP_LOAD_PARAMS ${APP_LOAD_PARAMS} ${PARAM_SCP})
	set(COMMON_DELETE_PARAMS ${COMMON_DELETE_PARAMS} ${PARAM_SCP})
endif()

#########
# GLYPHS
#########

# Enable the use of ledger-pki bolos' syscalls
set(DEFINES ${DEFINES} HAVE_LEDGER_PKI)

set(GEN_GLYPHS_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated)
if(USE_NBGL)
    set(GEN_GLYPHS_CMD "${SDK}/lib_nbgl/tools/icon2glyph.py")
    add_custom_target(
        genglyphs
        COMMAND ${MKDIR_EXECUTABLE} -p  ${GEN_GLYPHS_DIR}
        COMMAND ${Python3_EXECUTABLE} ${GEN_GLYPHS_CMD} ${GLYPH_OPT} --glyphcheader ${GEN_GLYPHS_DIR}/glyphs.h --glyphcfile ${GEN_GLYPHS_DIR}/glyphs.c ${GLYPH_FILES}
        BYPRODUCTS ${GEN_GLYPHS_DIR}/glyphs.h ${GEN_GLYPHS_DIR}/glyphs.c
        SOURCES ${GLYPH_FILES}
    )
else()
    add_custom_target(
        genglyphs
        COMMAND ${MKDIR_EXECUTABLE} -p  ${GEN_GLYPHS_DIR}
        COMMAND cd ${GEN_GLYPHS_DIR}
        COMMAND ${Python3_EXECUTABLE} ${SDK}/icon3.py --factorize --glyphcheader ${GLYPH_FILES} > ${GEN_GLYPHS_DIR}/glyphs.h
        COMMAND ${Python3_EXECUTABLE} ${SDK}/icon3.py --factorize --glyphcfile ${GLYPH_FILES} > ${GEN_GLYPHS_DIR}/glyphs.c
        BYPRODUCTS ${GEN_GLYPHS_DIR}/glyphs.h ${GEN_GLYPHS_DIR}/glyphs.c
        SOURCES ${GLYPH_FILES}
    )
endif()

if(NOT ENABLE_FUZZ)
    set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -L${SDK}/target/${TARGET_SDKNAME})
    if(IS_PLUGIN)
        set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -T${SDK}/target/${TARGET_SDKNAME}/plugin_script.ld)
    else()
        set(LEDGER_LD_FLAGS ${LEDGER_LD_FLAGS} -T${SDK}/target/${TARGET_SDKNAME}/script.ld)
    endif()
endif()

add_library(miscinterface INTERFACE)
target_include_directories(miscinterface INTERFACE ${SDK}/include ${TARGET_PATH})

add_library(extrafeatures INTERFACE)

add_library(printf STATIC EXCLUDE_FROM_ALL ${SDK}/src/os_printf.c)
target_link_libraries(printf PUBLIC miscinterface)
target_compile_options(printf PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(printf PRIVATE ${DEFINES})

add_library(cxnginterface INTERFACE)
target_include_directories(cxnginterface INTERFACE ${SDK}/lib_cxng/include)

file(GLOB_RECURSE CXNG_SOURCES ${SDK}/lib_cxng/*.c)
add_library(cxng STATIC EXCLUDE_FROM_ALL ${CXNG_SOURCES})
target_link_libraries(cxng PUBLIC miscinterface cxnginterface)
target_compile_options(cxng PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(cxng PRIVATE ${DEFINES})

file(GLOB_RECURSE BLEWBXX_SOURCES ${SDK}/lib_blewbxx/*.c ${SDK}/lib_blewbxx_impl/*.c)
add_library(blewbxx STATIC EXCLUDE_FROM_ALL ${BLEWBXX_SOURCES})
target_include_directories(blewbxx PUBLIC ${SDK}/lib_blewbxx/core ${SDK}/lib_blewbxx/core/auto ${SDK}/lib_blewbxx/core/template ${SDK}/lib_blewbxx_impl/include)
target_link_libraries(blewbxx PUBLIC miscinterface cxnginterface)
target_compile_options(blewbxx PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(blewbxx PRIVATE ${DEFINES})
if(ENABLE_BLUETOOTH AND TARGET_DEVICE IN_LIST WITH_BLUETOOTH)
    target_link_libraries(extrafeatures INTERFACE blewbxx)
endif()

if(USE_NBGL)
    add_library(nbglinterface INTERFACE)
    target_include_directories(nbglinterface INTERFACE ${SDK}/lib_nbgl/include ${SDK}/lib_ux_nbgl ${SDK}/lib_ux_nbgl/include)

    add_library(glyphs STATIC EXCLUDE_FROM_ALL ${GEN_GLYPHS_DIR}/glyphs.c)
    target_include_directories(glyphs INTERFACE ${GEN_GLYPHS_DIR})
    target_link_libraries(glyphs PUBLIC miscinterface nbglinterface)
    add_dependencies(glyphs genglyphs)
    target_compile_options(glyphs PRIVATE ${LEDGER_C_FLAGS})
    target_compile_definitions(glyphs PRIVATE ${DEFINES})

    file(GLOB_RECURSE NBGL_SOURCES ${SDK}/lib_nbgl/src/*.c ${SDK}/lib_ux_nbgl/*.c)
    add_library(nbgl STATIC EXCLUDE_FROM_ALL ${NBGL_SOURCES})
    target_link_libraries(nbgl PUBLIC nbglinterface miscinterface glyphs cxnginterface)
    target_compile_options(nbgl PRIVATE ${LEDGER_C_FLAGS})
    target_compile_definitions(nbgl PRIVATE ${DEFINES})

    if(ENABLE_FUZZ)
        target_link_libraries(nbglinterface INTERFACE glyphs)
        add_library(graphics ALIAS nbglinterface)
    else()    
        add_library(graphics ALIAS nbgl)
    endif()
else()
    file(GLOB_RECURSE BAGL_SOURCES ${SDK}/lib_bagl/*.c)
    add_library(bagl STATIC EXCLUDE_FROM_ALL ${BAGL_SOURCES})
    target_link_libraries(bagl PUBLIC miscinterface cxnginterface ux)
    target_include_directories(bagl PUBLIC ${SDK}/lib_bagl/include)
    target_compile_options(bagl PRIVATE ${LEDGER_C_FLAGS})
    target_compile_definitions(bagl PRIVATE ${DEFINES})

    add_library(glyphs STATIC EXCLUDE_FROM_ALL ${GEN_GLYPHS_DIR}/glyphs.c)
    target_include_directories(glyphs INTERFACE ${GEN_GLYPHS_DIR})
    target_link_libraries(glyphs PUBLIC miscinterface bagl)
    add_dependencies(glyphs genglyphs)
    target_compile_options(glyphs PRIVATE ${LEDGER_C_FLAGS})
    target_compile_definitions(glyphs PRIVATE ${DEFINES})

    file(GLOB_RECURSE UX_SOURCES ${SDK}/lib_ux/*.c)
    add_library(ux STATIC EXCLUDE_FROM_ALL ${UX_SOURCES})
    target_link_libraries(ux PUBLIC glyphs)
    target_include_directories(ux PUBLIC ${SDK}/lib_ux/include)
    target_compile_options(ux PRIVATE ${LEDGER_C_FLAGS})
    target_compile_definitions(ux PRIVATE ${DEFINES})
    add_library(graphics ALIAS ux)
endif()

file(GLOB_RECURSE STUSB_SOURCES ${SDK}/lib_stusb/*.c ${SDK}/lib_stusb_impl/*.c)
add_library(stusb STATIC EXCLUDE_FROM_ALL ${STUSB_SOURCES})
target_include_directories(stusb PUBLIC ${SDK}/lib_stusb ${SDK}/lib_stusb_impl ${SDK}/lib_stusb/STM32_USB_Device_Library/Core/Inc ${SDK}/lib_stusb/STM32_USB_Device_Library/Class/CCID/inc ${SDK}/lib_stusb/STM32_USB_Device_Library/Class/HID/Inc)
target_link_libraries(stusb PUBLIC miscinterface cxnginterface)
target_compile_options(stusb PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(stusb PRIVATE ${DEFINES})

file(GLOB_RECURSE STANDARD_SOURCES ${SDK}/lib_standard_app/*.c)
if (ENABLE_FUZZ)
    list(FILTER STANDARD_SOURCES EXCLUDE REGEX ".*main\\.c$")
    message("${STANDARD_SOURCES}")
endif()
add_library(standard STATIC EXCLUDE_FROM_ALL ${STANDARD_SOURCES})
target_link_libraries(standard PUBLIC miscinterface cxnginterface graphics)
target_include_directories(standard PUBLIC ${SDK}/lib_standard_app)
target_compile_options(standard PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(standard PRIVATE ${DEFINES})

file(GLOB_RECURSE MISC_SOURCES ${SDK}/src/*.c)
add_library(misc OBJECT EXCLUDE_FROM_ALL ${MISC_SOURCES})
target_include_directories(misc PUBLIC ${SDK})
target_link_libraries(misc PUBLIC miscinterface cxnginterface graphics stusb extrafeatures)
target_compile_options(misc PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(misc PRIVATE ${DEFINES})

file(GLOB_RECURSE STUB_SOURCES ${SDK}/src/*.S ${SDK}/src/*.s)
add_library(stub STATIC EXCLUDE_FROM_ALL ${STUB_SOURCES})
target_link_libraries(stub PRIVATE miscinterface)
target_compile_options(stub PRIVATE ${LEDGER_ASM_FLAGS})

if(ENBALE_FUZZ)
    return()
endif()

# LibC needed for the build of the app
set(ST_NEWLIB_PATH ${SDK}/arch/st33k1/lib CACHE INTERNAL "Newlib needed for the device we target")
# Map File used to generate the APDUs
set(MAP_FILE "${CMAKE_CURRENT_BINARY_DIR}/app.map")
add_executable(app.elf ${APP_SOURCES})
target_include_directories(app.elf PRIVATE ${APP_INCLUDE_DIR})
target_link_directories(app.elf PRIVATE ${ST_NEWLIB_PATH})
target_link_libraries(app.elf PRIVATE glyphs printf misc standard stub graphics m gcc c)
target_link_options(app.elf PUBLIC ${LEDGER_LD_FLAGS} LINKER:-Map=${MAP_FILE})
target_compile_options(app.elf PRIVATE ${LEDGER_C_FLAGS})
target_compile_definitions(app.elf PRIVATE ${DEFINES})

add_custom_target(
    hex
    COMMAND ${OBJCOPY_EXECUTABLE} -O ihex -S $<TARGET_FILE:app.elf> ${CMAKE_CURRENT_BINARY_DIR}/app.hex
    BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/app.hex
    DEPENDS app.elf
)

add_custom_target(
    apdu
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/ledgerblue_wrapper.py ${MAP_FILE} ${APP_LOAD_PARAMS} --offline ${CMAKE_CURRENT_BINARY_DIR}/app.apdu
    BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/app.apdu ${CMAKE_CURRENT_BINARY_DIR}/app.sha256
    DEPENDS hex
)

add_custom_target(
    load
    EXCLUDE_FROM_ALL
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/ledgerblue_wrapper.py ${APP_LOAD_PARAMS}
    DEPENDS app.apdu
)