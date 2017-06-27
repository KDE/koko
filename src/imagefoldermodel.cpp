/*
 *   Copyright 2017 by Marco Martin <mart@kde.org>

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

#include <QImage>
#include <QPixmap>
#include <QTimer>
#include <QProcess>
#include <QDebug>
#include <QMimeDatabase>
#include <QStandardPaths>

#include <kdirlister.h>
#include <kio/previewjob.h>
#include <KIO/EmptyTrashJob>
#include <kimagecache.h>

ImageFolderModel::ImageFolderModel(QObject *parent)
    : KDirModel(parent),
      m_screenshotSize(256, 256)
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


    m_previewTimer = new QTimer(this);
    m_previewTimer->setSingleShot(true);
    connect(m_previewTimer, &QTimer::timeout,
            this, &ImageFolderModel::delayedPreview);

    //using the same cache of the engine, they index both by url
    m_imageCache = new KImageCache(QStringLiteral("org.kde.koko"), 10485760);

    connect(this, &QAbstractItemModel::rowsInserted,
            this, &ImageFolderModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved,
            this, &ImageFolderModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset,
            this, &ImageFolderModel::countChanged);

    //TODO: don't hardcode this
    QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
    Q_ASSERT(locations.size() >= 1);
    qDebug() << locations;

    setUrl("file://"+locations.first());
}

ImageFolderModel::~ImageFolderModel()
{
    delete m_imageCache;
}

QHash<int, QByteArray> ImageFolderModel::roleNames() const
{
    return {
        { Qt::DisplayRole, "display" },
        { Qt::DecorationRole, "decoration" },
        { UrlRole, "url" },
        { MimeTypeRole, "mimeType" },
        { Thumbnail, "thumbnail" },
        { SelectedRole, "selected" }
    };
}

QString ImageFolderModel::url() const
{
    return dirLister()->url().toString();
}

void ImageFolderModel::setUrl(const QString& url)
{
    if (url.isEmpty()) {
        return;
    }
    if (dirLister()->url().path() == url) {
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
    case UrlRole: {
        KFileItem item = itemForIndex(index);
        return item.url().toString();
    }
    case MimeTypeRole: {
        KFileItem item = itemForIndex(index);
        return item.mimetype();
    }
    case Thumbnail: {
        KFileItem item = itemForIndex(index);
        QImage preview = QImage(m_screenshotSize, QImage::Format_ARGB32_Premultiplied);

        if (m_imageCache->findImage(item.url().toString(), &preview)) {
            return preview;
        }

        m_previewTimer->start(100);
        const_cast<ImageFolderModel *>(this)->m_filesToPreview[item.url()] = QPersistentModelIndex(index);
    }
    //TODO: implement selection
    case SelectedRole:
        return false;
    default:
        return KDirModel::data(index, role);
    }
}

void ImageFolderModel::delayedPreview()
{
    QHash<QUrl, QPersistentModelIndex>::const_iterator i = m_filesToPreview.constBegin();

    KFileItemList list;

    while (i != m_filesToPreview.constEnd()) {
        QUrl file = i.key();
        QPersistentModelIndex index = i.value();


        if (!m_previewJobs.contains(file) && file.isValid()) {
            list.append(KFileItem(file, QString(), 0));
            m_previewJobs.insert(file, QPersistentModelIndex(index));
        }

        ++i;
    }

    if (list.size() > 0) {
        KIO::PreviewJob* job = KIO::filePreview(list, m_screenshotSize);
        job->setIgnoreMaximumSize(true);
        // qDebug() << "Created job" << job;
        connect(job, &KIO::PreviewJob::gotPreview,
                this, &ImageFolderModel::showPreview);
        connect(job, &KIO::PreviewJob::failed,
                this, &ImageFolderModel::previewFailed);
    }

    m_filesToPreview.clear();
}

void ImageFolderModel::showPreview(const KFileItem &item, const QPixmap &preview)
{
    QPersistentModelIndex index = m_previewJobs.value(item.url());
    m_previewJobs.remove(item.url());

    if (!index.isValid()) {
        return;
    }

    m_imageCache->insertImage(item.url().toString(), preview.toImage());
    //qDebug() << "preview size:" << preview.size();
    emit dataChanged(index, index);
}

void ImageFolderModel::previewFailed(const KFileItem &item)
{
    m_previewJobs.remove(item.url());
}

#include "moc_imagefoldermodel.cpp"
