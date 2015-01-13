#
# Common Library
#
set(LIB_SRCS
    imagestorage.cpp
    balooimagefetcher.cpp
)

add_library(kokocommon SHARED ${LIB_SRCS})
target_link_libraries(kokocommon
    Qt5::Core
    Qt5::Positioning
    Qt5::Sql
    KF5::Baloo
)

generate_export_header(kokocommon BASE_NAME KOKO EXPORT_FILE_NAME koko_export.h)

install(TARGETS kokocommon EXPORT KokoLibraryTargets ${INSTALL_TARGETS_DEFAULT_ARGS})

#
# Application
#
add_executable(koko
    main.cpp
    reversegeocodelookupjob.cpp
    reversegeocoder.cpp
    filesystemtracker.cpp
    processor.cpp
    imageprocessorrunnable.cpp
    exiv2extractor.cpp
    kokoconfig.cpp
)

target_link_libraries(koko
    Qt5::Quick
    Qt5::Widgets
    Qt5::Qml
    Qt5::Positioning
    KF5::ConfigCore
    KF5::Baloo
    KF5::DBusAddons
    KF5::I18n
    kokocommon
    ${EXIV2_LIBRARIES}
    ${KDETREE_LIBRARIES}
)

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
)

add_library (kokoqmlplugin SHARED ${qml_plugin_SRCS})

target_link_libraries (kokoqmlplugin
    Qt5::Qml
    kokocommon
)

install (TARGETS kokoqmlplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/koko)
install (FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/koko)
install (FILES org.kde.koko.desktop DESTINATION ${XDG_APPS_INSTALL_DIR})

#
# Reverse GeoLookup Data
#
if (NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/cities1000.zip)
    file (DOWNLOAD "http://download.geonames.org/export/dump/cities1000.zip"
                ${CMAKE_CURRENT_BINARY_DIR}/cities1000.zip
        SHOW_PROGRESS
    )
endif()

execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar -xzf ${CMAKE_CURRENT_BINARY_DIR}/cities1000.zip
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/cities1000.txt DESTINATION ${DATA_INSTALL_DIR}/koko)
