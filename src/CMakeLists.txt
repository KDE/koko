# SPDX-FileCopyrightText: 2014 Vishesh Handa <vhanda@kde.org>
# SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
# SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: LGPL-2.1-or-later

add_subdirectory(models)

add_subdirectory(thumbnails)
add_subdirectory(editor)

qt_add_library(koko_static STATIC
    exiv2extractor.cpp
    filesystemimagefetcher.cpp
    reversegeocoder.cpp
    filesystemtracker.cpp
    processor.cpp
    committimer.cpp
    imageprocessorrunnable.cpp
    vectorimage.cpp
    controller.cpp
    kdtree.cpp
    filemenuactions.cpp
    dirmodelutils.cpp
    notificationmanager.cpp
    fileinfo.cpp
    displaycolorspace.cpp
    photosapplication.cpp
    photosapplication.h
    devicepixelratiohelper.cpp
    checkerboardimageprovider.cpp
    printerhelper.cpp
    filedialoghelper.cpp
    ocr.cpp
)

kconfig_target_kcfg_file(koko_static
    FILE kokoconfig.kcfg
    CLASS_NAME Config
    MUTATORS
    GENERATE_PROPERTIES
    GENERATE_MOC
    DEFAULT_VALUE_GETTERS
    SINGLETON
    QML_REGISTRATION
)

target_link_libraries(koko_static PUBLIC
    photos_model_static
    photos_thumbnails_static

    Qt::Widgets
    Qt::Core
    Qt::Svg
    Qt::QuickControls2
    KF6::CoreAddons
    KF6::KIOFileWidgets
    KF6::KIOWidgets
    KF6::DBusAddons
    KF6::FileMetaData
    KF6::ConfigGui
    KF6::ConfigCore
    KF6::ConfigWidgets
    KF6::I18n
    KF6::I18nQml
    KF6::Notifications
    KirigamiAddonsStatefulApp
    LibExiv2::LibExiv2
    KQuickImageEditor
    ${LibTesseract_LIBRARIES}
)

if(Qt6PrintSupport_FOUND)
    target_compile_definitions(koko_static PUBLIC HAVE_PRINTSUPPORT)
    target_link_libraries(koko_static PUBLIC Qt::PrintSupport)
endif()

ecm_add_qml_module(koko_static
    URI "org.kde.koko"
    GENERATE_PLUGIN_SOURCE
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/src/org/kde/koko
    IMPORTS
        org.kde.photos.models
        org.kde.photos.thumbnails
    DEPENDENCIES
        QtCore
        QtQml
        QtQuick
        org.kde.kirigamiaddons.statefulapp
)

ecm_target_qml_sources(koko_static SOURCES
    qml/gallery/GalleryPage.qml
    qml/gallery/GalleryDelegate.qml
    qml/gallery/NavigatorComponent.qml
    qml/gallery/NavigatorPathButton.qml

    qml/mediaview/MediaViewPage.qml
    qml/mediaview/MediaViewThumbnail.qml
    qml/mediaview/DelegateLoader.qml
    qml/mediaview/ThumbnailStrip.qml
    qml/mediaview/OverviewControl.qml
    qml/mediaview/SlideshowManager.qml
    qml/mediaview/InfoDrawer.qml
    qml/mediaview/InfoDrawerSidebarBase.qml
    qml/mediaview/InfoSidebar.qml
    qml/mediaview/MediaMetadataPage.qml
    qml/mediaview/TagInput.qml

    qml/mediaview/imagedelegate/ZoomArea.qml
    qml/mediaview/imagedelegate/AnimatedImageDelegate.qml
    qml/mediaview/imagedelegate/BaseImageDelegate.qml
    qml/mediaview/imagedelegate/RasterImageDelegate.qml
    qml/mediaview/imagedelegate/VectorImageDelegate.qml
    qml/mediaview/imagedelegate/VideoDelegate.qml
    qml/mediaview/imagedelegate/VideoPlayer.qml

    qml/BottomNavBar.qml
    qml/Main.qml
    qml/OcrResultDelegate.qml
    qml/PlacesPage.qml
    qml/ShareAction.qml
    qml/ShareDialog.qml
    qml/ShareMenu.qml
    qml/Sidebar.qml
    qml/Settings/PhotosConfigurationView.qml
    qml/Settings/GeneralConfigPage.qml
    qml/Settings/OcrConfigPage.qml
)

if(ANDROID)
    target_link_libraries(koko_static PUBLIC Qt::AndroidExtras)
else()
    target_link_libraries(koko_static PUBLIC KF6::WindowSystem)
endif()

if (TARGET XCB::XCB)
    target_compile_definitions(koko_static PUBLIC HAVE_X11)
    target_link_libraries(koko_static PUBLIC XCB::XCB Qt6::GuiPrivate)
endif()

add_subdirectory(resources)

add_executable(koko
    main.cpp
)

target_link_libraries(koko PRIVATE
    koko_static
    koko_staticplugin
    photos_model_staticplugin
    photos_thumbnails_staticplugin
    photos_editor_static
    photos_editor_staticplugin
)

install(FILES koko.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})
install(FILES org.kde.koko.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(TARGETS koko ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
