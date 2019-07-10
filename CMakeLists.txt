cmake_minimum_required(VERSION 3.6)
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/cmake/esp8266.cmake")
project(esp-arduino-cmake CXX C ASM)

include(cmake/arduino.cmake)
add_subdirectory(Template_ESP8266)

#set(USER_SOURCES src/main.cpp)
#set(USER_SOURCES esp_server/esp_server.cpp)
set(USER_SOURCES Template_ESP8266/Template_ESP8266.cpp)
include_directories(Template_ESP8266)

add_executable(firmware ${USER_SOURCES})
ARDUINO(firmware
        ESP8266WiFi
        ESP8266WebServer
        ESP8266HTTPUpdateServer
        ESP8266HTTPClient
        ESP8266httpUpdate
        ESP8266mDNS
        DNSServer
        Blynk
        EEPROM
        Ticker)
