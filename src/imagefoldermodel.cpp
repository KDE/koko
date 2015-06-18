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

#include "imagefoldermodel.h"
#include "imagestorage.h"

ImageFolderModel::ImageFolderModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_folders = ImageStorage::instance()->folders();
    connect(ImageStorage::instance(), SIGNAL(storageModified()), this, SLOT(slotPopulate()));
}

void ImageFolderModel::slotPopulate()
{
    beginResetModel();
    m_folders = ImageStorage::instance()->folders();
    endResetModel();
}

QHash<int, QByteArray> ImageFolderModel::roleNames() const
{
    auto hash = QAbstractItemModel::roleNames();
    hash.insert(FilesRole, "files");
    hash.insert(FileCountRole, "fileCount");
    hash.insert(CoverRole, "cover");

    return hash;
}

QVariant ImageFolderModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    QByteArray key = m_folders.at(index.row()).first;
    QString display = m_folders.at(index.row()).second;

    switch (role) {
        case Qt::DisplayRole:
            return display;

        case FilesRole:
            return ImageStorage::instance()->imagesForFolders(key);

        case FileCountRole:
            return ImageStorage::instance()->imagesForFolders(key).size();

        case CoverRole:
            return ImageStorage::instance()->imageForFolders(key);
    }

    return QVariant();

}

int ImageFolderModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_folders.size();
}
