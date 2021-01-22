cmake_minimum_required (VERSION 3.15)

# Compiler flags for the toolchain configuration
set (ICC_CPU_arch "arm")
set (ICC_CPU_VENDOR "ST")
set (ICC_CPU_MODEL "stm32f429xI")
set (ICC_CPU_FLAGS "--cpu Cortex-M4 --fpu VFPv4_sp")
set (ICC_CPU_LINKER "default")
set (ICC_DLIB_CONFIG "normal")
set (ICC_DLIB_USE_SEMIHOSTING true)
set (ICC_DLIB_USE_CMSIS true)
set (ICC_OUTPUT_CONVERTER "hex,srec")
# Selection of the comma-separated group checks
# i.e. "stdchecks,misrac2004,misrac2012,misrac++2008"
#set (CSTAT_SELECT_CHECKS "stdchecks")


# Configure for the ICC architecture
include ("toolchain-icc${ICC_CPU_arch}.cmake")

# Name the .elf file with the current project's directory name
project (${ICC_PROJECT_NAME})

# Enable C and Assembly Languages
enable_language (ASM C)

set (ICC_DEFINITIONS 
  USE_STDPERIPH_DRIVER 
	HSE_VALUE=8000000
	STM32F429X
)
add_compile_definitions (${ICC_DEFINITIONS})

set (ICC_INCLUDE_PATHS
  CMSIS/Device/ST/STM32F4xx/Include
  STM32F4xx_StdPeriph_Driver/inc
  board
  app
) 
include_directories(${ICC_INCLUDE_PATHS})

set (ICC_C_SOURCES
	app/main.c
	app/stm32f4xx_it.c
	board/iar_stm32f429ii_aca.c
	startup/system_stm32f4xx.c
  STM32F4xx_StdPeriph_Driver/src/misc.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_adc.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_can.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_crc.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_dac.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_dbgmcu.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_dcmi.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_dma.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_exti.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_flash.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_fmc.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_gpio.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_i2c.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_iwdg.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_pwr.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_rcc.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_rng.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_rtc.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_sdio.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_spi.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_syscfg.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_tim.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_usart.c
  STM32F4xx_StdPeriph_Driver/src/stm32f4xx_wwdg.c
)

set (ICC_ASM_SOURCES
	startup/startup_stm32f429x.s
)
add_executable (${ICC_PROJECT_NAME} ${ICC_C_SOURCES} ${ICC_ASM_SOURCES})
iar_macros()

set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
