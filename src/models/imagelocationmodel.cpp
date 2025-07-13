/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "imagelocationmodel.h"
#include "imagestorage.h"

ImageLocationModel::ImageLocationModel(QObject *parent)
    : AbstractImageModel(parent)
    , m_group(ImageStorage::LocationGroup::City)
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageLocationModel::slotPopulate);
}

void ImageLocationModel::slotPopulate()
{
    beginResetModel();
    m_locations = ImageStorage::instance()->locations(m_group);
    endResetModel();
}

QVariant ImageLocationModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const auto &collection = m_locations.at(index.row());

    switch (role) {
    case ContentRole:
        return collection.display;

    case FilesRole:
        return QVariant::fromValue(ImageStorage::instance()->imagesForLocation(collection.key, m_group));

    case FileCountRole:
        return ImageStorage::instance()->imagesForLocation(collection.key, m_group).size();

    case ItemRole:
        return ImageStorage::instance()->imageForLocation(collection, m_group).url();

    case ImageUrlRole:
        return ImageStorage::instance()->imageForLocation(collection, m_group).url().toLocalFile();

    case ItemTypeRole:
        return ItemType::Collection;

    case ThumbnailRole:
        return thumbnailForItem(ImageStorage::instance()->imageForLocation(collection, m_group));
    }

    return {};
}

int ImageLocationModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_locations.size();
}

void ImageLocationModel::setGroup(ImageStorage::LocationGroup group)
{
    if (m_group == group) {
        return;
    }

    beginResetModel();
    m_group = group;
    m_locations = ImageStorage::instance()->locations(group);
    endResetModel();

    Q_EMIT groupChanged();
}

ImageStorage::LocationGroup ImageLocationModel::group() const
{
    return m_group;
}
