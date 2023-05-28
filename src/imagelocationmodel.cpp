/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "imagelocationmodel.h"
#include "imagestorage.h"
#include "roles.h"

#include <kio/copyjob.h>
#include <kio/jobuidelegate.h>

ImageLocationModel::ImageLocationModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_group(Types::LocationGroup::City)
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageLocationModel::slotPopulate);
}

void ImageLocationModel::slotPopulate()
{
    beginResetModel();
    m_locations = ImageStorage::instance()->locations(static_cast<Types::LocationGroup>(m_group));
    endResetModel();
}

QHash<int, QByteArray> ImageLocationModel::roleNames() const
{
    return Roles::roleNames();
}

QVariant ImageLocationModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const QByteArray key = m_locations.at(index.row()).first;
    const QString display = m_locations.at(index.row()).second;

    switch (role) {
    case Roles::ContentRole:
        return display;

    case Roles::FilesRole: {
        const auto group = static_cast<Types::LocationGroup>(m_group);
        return ImageStorage::instance()->imagesForLocation(key, group);
    }

    case Roles::FileCountRole: {
        const auto group = static_cast<Types::LocationGroup>(m_group);
        return ImageStorage::instance()->imagesForLocation(key, group).size();
    }

    case Roles::ImageUrlRole: {
        const auto group = static_cast<Types::LocationGroup>(m_group);
        return ImageStorage::instance()->imageForLocation(key, group);
    }

    case Roles::ItemTypeRole: {
        return Types::Album;
    }
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

void ImageLocationModel::setGroup(Types::LocationGroup group)
{
    beginResetModel();
    m_group = group;
    m_locations = ImageStorage::instance()->locations(static_cast<Types::LocationGroup>(group));
    endResetModel();

    emit groupChanged();
}

Types::LocationGroup ImageLocationModel::group() const
{
    return m_group;
}
