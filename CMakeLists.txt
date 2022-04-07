# SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
# SPDX-License-Identifier: LGPL-2.0-or-later

project(Koko)
cmake_minimum_required(VERSION 3.16)

set(CMAKE_CXX_STANDARD 17)
set(QT5_MIN_VERSION 5.15)
set(KF5_MIN_VERSION 5.87)
set(KDE_COMPILERSETTINGS_LEVEL 5.84)

set(PROJECT_VERSION "22.02")

find_package(ECM ${KF5_MIN_VERSION} REQUIRED NO_MODULE)
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
include(KDEGitCommitHooks)
include(ECMSetupVersion)

ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX KOKO
    VERSION_HEADER ${CMAKE_CURRENT_BINARY_DIR}/version.h
)
find_package(Qt5 ${QT5_MIN_VERSION} REQUIRED NO_MODULE COMPONENTS Qml Quick Widgets Test Sql Positioning Svg)

if(ANDROID)
    find_package(Qt5 ${QT5_MIN_VERSION} REQUIRED NO_MODULE COMPONENTS AndroidExtras)
endif()

find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS I18n Declarative Config KIO GuiAddons CoreAddons Notifications FileMetaData DBusAddons)

find_package(LibExiv2 0.21 REQUIRED)

ecm_find_qmlmodule(org.kde.kquickimageeditor 1.0)
find_package(KQuickImageEditor COMPONENTS)
set_package_properties(KQuickImageEditor PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Simple image editor for QtQuick applications"
    URL "https://invent.kde.org/libraries/kquickimageeditor/"
    PURPOSE "Add image editing capability to image attachments"
)

ecm_find_qmlmodule(QtGraphicalEffects 1.0)

find_package(Qt5X11Extras ${QT5_MIN_VERSION})
set_package_properties(Qt5X11Extras PROPERTIES
    DESCRIPTION "Qt extras for the X11 platform"
    PURPOSE "Required for getting display color profile on X11"
    TYPE OPTIONAL
)

find_package(XCB COMPONENTS XCB)
set_package_properties(XCB PROPERTIES
    PURPOSE "Required for getting display color profile on X11"
    TYPE OPTIONAL
)

find_package(Qt5QuickControls2 ${QT5_MIN_VER})
set_package_properties(Qt5QuickControls2 PROPERTIES
    DESCRIPTION "User interface controls based on Qt Quick"
    PURPOSE "Required at runtime to run Koko"
    TYPE RUNTIME
)

find_package(KF5Kirigami2)
set_package_properties(KF5Kirigami2 PROPERTIES
    DESCRIPTION "A QtQuick based components set"
    PURPOSE "Required at runtime to run Koko"
    TYPE RUNTIME
)

include_directories(
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/src
  ${CMAKE_BINARY_DIR}/src
)

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    add_definitions(-DQT_QML_DEBUG)
endif()

ki18n_install(po)

kde_enable_exceptions()
add_subdirectory(src)
add_subdirectory(autotests)
add_subdirectory(icons)

install(FILES org.kde.koko.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})

# add clang-format target for all our real source files
file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})
kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
