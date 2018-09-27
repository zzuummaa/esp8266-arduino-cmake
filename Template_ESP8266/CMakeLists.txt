cmake_minimum_required(VERSION 3.6)
project(Template_ESP8266 CXX C ASM)

file(GLOB_RECURSE SOURCES "*.cpp" "*.h")

add_executable(${PROJECT_NAME} ${SOURCES})

ARDUINO(${PROJECT_NAME}
        ESP8266WiFi
        ESP8266WebServer
        ESP8266HTTPUpdateServer
        ESP8266HTTPClient
        ESP8266httpUpdate
        ESP8266mDNS
        DNSServer
        Blynk
        EEPROM
        Ticker
)
