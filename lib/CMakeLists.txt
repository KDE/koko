set (qml_plugin_SRCS
    qmlplugins.cpp
    tagmodel.cpp
    balooimagefetcher.cpp
    imagesmodel.cpp
)

add_library (galleryqmlplugin SHARED ${qml_plugin_SRCS})

target_link_libraries (galleryqmlplugin
    Qt5::Qml
    KF5::ConfigCore
    KF5::BalooCore
)

install (TARGETS galleryqmlplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/gallery)
install (FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/gallery)
