/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagefavoritesmodel.h"
#include "imagestorage.h"
#include "roles.h"

#include <kio/copyjob.h>
#include <kio/jobuidelegate.h>

ImageFavoritesModel::ImageFavoritesModel(QObject *parent)
    : OpenFileModel({}, parent)
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
