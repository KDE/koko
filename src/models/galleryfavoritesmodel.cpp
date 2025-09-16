/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
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
