/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "allimagesmodel.h"
#include "imagestorage.h"

AllImagesModel::AllImagesModel(QObject *parent)
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
    return {
        {FilePathRole, "filePath"},
        {ContentRole, "content"},
    };
}

QVariant AllImagesModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const QString filePath = m_images.at(index.row());

    switch (role) {
    case ContentRole: {
        const QString fileName = filePath.mid(filePath.lastIndexOf('/') + 1);
        return fileName;
    }

    case FilePathRole:
        return filePath;
    }

    return {};
}

int AllImagesModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_images.size();
}
