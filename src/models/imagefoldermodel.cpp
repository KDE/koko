/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * SPDX-FileCopyrightText: (C) 2017 by Marco Martin <mart@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagefoldermodel.h"
#include "imagestorage.h"

#include <QDebug>
#include <QDir>
#include <QImage>
#include <QMimeDatabase>
#include <QPixmap>
#include <QProcess>
#include <QStandardPaths>

#include <KDirLister>
#include <KDirModel>
#include <KIO/EmptyTrashJob>

using namespace Qt::StringLiterals;

ImageFolderModel::ImageFolderModel(QObject *parent)
    : AbstractImageModel(parent)
    , m_dirModel(new KDirModel(this))
{
    QMimeDatabase db;
    const QList<QMimeType> mimeList = db.allMimeTypes();

    m_mimeTypes << "inode/directory";
    for (const auto &mime : mimeList) {
        const auto mimeName = mime.name();
        if (mimeName.startsWith("image/"_L1) || mimeName.startsWith("video/"_L1)) {
            m_mimeTypes << mime.name();
        }
    }

    m_dirModel->dirLister()->setMimeFilter(m_mimeTypes);

    connect(m_dirModel, &KDirModel::rowsAboutToBeInserted, this, &ImageFolderModel::rowsAboutToBeInserted);
    connect(m_dirModel, &KDirModel::rowsAboutToBeMoved, this, &ImageFolderModel::rowsAboutToBeMoved);
    connect(m_dirModel, &KDirModel::rowsAboutToBeRemoved, this, &ImageFolderModel::rowsAboutToBeRemoved);
    connect(m_dirModel, &KDirModel::rowsInserted, this, &ImageFolderModel::rowsInserted);
    connect(m_dirModel, &KDirModel::rowsMoved, this, &ImageFolderModel::rowsMoved);
    connect(m_dirModel, &KDirModel::rowsRemoved, this, &ImageFolderModel::rowsRemoved);
    connect(m_dirModel, &KDirModel::modelReset, this, &ImageFolderModel::modelReset);
    connect(m_dirModel, &KDirModel::modelAboutToBeReset, this, &ImageFolderModel::modelAboutToBeReset);
    connect(m_dirModel, &KDirModel::layoutChanged, this, &ImageFolderModel::layoutChanged);
    connect(m_dirModel, &KDirModel::layoutAboutToBeChanged, this, &ImageFolderModel::layoutAboutToBeChanged);
    connect(m_dirModel->dirLister(), &KDirLister::completed, this, &ImageFolderModel::finishedLoading);
}

QUrl ImageFolderModel::url() const
{
    return m_dirModel->dirLister()->url();
}

void ImageFolderModel::setUrl(const QUrl &url)
{
    QUrl newUrl = url;
    if (url.isEmpty()) {
        const QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
        Q_ASSERT(locations.size() >= 1);
        newUrl = QUrl::fromLocalFile(locations.constFirst() + u'/');
    }

    if (m_dirModel->dirLister()->url() == newUrl) {
        m_dirModel->dirLister()->updateDirectory(newUrl);
        return;
    }

    m_dirModel->openUrl(newUrl);

    Q_EMIT urlChanged();
}

int ImageFolderModel::indexForUrl(const QString &url) const
{
    for (int row = 0; row < rowCount(); ++row) {
        QModelIndex idx = index(row, 0);
        if (data(idx, AbstractImageModel::ImageUrlRole).toString() == url) {
            return row;
        }
    }

    return -1;
}

QVariantMap ImageFolderModel::get(int i) const
{
    QModelIndex modelIndex = index(i, 0);

    const KFileItem &item = m_items.at(modelIndex.row());
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

    return dataFromItem(m_dirModel->index(index.row(), 0).data(KDirModel::FileItemRole).value<KFileItem>(), role);
}

int ImageFolderModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_dirModel->rowCount();
}
