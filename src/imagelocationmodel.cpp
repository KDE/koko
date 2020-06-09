/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
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
    connect(ImageStorage::instance(), SIGNAL(storageModified()), this, SLOT(slotPopulate()));
}

void ImageLocationModel::slotPopulate()
{
    beginResetModel();
    m_locations = ImageStorage::instance()->locations(static_cast<Types::LocationGroup>(m_group));
    endResetModel();
}

QHash<int, QByteArray> ImageLocationModel::roleNames() const
{
    auto hash = QAbstractItemModel::roleNames();
    hash.insert(Roles::FilesRole, "files");
    hash.insert(Roles::FileCountRole, "fileCount");
    // the url role returns the url of the cover image of the collection
    hash.insert(Roles::ImageUrlRole, "imageurl");
    hash.insert(Roles::ItemTypeRole, "itemType");

    return hash;
}

QVariant ImageLocationModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    QByteArray key = m_locations.at(index.row()).first;
    QString display = m_locations.at(index.row()).second;

    switch (role) {
    case Qt::DisplayRole:
        return display;

    case Roles::FilesRole: {
        auto group = static_cast<Types::LocationGroup>(m_group);
        return ImageStorage::instance()->imagesForLocation(key, group);
    }

    case Roles::FileCountRole: {
        auto group = static_cast<Types::LocationGroup>(m_group);
        return ImageStorage::instance()->imagesForLocation(key, group).size();
    }

    case Roles::ImageUrlRole: {
        auto group = static_cast<Types::LocationGroup>(m_group);
        return ImageStorage::instance()->imageForLocation(key, group);
    }

    case Roles::ItemTypeRole: {
        return Types::Album;
    }
    }

    return QVariant();
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
