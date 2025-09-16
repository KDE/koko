# SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(photos_model2_static STATIC
    abstractgallerymodel.h
    abstractgallerymodel.cpp
    galleryopenmodel.h
    galleryopenmodel.cpp
    galleryfoldermodel.h
    galleryfoldermodel.cpp
    gallerysortfilterproxymodel.h
    gallerysortfilterproxymodel.cpp
)

target_link_libraries(photos_model2_static PUBLIC
    Qt::Quick
    Qt::Qml
    Qt::Sql
    Qt::Positioning
    KF6::KIOCore
    KF6::KIOWidgets # For KDirModel
    KF6::KIOGui
    KF6::GuiAddons
    KF6::CoreAddons
)

ecm_add_qml_module(photos_model2_static
    URI "org.kde.photos.models2"
    GENERATE_PLUGIN_SOURCE
)
