/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "imagetimemodel.h"
#include "imagestorage.h"
#include "roles.h"

#include <kio/copyjob.h>
#include <kio/jobuidelegate.h>

ImageTimeModel::ImageTimeModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_group(Types::TimeGroup::Day)
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageTimeModel::slotPopulate);
}

void ImageTimeModel::slotPopulate()
{
    beginResetModel();
    auto tg = static_cast<Types::TimeGroup>(m_group);
    m_times = ImageStorage::instance()->timeTypes(tg);
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

    case Roles::FilesRole: {
        const auto tg = static_cast<Types::TimeGroup>(m_group);
        return ImageStorage::instance()->imagesForTime(key, tg);
    }

    case Roles::FileCountRole: {
        const auto tg = static_cast<Types::TimeGroup>(m_group);
        return ImageStorage::instance()->imagesForTime(key, tg).size();
    }

    case Roles::ImageUrlRole: {
        const auto tg = static_cast<Types::TimeGroup>(m_group);
        return ImageStorage::instance()->imageForTime(key, tg);
    }

    case Roles::DateRole: {
        const auto tg = static_cast<Types::TimeGroup>(m_group);
        return ImageStorage::instance()->dateForKey(key, tg);
    }

    case Roles::ItemTypeRole: {
        return Types::Album;
    }
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

Types::TimeGroup ImageTimeModel::group() const
{
    return m_group;
}

void ImageTimeModel::setGroup(Types::TimeGroup group)
{
    beginResetModel();
    m_group = group;

    auto tg = static_cast<Types::TimeGroup>(m_group);
    m_times = ImageStorage::instance()->timeTypes(tg);
    endResetModel();

    emit groupChanged();
}
