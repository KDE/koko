/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagefavoritesmodel.h"
#include "imagestorage.h"

#include <KIO/CopyJob>

ImageFavoritesModel::ImageFavoritesModel(QObject *parent)
    : AbstractImageModel(parent)
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageFavoritesModel::slotPopulate);
    slotPopulate();
}

void ImageFavoritesModel::slotPopulate()
{
    beginResetModel();
    m_images = ImageStorage::instance()->imagesForFavorites();
    endResetModel();
}

QVariant ImageFavoritesModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));
    return dataFromItem(m_images.at(index.row()), role);
}

int ImageFavoritesModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_images.size();
}
