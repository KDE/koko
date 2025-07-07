/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "imagelocationmodel.h"
#include "imagestorage.h"
#include "roles.h"

ImageLocationModel::ImageLocationModel(QObject *parent)
    : QAbstractListModel(parent)
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

QHash<int, QByteArray> ImageLocationModel::roleNames() const
{
    return Roles::roleNames();
}

QVariant ImageLocationModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const QByteArray &key = m_locations.at(index.row()).first;
    const QString &display = m_locations.at(index.row()).second;

    switch (role) {
    case Roles::ContentRole:
        return display;

    case Roles::FilesRole:
        return QVariant::fromValue(ImageStorage::instance()->imagesForLocation(key, m_group));

    case Roles::FileCountRole:
        return ImageStorage::instance()->imagesForLocation(key, m_group).size();

    case Roles::ImageUrlRole:
        return ImageStorage::instance()->imageForLocation(key, m_group);

    case Roles::ItemTypeRole:
        return QVariant::fromValue(ImageStorage::ItemTypes::Album);
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
