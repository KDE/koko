/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
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
