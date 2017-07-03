/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include "imagelocationmodel.h"
#include "imagestorage.h"
#include "types.h"
#include "roles.h"

#include <kio/copyjob.h>
#include <kio/jobuidelegate.h>

ImageLocationModel::ImageLocationModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_group(ImageLocationModel::City)
{
    connect(ImageStorage::instance(), SIGNAL(storageModified()), this, SLOT(slotPopulate()));
}

void ImageLocationModel::slotPopulate()
{
    beginResetModel();
    m_locations = ImageStorage::instance()->locations(static_cast<ImageStorage::LocationGroup>(m_group));
    endResetModel();
}

QHash<int, QByteArray> ImageLocationModel::roleNames() const
{
    auto hash = QAbstractItemModel::roleNames();
    hash.insert( Roles::FilesRole, "files");
    hash.insert( Roles::FileCountRole, "fileCount");
    //the url role returns the url of the cover image of the collection
    hash.insert( Roles::ImageUrlRole, "imageurl");
    hash.insert( Roles::ItemTypeRole, "itemType");

    return hash;
}

QVariant ImageLocationModel::data(const QModelIndex& index, int role) const
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
            auto group = static_cast<ImageStorage::LocationGroup>(m_group);
            return ImageStorage::instance()->imagesForLocation(key, group);
        }

        case Roles::FileCountRole: {
            auto group = static_cast<ImageStorage::LocationGroup>(m_group);
            return ImageStorage::instance()->imagesForLocation(key, group).size();
        }

        case Roles::ImageUrlRole: {
            auto group = static_cast<ImageStorage::LocationGroup>(m_group);
            return ImageStorage::instance()->imageForLocation(key, group);
        }
        
        case Roles::ItemTypeRole: {
            return Types::Album;
        }
    }

    return QVariant();

}

int ImageLocationModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_locations.size();
}

void ImageLocationModel::setGroup(ImageLocationModel::LocationGroup group)
{
    beginResetModel();
    m_group = group;
    m_locations = ImageStorage::instance()->locations(static_cast<ImageStorage::LocationGroup>(group));
    endResetModel();

    emit groupChanged();
}

ImageLocationModel::LocationGroup ImageLocationModel::group() const
{
    return m_group;
}

void ImageLocationModel::removeImage(const QString& path, int index)
{
    Q_UNUSED(index);
    //Removes the file from database
    ImageStorage::instance()->removeImage(path);
    ImageStorage::instance()->commit();
    
    // Removes the file from physical storage to the trash
    KIO::trash(QUrl::fromLocalFile(path));
}
