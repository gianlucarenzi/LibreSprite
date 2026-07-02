# Undo Library
# Copyright (C) 2015 David Capello

# Undo targets CMake 4.1. Debian 12 (bookworm) and older don't package it,
# so fall back to the previous minimum version there if 4.1 isn't found.
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

project(undo CXX)
option(UNDO_TESTS "Compile undo tests" on)

include_directories(.)

if(UNIX)
  add_definitions(-std=c++11)
endif()

add_library(undo undo_history.cpp)

if(UNDO_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()
