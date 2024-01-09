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
    for (auto &mime : std::as_const(mimeList)) {
        if (mime.name().startsWith(QStringLiteral("image/")) || mime.name().startsWith(QStringLiteral("video/"))) {
            m_mimeTypes << mime.name();
        }
    }

    dirLister()->setMimeFilter(m_mimeTypes);

    connect(this, &QAbstractItemModel::rowsInserted, this, &ImageFolderModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &ImageFolderModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &ImageFolderModel::countChanged);
    // we need the complete one, not the qurl one
    connect(dirLister(), QOverload<>::of(&KCoreDirLister::completed), this, &ImageFolderModel::jobFinished);
}

void ImageFolderModel::jobFinished()
{
    if (dirLister()->isFinished()) {
        Q_EMIT finishedLoading();
    }
}

QHash<int, QByteArray> ImageFolderModel::roleNames() const
{
    return Roles::roleNames();
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
    Q_EMIT urlChanged();
}

int ImageFolderModel::indexForUrl(const QString &url) const
{
    return KDirModel::indexForUrl(QUrl(url)).row();
}

QVariantMap ImageFolderModel::get(int i) const
{
    QModelIndex modelIndex = index(i, 0);

    KFileItem item = itemForIndex(modelIndex);
    const QString url = item.url().toString();
    const QString mimeType = item.mimetype();

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
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

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

    case Roles::SelectedRole:
        return false;

    case Roles::ContentRole:
        return KDirModel::data(index, Qt::DisplayRole);

    default:
        return KDirModel::data(index, role);
    }
}
