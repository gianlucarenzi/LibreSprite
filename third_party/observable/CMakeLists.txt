# Observable Library
# Copyright (C) 2016-2021 David Capello

# Observable targets CMake 4.1. Debian 12 (bookworm) and older don't package
# it, so fall back to the previous minimum version there if 4.1 isn't found.
set(_LIBRESPRITE_CMAKE_MIN 4.1)
if(CMAKE_VERSION VERSION_LESS 4.1 AND EXISTS "/etc/os-release")
  file(STRINGS "/etc/os-release" _LIBRESPRITE_OS_RELEASE)
  string(REGEX MATCH "ID=\"?debian\"?" _LIBRESPRITE_IS_DEBIAN "${_LIBRESPRITE_OS_RELEASE}")
  string(REGEX MATCH "VERSION_ID=\"?([0-9]+)\"?" _LIBRESPRITE_UNUSED "${_LIBRESPRITE_OS_RELEASE}")
  if(_LIBRESPRITE_IS_DEBIAN AND CMAKE_MATCH_1 AND CMAKE_MATCH_1 LESS_EQUAL 12)
    set(_LIBRESPRITE_CMAKE_MIN 3.18)
  endif()
endif()
cmake_minimum_required(VERSION ${_LIBRESPRITE_CMAKE_MIN})

project(observable CXX)
option(OBSERVABLE_TESTS "Compile observable tests" ON)
option(OBSERVABLE_BENCHMARKS "Compile observable benchmarks" OFF)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(UNIX AND NOT APPLE)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pthread")
endif()

add_library(obs obs/connection.cpp)
target_include_directories(obs PUBLIC .)

if(OBSERVABLE_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()

if(OBSERVABLE_BENCHMARKS)
  add_subdirectory(benchmarks)
endif()
