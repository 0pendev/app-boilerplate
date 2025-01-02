if(NOT ENABLE_FUZZ)
  return()
endif()

if (NOT CMAKE_C_COMPILER_ID MATCHES "Clang")
  message(FATAL_ERROR "Fuzzer needs to be built with Clang")
endif()

message("FLAGS: ${LEDGER_C_FLAGS}")

list(FILTER APP_SOURCES EXCLUDE REGEX ".*ui.*\\.c$")

add_executable(fuzzer ${CMAKE_CURRENT_SOURCE_DIR}/mock.c  ${CMAKE_CURRENT_SOURCE_DIR}/fuzz_tx_parser.c ${APP_SOURCES})
target_compile_options(fuzzer PRIVATE ${LEDGER_C_FLAGS})
target_link_options(fuzzer PRIVATE ${LEDGER_LD_FLAGS})
target_include_directories(fuzzer PUBLIC ${APP_INCLUDE_DIR})
target_link_libraries(fuzzer PUBLIC cxng standard graphics glyphs)
target_compile_definitions(fuzzer PRIVATE ${DEFINES})