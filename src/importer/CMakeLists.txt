# SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(koko_importer_static STATIC
    deviceimagemodel.cpp
    deviceimagemodel.h
    documentdirfinder.cpp
    documentdirfinder.h
    importerhelper.cpp
    importerhelper.h
    mimetypeutils.cpp
    mimetypeutils.h
)

ecm_add_qml_module(koko_importer_static
    URI "org.kde.koko.importer"
    GENERATE_PLUGIN_SOURCE
)

ecm_target_qml_sources(koko_importer_static SOURCES
    ImportWindow.qml
    DevicePhotosPage.qml
)

target_link_libraries(koko_importer_static PUBLIC
    Qt::Gui
    KF6::KIOCore
    KF6::I18n
)
