cmake_minimum_required(VERSION 3.10)
project(wasm-fortanix)

set(WAMR_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
include (${WAMR_ROOT_DIR}/build-scripts/runtime_lib.cmake)
add_library(vmlib ${WAMR_RUNTIME_LIB_SOURCE})
# target_compile_options(vmlib PRIVATE -nostdlib -nostdinc)
