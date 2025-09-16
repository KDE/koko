/*
 *  SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <KLocalizedString>

#include "imagestorage.h"

#include "galleryfavoritesmodel.h"

GalleryFavoritesModel::GalleryFavoritesModel(QObject *parent)
    : AbstractGalleryModel(parent)
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &GalleryFavoritesModel::populate);
    populate();
}

QString GalleryFavoritesModel::title() const
{
    return i18nc("@title", "Favorites");
}

QVariant GalleryFavoritesModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const auto &fileItem = m_fileItems.at(index.row());
    return dataFromFileItem(fileItem, role);
}

int GalleryFavoritesModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_fileItems.size();
}

void GalleryFavoritesModel::populate()
{
    beginResetModel();
    m_fileItems = ImageStorage::instance()->imagesForFavorites();
    endResetModel();
}
