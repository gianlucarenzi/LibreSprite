# LibreSprite Desktop Integration Module
# Copyright (C) 2016  Gabriel Rauter
#
# Licensed under the the MIT License (https://opensource.org/licenses/MIT).

# This module targets CMake 4.1. Debian 13 (trixie) and older don't package
# it, so fall back to the previous minimum version there if 4.1 isn't found.
set(_LIBRESPRITE_CMAKE_MIN 4.1)
if(CMAKE_VERSION VERSION_LESS 4.1 AND EXISTS "/etc/os-release")
  file(STRINGS "/etc/os-release" _LIBRESPRITE_OS_RELEASE)
  string(REGEX MATCH "ID=\"?debian\"?" _LIBRESPRITE_IS_DEBIAN "${_LIBRESPRITE_OS_RELEASE}")
  string(REGEX MATCH "VERSION_ID=\"?([0-9]+)\"?" _LIBRESPRITE_UNUSED "${_LIBRESPRITE_OS_RELEASE}")
  if(_LIBRESPRITE_IS_DEBIAN AND CMAKE_MATCH_1 AND CMAKE_MATCH_1 LESS_EQUAL 13)
    set(_LIBRESPRITE_CMAKE_MIN 3.18)
  endif()
endif()
cmake_minimum_required(VERSION ${_LIBRESPRITE_CMAKE_MIN})
set(QT_MIN_VERSION "5.2.0")
project(librespritethumbnail)
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})
set(KDE_INSTALL_DIRS_NO_DEPRECATED, TRUE)
include(FeatureSummary)
include(WriteBasicConfigVersionFile)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)
find_package(KF5 REQUIRED COMPONENTS KIO)
add_definitions(${QT_DEFINITIONS} -DQT_USE_FAST_CONCATENATION -DQT_USE_FAST_OPERATOR_PLUS)
set(KDE_INSTALL_USE_QT_SYS_PATHS)
add_library(librespritethumbnail MODULE aseprite_thumb_creator.cpp)
target_link_libraries(librespritethumbnail KF5::KIOWidgets)
install(TARGETS librespritethumbnail DESTINATION ${PLUGIN_INSTALL_DIR})
install(FILES librespritethumbnail.desktop DESTINATION ${SERVICES_INSTALL_DIR})
