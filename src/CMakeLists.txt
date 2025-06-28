# SPDX-FileCopyrightText: 2014 Vishesh Handa <vhanda@kde.org>
# SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
# SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: LGPL-2.1-or-later

add_subdirectory(models)

add_subdirectory(thumbnails)

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
    filemenu.h
    filemenu.cpp
    dirmodelutils.cpp
    notificationmanager.cpp
    fileinfo.cpp
    displaycolorspace.cpp
    photosapplication.cpp
    photosapplication.h
    devicepixelratiohelper.cpp
    checkerboardimageprovider.cpp
    printerhelper.cpp
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
    KF6::GuiAddons
    KF6::FileMetaData
    KF6::ConfigGui
    KF6::ConfigCore
    KF6::ConfigWidgets
    KF6::I18n
    KF6::I18nQml
    KF6::Notifications
    KirigamiAddonsStatefulApp
    LibExiv2::LibExiv2
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

ecm_target_qml_sources(koko_static PRIVATE PATH editor SOURCES
    qml/editor/AnimatedLoader.qml
    qml/editor/AnnotationsToolBarContents.qml
    qml/editor/ButtonGrid.qml
    qml/editor/EditorView.qml
    qml/editor/UndoRedoGroup.qml
)

ecm_target_qml_sources(koko_static SOURCES
    qml/AlbumDelegate.qml
    qml/AlbumView.qml
    qml/BottomNavBar.qml
    qml/DelegateLoader.qml
    qml/ImageMetadataPage.qml
    qml/ImageViewPage.qml
    qml/InfoDrawer.qml
    qml/InfoDrawerSidebarBase.qml
    qml/InfoSidebar.qml
    qml/Main.qml
    qml/OverviewControl.qml
    qml/PlacesPage.qml
    qml/SelectionButton.qml
    qml/ShareAction.qml
    qml/ShareDialog.qml
    qml/ShareDrawer.qml
    qml/Sidebar.qml
    qml/SlideshowManager.qml
    qml/TagInput.qml
    qml/ThumbnailStrip.qml
    qml/ZoomArea.qml
    qml/Settings/PhotosConfigurationView.qml
    qml/Settings/GeneralConfigPage.qml
)

ecm_target_qml_sources(koko_static PRIVATE
    PATH imagedelegate
    SOURCES
        qml/imagedelegate/AnimatedImageDelegate.qml
        qml/imagedelegate/BaseImageDelegate.qml
        qml/imagedelegate/RasterImageDelegate.qml
        qml/imagedelegate/VectorImageDelegate.qml
        qml/imagedelegate/VideoDelegate.qml
        qml/imagedelegate/VideoPlayer.qml
)

ecm_target_qml_sources(koko_static PRIVATE
    PATH Dialog
    SOURCES
        qml/Dialog/ConfirmDiscardingChange.qml
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
)

install(FILES koko.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})
install(FILES org.kde.koko.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(TARGETS koko ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
