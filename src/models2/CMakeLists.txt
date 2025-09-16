# SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(photos_model2_static STATIC
    common/abstractgallerymodel.h
    common/abstractgallerymodel.cpp
    common/abstractnavigablegallerymodel.h
    common/abstractnavigablegallerymodel.cpp
    common/gallerysortfilterproxymodel.h
    common/gallerysortfilterproxymodel.cpp
    #galleryopenmodel.h
    #galleryopenmodel.cpp
    galleryfoldermodel.h
    galleryfoldermodel.cpp
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

target_include_directories(photos_model2_static
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/common
)

ecm_add_qml_module(photos_model2_static
    URI "org.kde.photos.models2"
    GENERATE_PLUGIN_SOURCE
)
