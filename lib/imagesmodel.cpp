/*
 * <one line to give the library's name and an idea of what it does.>
 * Copyright (C) 2014  Vishesh Handa <me@vhanda.in>
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

#include "imagesmodel.h"
#include "balooimagefetcher.h"

#include <QFileInfo>

ImagesModel::ImagesModel(QObject* parent)
    : QAbstractListModel(parent)
{
    BalooImageFetcher* fetcher = new BalooImageFetcher(this);

    auto func = [&](const QString& path) {
        beginInsertRows(QModelIndex(), m_images.size(), m_images.size());
        m_images << path;
        endInsertRows();
    };
    connect(fetcher, &BalooImageFetcher::imageFile, this, func);
    fetcher->fetchAllImages();
}

QHash<int, QByteArray> ImagesModel::roleNames() const
{
    auto hash = QAbstractItemModel::roleNames();
    hash.insert(FilePathRole, "filePath");

    return hash;
}

QVariant ImagesModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    QString filePath = m_images.at(index.row());

    switch (role) {
        case Qt::DisplayRole:
            return QFileInfo(filePath).fileName();

        case FilePathRole:
            return filePath;
    }

    return QVariant();
}

int ImagesModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_images.size();
}
