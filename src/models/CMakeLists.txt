# SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(photos_model_static STATIC
    abstractimagemodel.cpp
    abstractimagemodel.h
    imagefavoritesmodel.cpp
    imagefavoritesmodel.h
    imagefoldermodel.cpp
    imagefoldermodel.h
    imagegroupmodel.cpp
    imagegroupmodel.h
    imagelocationmodel.cpp
    imagelocationmodel.h
    imagestorage.cpp
    imagestorage.h
    imagetagsmodel.cpp
    imagetagsmodel.h
    imagetimemodel.cpp
    imagetimemodel.h
    openfilemodel.cpp
    openfilemodel.h
    roles.cpp
    roles.h
    sortmodel.cpp
    sortmodel.h
)

target_link_libraries(photos_model_static PUBLIC
    Qt::Quick
    Qt::Qml
    Qt::Sql
    Qt::Positioning
    KF6::KIOCore
    KF6::KIOWidgets # for KDirModel
    KF6::GuiAddons
    KF6::CoreAddons
)

ecm_add_qml_module(photos_model_static
    URI "org.kde.photos.models"
    GENERATE_PLUGIN_SOURCE
)
