#
# Common Library
#
set(LIB_SRCS
    imagestorage.cpp
    balooimagefetcher.cpp
)

add_library(gallerycommon SHARED ${LIB_SRCS})
target_link_libraries(gallerycommon
    Qt5::Core
    Qt5::Positioning
    KF5::Baloo
    KVariantStore
)

generate_export_header(gallerycommon BASE_NAME GALLERY EXPORT_FILE_NAME gallery_export.h)

install(TARGETS gallerycommon EXPORT GalleryLibraryTargets ${INSTALL_TARGETS_DEFAULT_ARGS})

#
# Application
#
add_executable(gallery
    main.cpp
    reversegeocodelookupjob.cpp
    filesystemtracker.cpp
)

target_link_libraries(gallery
    Qt5::Quick
    Qt5::Widgets
    Qt5::Qml
    Qt5::Positioning
    KF5::ConfigCore
    KF5::Baloo
    KF5::FileMetaData
    KVariantStore
    gallerycommon
)

install(TARGETS gallery ${INSTALL_TARGETS_DEFAULT_ARGS})

#
# QML Plugin
#
set (qml_plugin_SRCS
    qmlplugins.cpp
    tagmodel.cpp
    imagesmodel.cpp
    imagelocationmodel.cpp
    imagetimemodel.cpp
    imagefoldermodel.cpp
    imagelocationcategorizer.cpp
)

add_library (galleryqmlplugin SHARED ${qml_plugin_SRCS})

target_link_libraries (galleryqmlplugin
    Qt5::Qml
    Qt5::Positioning
    KF5::ConfigCore
    KF5::Baloo
    KF5::FileMetaData
    gallerycommon
    KVariantStore
)

install (TARGETS galleryqmlplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/gallery)
install (FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/gallery)

add_subdirectory(autotest)
