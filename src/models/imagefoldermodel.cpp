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

#include <KCoreDirLister>
#include <KIO/EmptyTrashJob>

ImageFolderModel::ImageFolderModel(QObject *parent)
    : AbstractImageModel(parent)
    , m_dirLister(new KCoreDirLister(this))
{
    QMimeDatabase db;
    QList<QMimeType> mimeList = db.allMimeTypes();

    m_mimeTypes << "inode/directory";
    for (auto &mime : std::as_const(mimeList)) {
        if (mime.name().startsWith(QStringLiteral("image/")) || mime.name().startsWith(QStringLiteral("video/"))) {
            m_mimeTypes << mime.name();
        }
    }

    m_dirLister->setMimeFilter(m_mimeTypes);

    connect(m_dirLister, &KCoreDirLister::newItems, this, [this](const KFileItemList &items) {
        beginInsertRows({}, m_items.size(), m_items.size() + items.size() - 1);
        m_items << items;
        endInsertRows();
    });
    connect(m_dirLister, &KCoreDirLister::clear, this, [this] {
        beginResetModel();
        m_items.clear();
        endResetModel();
    });
}

QUrl ImageFolderModel::url() const
{
    return m_dirLister->url();
}

void ImageFolderModel::setUrl(const QUrl &url)
{
    QUrl newUrl = url;
    if (url.isEmpty()) {
        const QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
        Q_ASSERT(locations.size() >= 1);
        newUrl = QUrl::fromLocalFile(locations.constFirst() + u'/');
    }

    if (m_dirLister->url() == newUrl) {
        m_dirLister->updateDirectory(newUrl);
        return;
    }

    m_dirLister->openUrl(newUrl);

    Q_EMIT urlChanged();
}

int ImageFolderModel::indexForUrl(const QString &url) const
{
    int i = 0;
    KFileItem itemComp(QUrl(url), {});
    itemComp.setDelayedMimeTypes(true);

    for (const auto &item : m_items) {
        if (item == itemComp) {
            return i;
        }
        i++;
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
    return dataFromItem(m_items.at(index.row()), role);
}

int ImageFolderModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}
