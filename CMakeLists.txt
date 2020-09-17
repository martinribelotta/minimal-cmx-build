cmake_minimum_required(VERSION 3.5)

set(TARGET_NAME armv7m-universal.elf)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(LIB_PATH "${CMAKE_SOURCE_DIR}/lib")
set(LINKER_SCRIPT "${CMAKE_SOURCE_DIR}/lib/link.ld")
set(ARCH_FLAGS "-mcpu=cortex-m3 -mthumb")
set(C_FLAGS "-fdata-sections -ffunction-sections -fmove-loop-invariants")
set(LD_FLAGS "-Wl,--print-memory-usage -Wl,--gc-sections -specs=nosys.specs -nostartfiles -L${LIB_PATH} -T${LINKER_SCRIPT}")

set(CMAKE_C_FLAGS "${ARCH_FLAGS} ${C_FLAGS} ${OPT_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LD_FLAGS}")
project(${TARGET_NAME} LANGUAGES C)

file(GLOB CSRC src/*.c)
include_directories(inc)

file(GLOB OOCD_SCRIPT flash.cfg)

add_executable(${TARGET_NAME} ${CSRC})
set_target_properties(${TARGET_NAME} PROPERTIES LINK_DEPENDS ${LINKER_SCRIPT})
add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                   COMMAND arm-none-eabi-objdump -z -x -s -S -d ${TARGET_NAME} > ${TARGET_NAME}.objdump
                   VERBATIM USES_TERMINAL)

add_custom_target(flash DEPENDS ${TARGET_NAME})
add_custom_command(TARGET flash USES_TERMINAL
                   COMMAND openocd -f ${OOCD_SCRIPT} -c "program ${TARGET_NAME} verify reset exit")

add_custom_target(erase)
add_custom_command(TARGET erase USES_TERMINAL
                   COMMAND openocd -f ${OOCD_SCRIPT} -c "init" -c "reset halt" -c "flash erase_sector 0 0 last" -c "exit")
