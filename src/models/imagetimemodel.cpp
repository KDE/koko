/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "imagetimemodel.h"
#include "roles.h"

ImageTimeModel::ImageTimeModel(QObject *parent)
    : QAbstractListModel(parent)
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

QHash<int, QByteArray> ImageTimeModel::roleNames() const
{
    return Roles::roleNames();
}

QVariant ImageTimeModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const QByteArray key = m_times.at(index.row()).first;

    switch (role) {
    case Roles::ContentRole:
        return m_times.at(index.row()).second;

    case Roles::FilesRole:
        return QVariant::fromValue(ImageStorage::instance()->imagesForTime(key, m_group));

    case Roles::FileCountRole:
        return ImageStorage::instance()->imagesForTime(key, m_group).size();

    case Roles::ImageUrlRole:
        return ImageStorage::instance()->imageForTime(key, m_group);

    case Roles::DateRole:
        return ImageStorage::instance()->dateForKey(key, m_group);

    case Roles::ItemTypeRole:
        return QVariant::fromValue(ImageStorage::ItemTypes::Album);
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
