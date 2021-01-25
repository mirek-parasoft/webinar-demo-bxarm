### BEGIN CMAKE_TOOLCHAIN_FILE
# "Generic" is used when cross compiling
set (CMAKE_SYSTEM_NAME Generic)

# Some system-dependent settings
if (WIN32)
  # <arch> --> <ARCH>
  string (TOUPPER ${ICC_CPU_arch} ICC_CPU_ARCH)
  set (ICC_INSTALLATION_PLACES
    "$ENV{ProgramFiles\(x86\)}/IAR Systems/Embedded Workbench 8.4"
    "$ENV{ProgramFiles\(x86\)}/IAR Systems/Embedded Workbench 8.3"
    "$ENV{ProgramFiles\(x86\)}/IAR Systems/Embedded Workbench 8.2"
    "$ENV{ProgramFiles\(x86\)}/IAR Systems/Embedded Workbench 8.1"
    "$ENV{ProgramFiles\(x86\)}/IAR Systems/Embedded Workbench 8.*"
    "$ENV{SystemDrive}/IAR/EW${ICC_CPU_ARCH}/${ICC_VERSION}"
    "$ENV{SystemDrive}/IAR/EW${ICC_CPU_ARCH}/*"
    "$ENV{SystemDrive}/IAR/EW/${ICC_CPU_ARCH}/${ICC_VERSION}"	
    "$ENV{SystemDrive}/IAR/EW/${ICC_CPU_ARCH}/*"
  )
  # Default max_path length is 260.  Ninja fails if >245 chars.  
  # This option lets cmake use tricks to shrink the path.
  set (CMAKE_OBJECT_PATH_MAX 240)
  set (NUM_PROCS "$ENV{NUMBER_OF_PROCESSORS}")
else()
  set (ICC_INSTALLATION_PLACES
    "/opt/iarsystems/bx${ICC_CPU_arch}*/${ICC_CPU_arch}"
  )
  set (NUM_PROCS 2)
endif()

find_path (ICC_PATH
  NAMES icc${ICC_CPU_arch} icc${ICC_CPU_arch}.exe
  PATHS ${ICC_INSTALLATION_PLACES}
  HINTS ${ICC_INSTALLATION_PLACES}
  PATH_SUFFIXES ${ICC_CPU_arch}/bin
)
           
if (NOT ICC_PATH)
  message (FATAL_ERROR "Could not find the folder containing the IAR Toolchain for [${ICC_CPU_arch}].")
else() 
  message (STATUS "Found IAR Toolchain for [${ICC_CPU_arch}] at: ${ICC_PATH}")    
endif()

# Fallback to defaults if none is specified
if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message ("-- Setting build type to 'Debug' as none was specified")
  set (CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build" FORCE)
  # Set the possible values of build type for cmake-gui
  set_property (CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Default C compiler flags
set (CMAKE_C_FLAGS_DEBUG_INIT "-Ol -e --debug --no_cse --no_unroll --no_inline --no_code_motion --no_tbaa --no_clustering --no_scheduling --use_c++_inline -DDEBUG")
set (CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG_INIT}" CACHE STRING "" FORCE)
set (CMAKE_C_FLAGS_RELEASE_INIT "-Ohs -e --use_c++_inline -DNDEBUG")
set (CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE_INIT}" CACHE STRING "" FORCE)
set (CMAKE_C_FLAGS_MINSIZEREL_INIT "-Ohz -e  -DNDEBUG")
set (CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL_INIT}" CACHE STRING "" FORCE)
set (CMAKE_C_FLAGS_RELWITHDEBINFO_INIT "-Ohs -e --debug -DDEBUG")
set (CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO_INIT}" CACHE STRING "" FORCE)

# Default C++ compiler flags
set (CMAKE_CXX_FLAGS_DEBUG_INIT "--c++ -Ol --debug  --no_cse --no_unroll --no_inline --no_code_motion --no_tbaa --no_clustering --no_scheduling --no_exceptions --no_rtti -DDEBUG")
set (CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG_INIT}" CACHE STRING "" FORCE)
set (CMAKE_CXX_FLAGS_RELEASE_INIT "--c++ -Ohs --no_exceptions --no_rtti -DNDEBUG")
set (CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE_INIT}" CACHE STRING "" FORCE)
set (CMAKE_CXX_FLAGS_MINSIZEREL_INIT "--c++ -Ohz --no_exceptions --no_rtti -DNDEBUG")
set (CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL_INIT}" CACHE STRING "" FORCE)
set (CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "--c++ -Ohs --no_exceptions --no_rtti --debug -DDEBUG")
set (CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT}" CACHE STRING "" FORCE)

# Set DLIB header
#set (DLIB_CONFIG "--dlib_config ${ICC_PATH}/../inc/c/DLib_Config_${ICC_DLIB_CONFIG}.h")
set (DLIB_CONFIG "--dlib_config full")

# IAR C (and C++) Compiler 
find_program (ICC_EXECUTABLE
  NAMES icc${ICC_CPU_arch} icc${ICC_CPU_arch}.exe
  PATHS ${ICC_PATH} 
  HINTS ${ICC_PATH} 
  PATH_SUFFIXES ${ICC_CPU_arch}/bin
)
if (NOT ICC_EXECUTABLE)
  message (FATAL_ERROR "IAR C/C++ Compiler for ${ICC_CPU_arch} could not be found.")
endif()              

# IAR Assembler
find_program (IASM_EXECUTABLE
  NAMES iasm${ICC_CPU_arch} iasm${ICC_CPU_arch}.exe
  PATHS ${ICC_PATH} 
  HINTS ${ICC_PATH} 
  PATH_SUFFIXES ${ICC_CPU_arch}/bin
)
if (NOT IASM_EXECUTABLE)
  message (FATAL_ERROR "IAR Assembler for ${ICC_CPU_arch} could not be found.")
endif()

set (CMAKE_C_COMPILER   ${ICC_EXECUTABLE}  "${ICC_CPU_FLAGS} ${DLIB_CONFIG}")
set (CMAKE_CXX_COMPILER ${ICC_EXECUTABLE}  "${ICC_CPU_FLAGS} ${DLIB_CONFIG}")
set (CMAKE_ASM_COMPILER ${IASM_EXECUTABLE} "${ICC_CPU_FLAGS}")

# Use semihosting?
if (ICC_DLIB_USE_SEMIHOSTING)
  set (ICC_DLIB_FLAGS "${ICC_DLIB_FLAGS} --semihosting")
endif()

# Default CMSIS headers ?
if (ICC_DLIB_USE_CMSIS)
  if (${ICC_CPU_arch} STREQUAL "arm")
    include_directories (SYSTEM "${ICC_PATH}/../CMSIS/Core/Include")
  else()
    message (FATAL_ERROR "The CMSIS feature is only available for Arm.")
  endif()
endif()

# Should use the stock ICF or custom?
if (${ICC_CPU_LINKER} MATCHES "default")
  set (ICC_LINKER_CONFIG "--config ${ICC_PATH}/../config/linker/${ICC_CPU_VENDOR}/${ICC_CPU_MODEL}.icf")
else()
  set (ICC_LINKER_CONFIG "--config ../${ICC_CPU_LINKER}")
endif()

# Default Linker flags
set (CMAKE_C_LINK_FLAGS   "${ICC_DLIB_FLAGS} --entry __iar_program_start --vfe --text_out locale --map . ${ICC_LINKER_CONFIG}")
set (CMAKE_CXX_LINK_FLAGS "${ICC_DLIB_FLAGS} --entry __iar_program_start --vfe --text_out locale --map . ${ICC_LINKER_CONFIG}")

macro (ielftool_generate_ihex target)
  add_custom_command (
    TARGET ${target} POST_BUILD
    COMMAND "${CMAKE_IAR_ELFTOOL}"
            --ihex
            --silent
            "${CMAKE_CURRENT_BINARY_DIR}/${target}.elf"
            "${CMAKE_CURRENT_BINARY_DIR}/${target}.hex"
    COMMENT "Generating : ${target}.hex file."
    VERBATIM
  )
endmacro()

macro (ielftool_generate_srec target)
  add_custom_command (
    TARGET ${target} POST_BUILD
    COMMAND "${CMAKE_IAR_ELFTOOL}"
            --srec
            --silent
            "${CMAKE_CURRENT_BINARY_DIR}/${target}.elf"
            "${CMAKE_CURRENT_BINARY_DIR}/${target}.srec"
    COMMENT "Generating : ${target}.srec file."
    VERBATIM
  )
endmacro()

function (get_project_name ICC_PROJECT_NAME)
  get_filename_component (P_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)
  string (REPLACE " " "_" P_NAME ${P_NAME})
  set (${ICC_PROJECT_NAME} ${P_NAME} PARENT_SCOPE)
endfunction()
get_project_name (ICC_PROJECT_NAME)

################################################################################################################
### ------------------------------------------------ C-STAT ------------------------------------------------ ###
################################################################################################################

set (ICSTAT_TIMEOUT         "--timeout=600")
set (ICSTAT_MSG_LIMIT       "--message_limit=100")
set (ICSTAT_SELECTED_CHECKS "${CMAKE_CURRENT_BINARY_DIR}/cstat_sel_checks.txt" CACHE FILEPATH "C-STAT Checks")
set (ICSTAT_COMMANDS        "${CMAKE_CURRENT_BINARY_DIR}/cstatcmds.txt"        CACHE FILEPATH "C-STAT Commands")
set (ICSTAT_DB              "${CMAKE_CURRENT_BINARY_DIR}/cstat.db"             CACHE FILEPATH "C-STAT Database")
set (ICSTAT_HEADER_PATHS "")
set (ICSTAT_DEFINES "")
set (ICSTAT_DLIB ${DLIB_CONFIG})

find_program(ICHECKS_EXECUTABLE
  NAMES ichecks ichecks.exe
  PATHS ${ICC_PATH} 
  HINTS ${ICC_PATH} 
  PATH_SUFFIXES ${ICC_CPU_arch}/bin
)
find_program(ICSTAT_EXECUTABLE 
  NAMES icstat icstat.exe
  PATHS ${ICC_PATH} 
  HINTS ${ICC_PATH} 
  PATH_SUFFIXES ${ICC_CPU_arch}/bin
)

function (cstat_analyze_definitions defs)
  foreach (defines IN LISTS ARGV)
    string (APPEND compiler_defines " -D${defines}")
  endforeach()
  set (ICSTAT_DEFINES ${compiler_defines} PARENT_SCOPE)
endfunction()

function (cstat_analyze_headers includes)
  if (ICC_DLIB_USE_CMSIS)
    string (APPEND HEADER_PATHS " -I \"${ICC_PATH}/../CMSIS/Core/Include\"")
  endif()
  foreach (include_path IN LISTS ARGV)
    string (APPEND HEADER_PATHS " -I \"${CMAKE_SOURCE_DIR}/${include_path}\"")
  endforeach()
  set (ICSTAT_HEADER_PATHS ${HEADER_PATHS} PARENT_SCOPE)
endfunction()

function (cstat_analyze_sources sources)
  string (TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_UPPER)
  foreach (src IN LISTS ARGV)
    if (src MATCHES ".c$")
      set (ICSTAT_COMPILER_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE_UPPER}}")
      set (ICSTAT_CMD_LINK_ANALIZE_FILES ${ICSTAT_CMD_LINK_ANALIZE_FILES} "${PROJECT_BINARY_DIR}/${ICC_PROJECT_NAME}.dir/${src}${CMAKE_C_OUTPUT_EXTENSION} ")
    endif()
    if (src MATCHES ".cpp$|.cxx$")
      set (ICSTAT_COMPILER_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_${CMAKE_BUILD_TYPE_UPPER}}")
      set (ICSTAT_CMD_LINK_ANALIZE_FILES ${ICSTAT_CMD_LINK_ANALIZE_FILES} "${PROJECT_BINARY_DIR}/${ICC_PROJECT_NAME}.dir/${src}${CMAKE_CXX_OUTPUT_EXTENSION} ")
    endif()
    set (ICSTAT_COMPILER_FLAGS "${ICSTAT_COMPILER_FLAGS} ${ICC_CPU_FLAGS} ${ICSTAT_DLIB} ${ICSTAT_HEADER_PATHS}")
    set (ICSTAT_CMDS_LIST ${ICSTAT_CMDS_LIST} "analyze ${ICSTAT_TIMEOUT} ${ICSTAT_MSG_LIMIT} -- icc${ICC_CPU_arch} ${ICSTAT_DEFINES} ${ICSTAT_COMPILER_FLAGS} \"${PROJECT_SOURCE_DIR}/${src}\"\n")  
  endforeach()
  set (ICSTAT_CMD_LINK_ANALIZE "link_analyze ${ICSTAT_TIMEOUT} ${ICSTAT_MSG_LIMIT} -- ${ICSTAT_CMD_LINK_ANALIZE_FILES}")
  set (ICSTAT_CMDS_LIST ${ICSTAT_CMDS_LIST} ${ICSTAT_CMD_LINK_ANALIZE})
  file (WRITE ${ICSTAT_COMMANDS} ${ICSTAT_CMDS_LIST})
endfunction()

function (generate_cstat_target)
  set (ICSTAT_FLAGS --db ${ICSTAT_DB} --checks ${ICSTAT_SELECTED_CHECKS} CACHE STRING "Additional C-STAT command line options")  
  cstat_analyze_definitions(${ICC_DEFINITIONS})
  cstat_analyze_headers(${ICC_INCLUDE_PATHS})
  cstat_analyze_sources(${ICC_C_SOURCES} ${ICC_CXX_SOURCES})
  add_custom_target (cstat_analyze
    COMMAND ${ICHECKS_EXECUTABLE} --package ${CSTAT_SELECT_CHECKS} --output ${ICSTAT_SELECTED_CHECKS}
    COMMAND ${ICSTAT_EXECUTABLE} ${ICSTAT_FLAGS} --parallel ${NUM_PROCS} commands ${ICSTAT_COMMANDS}  
    COMMENT "Performing C-STAT Static Analysis..."
    VERBATIM
  )
endfunction()

macro (iar_macros)
  # Should generate an Intel HEX output ?
  if (ICC_OUTPUT_CONVERTER MATCHES "hex")
    ielftool_generate_ihex(${ICC_PROJECT_NAME})
  endif()

  # Should generate a SREC output ?
  if (ICC_OUTPUT_CONVERTER MATCHES "srec")
    ielftool_generate_srec(${ICC_PROJECT_NAME})
  endif()

  # Should perform C-STAT Static Analysis ?

  if (CSTAT_SELECT_CHECKS)
    if (NOT ICHECKS_EXECUTABLE)
      message (FATAL_ERROR "ichecks${EXTENSION} executable not found. Analysis should be disabled.")
    endif()
    if (NOT ICSTAT_EXECUTABLE) 
      message (FATAL_ERROR "icstat${EXTENSION} executable not found. Analysis should be disabled.")
    endif()
    if (NOT DEFINED ICC_DEFINITIONS)
      message (STATUS "C-STAT target might require ICC_DEFINITIONS")
    endif()
    if (NOT DEFINED ICC_INCLUDE_PATHS)
      message (FATAL_ERROR "C-STAT target requires ICC_INCLUDE_PATHS")
    endif()
    
    # Generate a C-STAT target 
    generate_cstat_target()
  endif()
endmacro()
### END CMAKE_TOOLCHAIN_FILE
