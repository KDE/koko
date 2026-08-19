/*
 *  SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <KLocalizedString>

#include "imagestorage.h"

#include "galleryallimagesmodel.h"

GalleryAllImagesModel::GalleryAllImagesModel(QObject *parent)
    : AbstractGalleryModel(parent)
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &GalleryAllImagesModel::populate);
    populate();
}

QString GalleryAllImagesModel::title() const
{
    return i18nc("@title", "All media");
}

QVariant GalleryAllImagesModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const auto &fileItem = m_fileItems.at(index.row());
    return dataFromFileItem(fileItem, role);
}

int GalleryAllImagesModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_fileItems.size();
}

void GalleryAllImagesModel::populate()
{
    beginResetModel();
    m_fileItems = ImageStorage::instance()->imagesForAll();
    endResetModel();
}
