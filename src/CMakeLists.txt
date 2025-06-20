# SPDX-FileCopyrightText: 2014 Vishesh Handa <vhanda@kde.org>
# SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
# SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: LGPL-2.1-or-later

add_library(koko_static STATIC
    imagestorage.cpp
    exiv2extractor.cpp
    filesystemimagefetcher.cpp
)

target_link_libraries(koko_static PUBLIC
    Qt::Qml
    Qt::Quick
    Qt::Core
    Qt::Positioning
    Qt::Sql
    Qt::Svg
    Qt::QuickControls2
    KF6::CoreAddons
    KF6::KIOCore
    KF6::DBusAddons
    KF6::FileMetaData
    KF6::ConfigGui
    KF6::ConfigCore
    KF6::I18n
    KirigamiAddonsStatefulApp
    LibExiv2::LibExiv2
)

add_executable(koko
    main.cpp
    openfilemodel.cpp
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
    openfilemodel.cpp
    imagelocationmodel.cpp
    imagefavoritesmodel.cpp
    imagetagsmodel.cpp
    imagetimemodel.cpp
    imagefoldermodel.cpp
    sortmodel.cpp
    imagelistmodel.cpp
    notificationmanager.cpp
    types.cpp
    roles.cpp
    fileinfo.cpp
    displaycolorspace.cpp
    photosapplication.cpp
    photosapplication.h
    ${koko_SRCS}
)

kconfig_target_kcfg_file(koko
    FILE kokoconfig.kcfg
    CLASS_NAME Config
    MUTATORS
    GENERATE_PROPERTIES
    GENERATE_MOC
    DEFAULT_VALUE_GETTERS
    SINGLETON
    QML_REGISTRATION
)

target_link_libraries(koko PRIVATE
    koko_static
    Qt::Qml
    Qt::Quick
    Qt::Widgets
    KF6::KIOFileWidgets
    KF6::KIOWidgets
    KF6::GuiAddons
    KF6::I18n
    KF6::I18nQml
    KF6::Notifications
    KF6::ConfigCore
    KF6::CoreAddons
    KF6::ConfigWidgets
)

target_compile_definitions(koko PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)

ecm_add_qml_module(koko
    URI "org.kde.koko"
    GENERATE_PLUGIN_SOURCE
)

ecm_target_qml_sources(koko SOURCES
    qml/AlbumDelegate.qml
    qml/AlbumView.qml
    qml/BottomNavBar.qml
    qml/EditorView.qml
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

ecm_target_qml_sources(koko PRIVATE
    PATH imagedelegate
    SOURCES
        qml/imagedelegate/AnimatedImageDelegate.qml
        qml/imagedelegate/BaseImageDelegate.qml
        qml/imagedelegate/RasterImageDelegate.qml
        qml/imagedelegate/VectorImageDelegate.qml
        qml/imagedelegate/VideoDelegate.qml
        qml/imagedelegate/VideoPlayer.qml
)

ecm_target_qml_sources(koko PRIVATE
    PATH Dialog
    SOURCES
        qml/Dialog/ConfirmDiscardingChange.qml
)

if(ANDROID)
    target_link_libraries(koko PRIVATE Qt::AndroidExtras)
else()
    target_link_libraries(koko PRIVATE KF6::WindowSystem)
endif()

if (TARGET XCB::XCB)
    target_compile_definitions(koko PRIVATE HAVE_X11)
    target_link_libraries(koko PRIVATE XCB::XCB Qt6::GuiPrivate)
endif()

ecm_finalize_qml_module(koko DESTINATION ${KDE_INSTALL_QMLDIR})

add_subdirectory(resources)

install(FILES koko.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})
install(FILES org.kde.koko.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(TARGETS koko ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
