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
file(GLOB_RECURSE APP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c)
set(APP_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)

include(options.cmake)
include(ledger-sdk.cmake)
add_subdirectory(fuzzing)