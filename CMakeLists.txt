cmake_minimum_required(VERSION 3.4)
project(NVMe)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

include_directories("sw/deps/spdlog-1.11.0/include")

add_subdirectory(sw)
