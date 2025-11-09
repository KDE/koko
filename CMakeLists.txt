# SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
# SPDX-License-Identifier: LGPL-2.0-or-later

cmake_minimum_required(VERSION 3.16)

# KDE Applications version, managed by release script.
set(RELEASE_SERVICE_VERSION_MAJOR "26")
set(RELEASE_SERVICE_VERSION_MINOR "03")
set(RELEASE_SERVICE_VERSION_MICRO "70")
set(RELEASE_SERVICE_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}.${RELEASE_SERVICE_VERSION_MINOR}.${RELEASE_SERVICE_VERSION_MICRO}")

project(koko VERSION ${RELEASE_SERVICE_VERSION})

set(CMAKE_CXX_STANDARD 20)
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
    VERSION_HEADER ${CMAKE_CURRENT_BINARY_DIR}/src/version.h
)
find_package(Qt6 ${QT_MIN_VERSION} NO_MODULE COMPONENTS Qml Quick Widgets Test Sql Positioning Svg QuickControls2)
if(Qt6Gui_VERSION VERSION_GREATER_EQUAL "6.9.0")
    find_package(Qt6 ${REQUIRED_QT_VERSION} CONFIG REQUIRED GuiPrivate)
endif()
find_package(Qt6 ${QT_MIN_VERSION} COMPONENTS PrintSupport)

if(ANDROID)
    find_package(Qt6 ${QT_MIN_VERSION} NO_MODULE COMPONENTS AndroidExtras)
endif()

set_package_properties(Qt6 PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Base components"
)

find_package(KF6 ${KF_MIN_VERSION} COMPONENTS I18n Declarative Config ConfigWidgets KIO GuiAddons CoreAddons Notifications FileMetaData DBusAddons Kirigami Purpose)
set_package_properties(KF6 PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Base components"
)

find_package(LibExiv2 0.28)
set_package_properties(LibExiv2 PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Image metadata library and tools"
    URL "https://github.com/Exiv2/exiv2"
    PURPOSE "Get image metadata"
)

ecm_find_qmlmodule(org.kde.kquickimageeditor)
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

ecm_find_qmlmodule(org.kde.kirigamiaddons.formcard REQUIRED)
ecm_find_qmlmodule(org.kde.kirigamiaddons.delegates REQUIRED)

find_package(KF6KirigamiAddons)
set_package_properties(KF6KirigamiAddons PROPERTIES
    TYPE REQUIRED
    PURPOSE "Required runtime dependency"
)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

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
