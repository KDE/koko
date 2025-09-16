# SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(photos_model_static STATIC
    abstractgallerymodel.h
    abstractgallerymodel.cpp
    abstractnavigablegallerymodel.h
    abstractnavigablegallerymodel.cpp
    gallerysortfilterproxymodel.h
    gallerysortfilterproxymodel.cpp
    mediaviewfiltermodel.h
    mediaviewfiltermodel.cpp
    imagestorage.h
    imagestorage.cpp
    galleryopenmodel.h
    galleryopenmodel.cpp
    galleryfoldermodel.h
    galleryfoldermodel.cpp
    galleryfavoritesmodel.h
    galleryfavoritesmodel.cpp
    gallerytagsmodel.h
    gallerytagsmodel.cpp
    gallerytimemodel.h
    gallerytimemodel.cpp
    gallerylocationmodel.h
    gallerylocationmodel.cpp
)

target_link_libraries(photos_model_static PUBLIC
    Qt::Quick
    Qt::Qml
    Qt::Sql
    Qt::Positioning
    KF6::KIOCore
    KF6::KIOWidgets # For KDirModel
    KF6::KIOGui
    KF6::CoreAddons
    KF6::I18n
)

ecm_add_qml_module(photos_model_static
    URI "org.kde.photos.models"
    GENERATE_PLUGIN_SOURCE
)
