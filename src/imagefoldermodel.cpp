/*
 *   Copyright 2017 by Marco Martin <mart@kde.org>
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * 
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "imagefoldermodel.h"
#include "types.h"
#include "roles.h"

#include <QImage>
#include <QPixmap>
#include <QProcess>
#include <QDebug>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QDir>

#include <kdirlister.h>
#include <KIO/EmptyTrashJob>

ImageFolderModel::ImageFolderModel(QObject *parent)
    : KDirModel(parent)
{
    QMimeDatabase db;
    QList<QMimeType> mimeList = db.allMimeTypes();

    m_mimeTypes << "inode/directory";
    foreach (const QMimeType &mime, mimeList) {
        if (mime.name().startsWith(QStringLiteral("image/"))) {
            m_mimeTypes << mime.name();
        }
    }

    dirLister()->setMimeFilter(m_mimeTypes);

    connect(this, &QAbstractItemModel::rowsInserted,
            this, &ImageFolderModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved,
            this, &ImageFolderModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset,
            this, &ImageFolderModel::countChanged);
}

ImageFolderModel::~ImageFolderModel()
{
}

QHash<int, QByteArray> ImageFolderModel::roleNames() const
{
    return {
        { Qt::DisplayRole, "display" },
        { Qt::DecorationRole, "decoration" },
        { Roles::ImageUrlRole, "imageurl" },
        { Roles::MimeTypeRole, "mimeType" }, 
        { Roles::ItemTypeRole, "itemType"}
    };
}

QString ImageFolderModel::url() const
{
    return dirLister()->url().toString();
}

void ImageFolderModel::setUrl(QString& url)
{
    Q_ASSERT( QUrl(url).isLocalFile());
    url = QUrl(url).path();
    
    if (url.isEmpty()) {
        QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
        Q_ASSERT(locations.size() > 1);
        url = locations.first().append("/");
    }
    
    QString directoryUrl;
    
    if( QDir(url).exists()) {
        directoryUrl = QUrl::fromLocalFile(url).toString();
    } else {
        m_imagePath = url;
        directoryUrl = QUrl::fromLocalFile(url.left(url.lastIndexOf('/'))).toString();
    }
    
    if (dirLister()->url().path() == directoryUrl) {
        dirLister()->updateDirectory(QUrl(directoryUrl));
        return;
    }

    beginResetModel();
    dirLister()->openUrl(QUrl(directoryUrl));
    endResetModel();
    emit urlChanged();
}

int ImageFolderModel::indexForUrl(const QString &url) const
{
    QModelIndex index = KDirModel::indexForUrl(QUrl(url));
    return index.row();
}

QVariantMap ImageFolderModel::get(int i) const
{
    QModelIndex modelIndex = index(i, 0);

    KFileItem item = itemForIndex(modelIndex);
    QString url = item.url().toString();
    QString mimeType = item.mimetype();

    QVariantMap ret;
    ret.insert(QStringLiteral("url"), QVariant(url));
    ret.insert(QStringLiteral("mimeType"), QVariant(mimeType));

    return ret;
}

void ImageFolderModel::emptyTrash()
{
    KIO::emptyTrash();
}

QVariant ImageFolderModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }

    switch (role) {
        case Roles::ImageUrlRole: {
            KFileItem item = itemForIndex(index);
            return item.url().toString();
        }
        case Roles::MimeTypeRole: {
            KFileItem item = itemForIndex(index);
            return item.mimetype();
        }
        
        case Roles::ItemTypeRole: {
            KFileItem item = itemForIndex(index);
            if( item.isDir()) {
                return Types::Folder;
            } else {
                return Types::Image;
            }
    }
    
    default:
        return KDirModel::data(index, role);
    }
}

#include "moc_imagefoldermodel.cpp"
