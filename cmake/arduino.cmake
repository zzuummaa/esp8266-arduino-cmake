include(cmake/esp8266.cmake)
include(cmake/comport_settings.cmake)
include(cmake/ota_deploy.cmake)

# macro arduino
# usage:
# arduino(executable_name library1 library2 library3 ...)
# example:
# add_executable(firmware ${USER_SOURCES})
# arduino(firmware ESP8266WiFi Servo)
macro(arduino)
    # first argument - name of executable project, other - library names
    set(ARGUMENTS ${ARGN})
    list(GET ARGUMENTS 0 PROJECT_NAME)
    list(REMOVE_AT ARGUMENTS 0)

    # create core library
    # esp8266 core files
    file(GLOB_RECURSE CORE_ASM_ITEMS "${HARDWARE_ROOT}/cores/esp8266/*.S")
    file(GLOB_RECURSE CORE_C_ITEMS "${HARDWARE_ROOT}/cores/esp8266/*.c")
    file(GLOB_RECURSE CORE_CXX_ITEMS "${HARDWARE_ROOT}/cores/esp8266/*.cpp")

    add_library(${PROJECT_NAME}_arduino_core STATIC ${CORE_ASM_ITEMS} ${CORE_C_ITEMS} ${CORE_CXX_ITEMS})

    # esp8266 include directories
    target_include_directories(${PROJECT_NAME}_arduino_core PUBLIC
            ${HARDWARE_ROOT}/tools/sdk/include
            ${HARDWARE_ROOT}/tools/sdk/lwip2/include
            ${HARDWARE_ROOT}/tools/sdk/libc/xtensa-lx106-elf/include
            ${HARDWARE_ROOT}/cores/esp8266
            ${HARDWARE_ROOT}/variants/d1_mini
    )

    # and esp8266 build definitions
    target_compile_definitions(${PROJECT_NAME}_arduino_core PUBLIC
            -D__ets__
            -DICACHE_FLASH
            -DNO_EXTRA_4K_HEAP
            -DF_CPU=80000000L
            -DLWIP_OPEN_SRC
            -DARDUINO=10804
            -DARDUINO_ESP8266_GENERIC
            -DARDUINO_ARCH_ESP8266
            -DARDUINO_BOARD="ESP8266_GENERIC"
            -DLED_BUILTIN=2
            -DESP8266
            )

    # some other options and link libraries
    target_compile_options(${PROJECT_NAME}_arduino_core PUBLIC -U__STRICT_ANSI__)
    target_link_libraries(${PROJECT_NAME}_arduino_core PUBLIC hal phy pp net80211 lwip2 wpa crypto main wps axtls espnow smartconfig airkiss wpa2 stdc++ m c gcc)

    # empty lists of library files and include direcories
    set(LIBRARIES_FILES)
    set(LIBRARY_INCLUDE_DIRECTORIES)

    # for each every library determine it's sources and include directories
    foreach(ITEM ${ARGUMENTS})
        # library can be located in 3 different places.
        # user files located under documents folder
        set(LIBRARY_HOME ${USER_LIBRARIES_ROOT}/${ITEM})
        if(NOT EXISTS ${LIBRARY_HOME})
            # if no user library, look into esp8266 hardware libraries
            set(LIBRARY_HOME ${ESP8266_LIBRARIES_ROOT}/${ITEM})
            if(NOT EXISTS ${LIBRARY_HOME})
                # last chance that it be arduino standard library (as servo or SD)
                set(LIBRARY_HOME ${SYSTEM_LIBRARIES_ROOT}/${ITEM})
                if(NOT EXISTS ${LIBRARY_HOME})
                    message( FATAL_ERROR "Library ${ITEM} does not found")
                endif()
            endif()
        endif()
        # look for library source files
        file(GLOB_RECURSE LIBRARY_S_FILES ${LIBRARY_HOME}/*.S)
        file(GLOB_RECURSE LIBRARY_C_FILES ${LIBRARY_HOME}/*.c)
        file(GLOB_RECURSE LIBRARY_X_FILES "${LIBRARY_HOME}/*.cpp")
        # and append it to library sources list
        list(APPEND LIBRARIES_FILES ${LIBRARY_S_FILES} ${LIBRARY_c_FILES} ${LIBRARY_X_FILES})
        # also look into header files
        file(GLOB_RECURSE LIBRARY_H_FILES ${LIBRARY_HOME}/*.h ${LIBRARY_HOME}/*.hpp)
        foreach(HEADER_FILE ${LIBRARY_H_FILES})
            get_filename_component(HEADER_DIRECTORY ${HEADER_FILE} DIRECTORY)
            if (${HEADER_FILE} MATCHES ".*/linux/")
                message(${HEADER_FILE})
                continue()
            endif()
            list(APPEND LIBRARY_INCLUDE_DIRECTORIES ${HEADER_DIRECTORY})
        endforeach()
    endforeach()
    # exclude header directories duplicates
    list(REMOVE_DUPLICATES LIBRARY_INCLUDE_DIRECTORIES)

    # exclude linux sources
    list(FILTER LIBRARIES_FILES EXCLUDE REGEX ".*/linux/[^/]")

    # append all libraries sources to target executable
    target_sources(${PROJECT_NAME} PUBLIC ${LIBRARIES_FILES})
    # add include directories to it
    target_include_directories(${PROJECT_NAME} PUBLIC ${LIBRARY_INCLUDE_DIRECTORIES})

    # append arduino_core library as part of target executable
    target_link_libraries(${PROJECT_NAME} PUBLIC ${PROJECT_NAME}_arduino_core)

    # and custom command to create bin file
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${ESPTOOL_APP} -eo ${HARDWARE_ROOT}/bootloaders/eboot/eboot.elf -bo $<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.bin -bm dio -bf 40 -bz 1M -bs .text -bp 4096 -ec -eo $<TARGET_FILE:firmware> -bs .irom0.text -bs .text -bs .data -bs .rodata -bc -ec
            COMMENT "Building ${PROJECT_NAME}> bin file")

    add_custom_target(${PROJECT_NAME}_flash_comport
            COMMAND ${ESPTOOL_APP} -vv -cd ck -cb 115200 -cp ${ESPTOOL_COM_PORT} -ca 0x00000 -cf $<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.bin
            DEPENDS ${PROJECT_NAME})

    if (CURL)
        add_custom_target(${PROJECT_NAME}_deploy_ota
                COMMAND curl -v -F file=@$<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.bin --insecure -u admin@blynk.cc:admin https://${OTA_HOST}:${OTA_PORT}/admin/ota/start?token=${OTA_TOKEN}
                DEPENDS ${PROJECT_NAME})
    endif()
endmacro()