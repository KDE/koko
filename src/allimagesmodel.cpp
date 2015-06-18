/*
 * Copyright (C) 2015  Vishesh Handa <vhanda@kde.org>
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

#include "allimagesmodel.h"
#include "imagestorage.h"

AllImagesModel::AllImagesModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_images = ImageStorage::instance()->allImages();
    connect(ImageStorage::instance(), SIGNAL(storageModified()), this, SLOT(slotPopulate()));
}

void AllImagesModel::slotPopulate()
{
    beginResetModel();
    m_images = ImageStorage::instance()->allImages();
    endResetModel();
}

QHash<int, QByteArray> AllImagesModel::roleNames() const
{
    auto hash = QAbstractItemModel::roleNames();
    hash.insert(FilePathRole, "filePath");
    hash.insert(FilePathRole, "modelData");

    return hash;
}

QVariant AllImagesModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    QString filePath = m_images.at(index.row());

    switch (role) {
        case Qt::DisplayRole: {
            QString fileName = filePath.mid(filePath.lastIndexOf('/') + 1);
            return fileName;
        }

        case FilePathRole:
            return filePath;
    }

    return QVariant();
}

int AllImagesModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_images.size();
}
