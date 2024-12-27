cmake_minimum_required(VERSION 3.11)

project(Boilerplate C ASM)

# Application configuration
set(APP_NAME Boilerplate)
set(APP_VERSION_MAJOR 2)
set(APP_VERSION_MINOR 1)
set(APP_VERSION_PATCH 0)
set(APP_VERSION "${APP_VERSION_MAJOR}.${APP_VERSION_MINOR}.${APP_VERSION_PATCH}")

# Application graphical resources
file(GLOB ICONS ${CMAKE_CURRENT_SOURCE_DIR}/icons/*.gif)
file(GLOB APP_GLYPHS ${CMAKE_CURRENT_SOURCE_DIR}/glyphs/*.gif)

# Application allowed derivation curves and paths
set(CURVE_APP_LOAD_PARAMS secp256k1)
set(PATH_APP_LOAD_PARAMS 44'/1')

# Variant configuration (optional)
set(VARIANT_PARAM COIN)
set(VARIANT_VALUES 'BOL')

set(ICON_nanox ${CMAKE_CURRENT_SOURCE_DIR}/icons/app_boilerplate_14px.gif)
set(ICON_nanosplus ${CMAKE_CURRENT_SOURCE_DIR}/icons/app_boilerplate_14px.gif)
set(ICON_stax ${CMAKE_CURRENT_SOURCE_DIR}/icons/app_boilerplate_32px.gif)
set(ICON_flex ${CMAKE_CURRENT_SOURCE_DIR}/icons/app_boilerplate_40px.gif)
set(ICON_NAME ${ICON_${TARGET_DEVICE}})

include(options.cmake)
include(ledger-sdk.cmake)

set(MAP_FILE "${CMAKE_CURRENT_BINARY_DIR}/app.map")
file(GLOB_RECURSE APP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)
add_executable(app.elf ${APP_SOURCES})
target_include_directories(app.elf PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_directories(app.elf PRIVATE ${ST_NEWLIB_PATH})
target_link_libraries(app.elf PRIVATE glyphs printf misc standard stub graphics gcc c)
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