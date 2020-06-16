#
# Common Library
#
set(LIB_SRCS
    imagestorage.cpp
    filesystemimagefetcher.cpp
    ${LIB_SRCS}
)

add_library(kokocommon SHARED ${LIB_SRCS})
target_link_libraries(kokocommon
    Qt5::Core
    Qt5::Positioning
    Qt5::Sql
    KF5::CoreAddons
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
    reversegeocoder.cpp
    filesystemtracker.cpp
    processor.cpp
    committimer.cpp
    imageprocessorrunnable.cpp
    exiv2extractor.cpp
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
    LibExiv2::LibExiv2
)

if(ANDROID)
    target_link_libraries(koko Qt5::AndroidExtras)
endif()

install(TARGETS koko ${INSTALL_TARGETS_DEFAULT_ARGS})

#
# QML Plugin
#
set (qml_plugin_SRCS
    qmlplugins.cpp
    tagmodel.cpp
    imagelocationmodel.cpp
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

install (TARGETS kokoqmlplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/koko)
install (FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/koko)
install (FILES org.kde.koko.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})

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
        message(FATAL_ERROR "You need to download packag separately. See packaging section in the readme.")
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
        message(FATAL_ERROR "You need to download packag separately. See packaging section in the readme.")
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
        message(FATAL_ERROR "You need to download packag separately. See packaging section in the readme.")
    endif()
endif()

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/cities1000.txt DESTINATION ${DATA_INSTALL_DIR}/koko)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/admin1Codes.txt DESTINATION ${DATA_INSTALL_DIR}/koko)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/admin2Codes.txt DESTINATION ${DATA_INSTALL_DIR}/koko)
install (FILES countries.csv DESTINATION ${DATA_INSTALL_DIR}/koko)
install (FILES koko.notifyrc DESTINATION ${KNOTIFYRC_INSTALL_DIR})
