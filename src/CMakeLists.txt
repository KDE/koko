# SPDX-FileCopyrightText: 2014 Vishesh Handa <vhanda@kde.org>
# SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
# SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# Common Library
#
set(LIB_SRCS
    imagestorage.cpp
    exiv2extractor.cpp
    filesystemimagefetcher.cpp
    ${LIB_SRCS}
)

add_library(kokocommon SHARED ${LIB_SRCS})
target_link_libraries(kokocommon
    Qt5::Core
    Qt5::Positioning
    Qt5::Sql
    Qt5::Svg
    KF5::CoreAddons
    KF5::DBusAddons
    KF5::FileMetaData
    LibExiv2::LibExiv2
)

generate_export_header(kokocommon BASE_NAME KOKO EXPORT_FILE_NAME koko_export.h)
set_target_properties(kokocommon PROPERTIES
    VERSION 0.0.1
    SOVERSION 0.0.1
)

install(TARGETS kokocommon EXPORT KokoLibraryTargets ${INSTALL_TARGETS_DEFAULT_ARGS})

#
# Application
#

set(koko_SRCS
    main.cpp
    openfilemodel.cpp
    reversegeocoder.cpp
    filesystemtracker.cpp
    processor.cpp
    committimer.cpp
    imageprocessorrunnable.cpp
    vectorimage.cpp
    kdtree.c
    resources.qrc
)

kconfig_add_kcfg_files(koko_SRCS kokoconfig.kcfgc GENERATE_MOC)

add_executable(koko ${koko_SRCS})

target_link_libraries(koko
    Qt5::Quick
    Qt5::Widgets
    Qt5::Qml
    Qt5::Positioning
    KF5::ConfigCore
    KF5::I18n
    KF5::CoreAddons
    KF5::KIOCore
    KF5::ConfigGui
    kokocommon
)

target_include_directories(koko PRIVATE ${CMAKE_BINARY_DIR})

if(ANDROID)
    target_link_libraries(koko Qt5::AndroidExtras)
endif()

install(TARGETS koko ${INSTALL_TARGETS_DEFAULT_ARGS})

#
# QML Plugin
#
set (qml_plugin_SRCS
    qmlplugins.cpp
    dirmodelutils.cpp
    openfilemodel.cpp
    imagelocationmodel.cpp
    imagefavoritesmodel.cpp
    imagetagsmodel.cpp
    imagetimemodel.cpp
    imagefoldermodel.cpp
    sortmodel.cpp
    allimagesmodel.cpp
    imagelistmodel.cpp
    notificationmanager.cpp
    types.cpp
    roles.cpp
    imagedocument.cpp
)

add_library (kokoqmlplugin SHARED ${qml_plugin_SRCS})

target_link_libraries (kokoqmlplugin
    Qt5::Qml
    KF5::KIOCore
    KF5::KIOFileWidgets
    KF5::KIOWidgets
    KF5::GuiAddons
    KF5::I18n
    KF5::Notifications
    kokocommon
)

install (TARGETS kokoqmlplugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/koko)
install (FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/koko)
install (FILES org.kde.koko.desktop DESTINATION ${KDE_INSTALL_APPDIR})

#
# Reverse GeoLookup Data
#
# Packagers can download the file and put it in the tarball
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/cities1000.zip)
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/cities1000.zip DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
endif()

if (NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/cities1000.zip)
    file (DOWNLOAD "http://download.geonames.org/export/dump/cities1000.zip"
                ${CMAKE_CURRENT_BINARY_DIR}/cities1000.zip
        SHOW_PROGRESS
        STATUS status
    )
    list(GET status 0 status_code) 
    if(NOT status_code EQUAL 0)
        message(FATAL_ERROR "You need to download some files separately. See the packaging section of README.md.")
    endif()
endif()

execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar -xzf ${CMAKE_CURRENT_BINARY_DIR}/cities1000.zip
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/admin1CodesASCII.txt)
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/admin1CodesASCII.txt DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
endif()

if (NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/admin1CodesASCII.txt)
    file (DOWNLOAD "http://download.geonames.org/export/dump/admin1CodesASCII.txt"
                ${CMAKE_CURRENT_BINARY_DIR}/admin1CodesASCII.txt
        SHOW_PROGRESS
        STATUS status
    )
    list(GET status 0 status_code) 
    if(NOT status_code EQUAL 0)
        message(FATAL_ERROR "You need to download some files separately. See the packaging section of README.md.")
    endif()
endif()
file(RENAME ${CMAKE_CURRENT_BINARY_DIR}/admin1CodesASCII.txt ${CMAKE_CURRENT_BINARY_DIR}/admin1Codes.txt)

if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/admin2Codes.txt)
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/admin2Codes.txt DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
endif()

if (NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/admin2Codes.txt)
    file (DOWNLOAD "http://download.geonames.org/export/dump/admin2Codes.txt"
                ${CMAKE_CURRENT_BINARY_DIR}/admin2Codes.txt
        SHOW_PROGRESS
        STATUS status
    )
    list(GET status 0 status_code) 
    if(NOT status_code EQUAL 0)
        message(FATAL_ERROR "You need to download some files separately. See the packaging section of README.md.")
    endif()
endif()

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/cities1000.txt DESTINATION ${KDE_INSTALL_DATADIR}/koko)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/admin1Codes.txt DESTINATION ${KDE_INSTALL_DATADIR}/koko)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/admin2Codes.txt DESTINATION ${KDE_INSTALL_DATADIR}/koko)
install (FILES countries.csv DESTINATION ${KDE_INSTALL_DATADIR}/koko)
install (FILES koko.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFY5RCDIR})
