cmake_minimum_required(VERSION 3.6)
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/cmake/esp8266.cmake")
project(node CXX C ASM)

include(cmake/arduino.cmake)
add_subdirectory(Template_ESP8266)

set(USER_SOURCES src/main.cpp)
include_directories(src)

add_executable(firmware ${USER_SOURCES})
ARDUINO(firmware ESP8266WiFi ESP8266WebServer ESP8266mDNS)
