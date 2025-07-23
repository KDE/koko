# SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
# SPDX-License-Identifier: BSD-2-Clause

add_library(photos_thumbnails_static STATIC
    thumbnailitem.cpp
    thumbnailitem.h
    thumbnailmanager.cpp
    thumbnailmanager.h
)

target_link_libraries(photos_thumbnails_static PUBLIC
    Qt::Quick
    KF6::KIOGui
)

ecm_add_qml_module(photos_thumbnails_static
    URI "org.kde.photos.thumbnails"
    GENERATE_PLUGIN_SOURCE
)
