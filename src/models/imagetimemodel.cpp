/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "imagetimemodel.h"

ImageTimeModel::ImageTimeModel(QObject *parent)
    : AbstractImageModel(parent)
    , m_group(ImageStorage::TimeGroup::Day)
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageTimeModel::slotPopulate);
    slotPopulate();
}

void ImageTimeModel::slotPopulate()
{
    beginResetModel();
    m_times = ImageStorage::instance()->timeTypes(m_group);
    endResetModel();
}

QVariant ImageTimeModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const auto &collection = m_times.at(index.row());

    switch (role) {
    case ContentRole:
        return collection.display;

    case FilesRole:
        return QVariant::fromValue(ImageStorage::instance()->imagesForTime(collection.key, m_group));

    case FileCountRole:
        return ImageStorage::instance()->imagesForTime(collection.key, m_group).size();

    case ImageUrlRole:
        return ImageStorage::instance()->imageForTime(collection, m_group).url();

    case ItemRole:
        return ImageStorage::instance()->imageForTime(collection, m_group);

    case DateRole:
        return ImageStorage::instance()->dateForCollection(collection, m_group);

    case ItemTypeRole:
        return ItemType::Collection;

    case ThumbnailRole:
        return thumbnailForItem(ImageStorage::instance()->imageForTime(collection, m_group));
    }

    return {};
}

int ImageTimeModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_times.size();
}

ImageStorage::TimeGroup ImageTimeModel::group() const
{
    return m_group;
}

void ImageTimeModel::setGroup(ImageStorage::TimeGroup group)
{
    if (m_group == group) {
        return;
    }

    beginResetModel();
    m_group = group;
    m_times = ImageStorage::instance()->timeTypes(m_group);
    endResetModel();

    Q_EMIT groupChanged();
}
