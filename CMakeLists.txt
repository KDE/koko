# SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
# SPDX-License-Identifier: LGPL-2.0-or-later

cmake_minimum_required(VERSION 3.16)

# KDE Applications version, managed by release script.
set(RELEASE_SERVICE_VERSION_MAJOR "24")
set(RELEASE_SERVICE_VERSION_MINOR "04")
set(RELEASE_SERVICE_VERSION_MICRO "70")
set(RELEASE_SERVICE_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}.${RELEASE_SERVICE_VERSION_MINOR}.${RELEASE_SERVICE_VERSION_MICRO}")

project(koko VERSION ${RELEASE_SERVICE_VERSION})

set(CMAKE_CXX_STANDARD 17)
set(QT_MIN_VERSION 6.5)
set(KF_MIN_VERSION 5.240)
set(KDE_COMPILERSETTINGS_LEVEL 5.84)

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${ECM_MODULE_PATH})

include(FeatureSummary)
include(ECMAddTests)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(ECMFindQmlModule)
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
find_package(Qt6 ${QT_MIN_VERSION} REQUIRED NO_MODULE COMPONENTS Qml Quick Widgets Test Sql Positioning Svg)

if(ANDROID)
    find_package(Qt6 ${QT_MIN_VERSION} REQUIRED NO_MODULE COMPONENTS AndroidExtras)
endif()

find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS I18n Declarative Config ConfigWidgets KIO GuiAddons CoreAddons Notifications FileMetaData DBusAddons)

find_package(LibExiv2 0.21 REQUIRED)

ecm_find_qmlmodule(org.kde.kquickimageeditor 1.0)
find_package(KQuickImageEditor COMPONENTS)
set_package_properties(KQuickImageEditor PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Simple image editor for QtQuick applications"
    URL "https://invent.kde.org/libraries/kquickimageeditor/"
    PURPOSE "Add image editing capability to image attachments"
)

find_package(XCB COMPONENTS XCB)
set_package_properties(XCB PROPERTIES
    PURPOSE "Required for getting display color profile on X11"
    TYPE OPTIONAL
)

find_package(Qt6QuickControls2 ${QT_MIN_VER})
set_package_properties(Qt6QuickControls2 PROPERTIES
    DESCRIPTION "User interface controls based on Qt Quick"
    PURPOSE "Required at runtime to run Koko"
    TYPE RUNTIME
)

find_package(KF6Kirigami)
set_package_properties(KF6Kirigami PROPERTIES
    DESCRIPTION "A QtQuick based components set"
    PURPOSE "Required at runtime to run Koko"
    TYPE RUNTIME
)

find_package(KF6Purpose)
set_package_properties(KF6Purpose PROPERTIES
    DESCRIPTION "Offers available actions for a specific purpose"
    PURPOSE "Required at runtime to run Koko and allow sharing of files"
    TYPE RUNTIME
)

include_directories(
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/src
  ${CMAKE_BINARY_DIR}/src
)

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
