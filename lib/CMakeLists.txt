set (qml_plugin_SRCS
    qmlplugins.cpp
    tagmodel.cpp
    balooimagefetcher.cpp
    imagesmodel.cpp
    reversegeocodelookupjob.cpp
    imagelocationmodel.cpp
    imagelocationcategorizer.cpp
    imagestorage.cpp
)

add_library (galleryqmlplugin SHARED ${qml_plugin_SRCS})

target_link_libraries (galleryqmlplugin
    Qt5::Qml
    Qt5::Positioning
    KF5::ConfigCore
    KF5::Baloo
    KF5::FileMetaData
)

install (TARGETS galleryqmlplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/gallery)
install (FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/gallery)

add_subdirectory(autotest)
