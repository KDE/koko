# SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
# SPDX-License-Identifier: LGPL-2.0-or-later

project(Koko)
cmake_minimum_required(VERSION 3.16)

find_package(ECM 5.70.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${ECM_MODULE_PATH})

include(FeatureSummary)
include(ECMAddTests)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(ECMQMLModules)
include(KDECompilerSettings)
include(GenerateExportHeader)
include(ECMInstallIcons)
include(KDEClangFormat)

find_package(Qt5 REQUIRED NO_MODULE COMPONENTS Qml Quick Widgets Test Sql Positioning)

if(ANDROID)
    find_package(Qt5 REQUIRED NO_MODULE COMPONENTS AndroidExtras)
endif()

find_package(KF5 5.70 REQUIRED COMPONENTS I18n Declarative Config KIO GuiAddons CoreAddons Notifications FileMetaData)
find_package(LibExiv2 0.21 REQUIRED)

ecm_find_qmlmodule(org.kde.kquickimageeditor 1.0)
find_package(KQuickImageEditor COMPONENTS)
set_package_properties(KQuickImageEditor PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Simple image editor for QtQuick applications"
    URL "https://invent.kde.org/libraries/kquickimageeditor/"
    PURPOSE "Add image editing capability to image attachments"
)


include_directories(
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/src
  ${CMAKE_BINARY_DIR}/src
)

kde_enable_exceptions()
add_subdirectory(src)
add_subdirectory(autotests)
add_subdirectory(icons)

install(FILES org.kde.koko.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})

# add clang-format target for all our real source files
file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
