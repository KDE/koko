/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 by Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagefoldermodel.h"
#include "roles.h"
#include "types.h"

#include <QDebug>
#include <QDir>
#include <QImage>
#include <QMimeDatabase>
#include <QPixmap>
#include <QProcess>
#include <QStandardPaths>

#include <KIO/EmptyTrashJob>
#include <kdirlister.h>

ImageFolderModel::ImageFolderModel(QObject *parent)
    : KDirModel(parent)
{
    QMimeDatabase db;
    QList<QMimeType> mimeList = db.allMimeTypes();

    m_mimeTypes << "inode/directory";
    for (auto &mime : qAsConst(mimeList)) {
        if (mime.name().startsWith(QStringLiteral("image/")) || mime.name().startsWith(QStringLiteral("video/"))) {
            m_mimeTypes << mime.name();
        }
    }

    dirLister()->setMimeFilter(m_mimeTypes);

    connect(this, &QAbstractItemModel::rowsInserted, this, &ImageFolderModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &ImageFolderModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &ImageFolderModel::countChanged);
}

ImageFolderModel::~ImageFolderModel()
{
}

QHash<int, QByteArray> ImageFolderModel::roleNames() const
{
    return {{Qt::DisplayRole, "display"},
            {Qt::DecorationRole, "decoration"},
            {Roles::ImageUrlRole, "imageurl"},
            {Roles::MimeTypeRole, "mimeType"},
            {Roles::ItemTypeRole, "itemType"}};
}

QUrl ImageFolderModel::url() const
{
    return dirLister()->url();
}

void ImageFolderModel::setUrl(QUrl &url)
{
    if (url.isEmpty()) {
        QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
        Q_ASSERT(locations.size() >= 1);
        url = QUrl::fromLocalFile(locations.first().append("/"));
    }

    if (dirLister()->url() == url) {
        dirLister()->updateDirectory(QUrl(url));
        return;
    }

    beginResetModel();
    dirLister()->openUrl(QUrl(url));
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
        if (item.isDir()) {
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
