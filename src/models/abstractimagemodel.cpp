// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "abstractimagemodel.h"

#include <QFileInfo>
#include <QIcon>
#include <QMimeDatabase>
#include <QTimer>

#include <KIO/PreviewJob>

using namespace Qt::StringLiterals;

AbstractImageModel::AbstractImageModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_screenshotSize(256, 256)
    , m_itemData(5000)
{
    m_previewTimer = new QTimer(this);
    m_previewTimer->setSingleShot(true);
    connect(m_previewTimer, &QTimer::timeout, this, &AbstractImageModel::delayedPreview);
}

QHash<int, QByteArray> AbstractImageModel::roleNames() const
{
    return {
        {Qt::DecorationRole, "decoration"},
        {FilesRole, "files"},
        {FileCountRole, "fileCount"},
        {ImageUrlRole, "imageurl"},
        {DateRole, "date"},
        {MimeTypeRole, "mimeType"},
        {ItemTypeRole, "itemType"},
        {ContentRole, "content"},
        {SelectedRole, "selected"},
        {ItemRole, "item"},
        {ThumbnailRole, "thumbnail"},
    };
}

QVariant AbstractImageModel::dataFromItem(const KFileItem &item, int role) const
{
    switch (role) {
    case ItemRole:
        return item;
    case ContentRole:
        return item.name();
    case ImageUrlRole:
        return item.url();
    case ItemTypeRole:
        return item.isDir() ? ItemType::Folder : ItemType::Image;
    case MimeTypeRole:
        return item.mimetype();
    case SelectedRole:
        return false;
    case ThumbnailRole:
        return thumbnailForItem(item);
    default:
        return {};
    }
}

QVariant AbstractImageModel::thumbnailForItem(const KFileItem &item) const
{
    const auto thumbnailSource = item.url();
    if (m_itemData.contains(thumbnailSource)) {
        const auto pixmap = m_itemData[thumbnailSource]->thumbnail;
        if (pixmap.isNull()) {
            Q_ASSERT_X(false, Q_FUNC_INFO, "At that point we should have a thumbnail");
            return false;
        }
        return pixmap;
    }

    if (!m_filesInPreviewGeneration.contains(thumbnailSource) && !m_filesToPreview.contains(item)) {
        if (!item.isMimeTypeKnown()) {
            QString mimeType;
            static QMimeDatabase db;
            const QString scheme = item.url().scheme();
            const QFileInfo info(thumbnailSource.path());

            if (info.isDir()) {
                mimeType = u"inode/directory"_s;
            } else if (scheme.startsWith(QLatin1String("http")) || scheme == QLatin1String("mailto")) {
                mimeType = u"application/octet-stream"_s;
            } else {
                mimeType = db.mimeTypeForFile(thumbnailSource.path(), QMimeDatabase::MatchMode::MatchExtension).name();
            }
            KFileItem itemWithMimetype(thumbnailSource, mimeType);
            m_filesToPreview.append(itemWithMimetype);
        } else {
            m_filesToPreview.append(item);
        }

        if (!m_previewTimer->isActive()) {
            m_previewTimer->start();
        }
        return false;
    }

    // already generating the preview
    return false;
}

void AbstractImageModel::delayedPreview()
{
    if (m_filesToPreview.isEmpty()) {
        return;
    }

    Q_ASSERT(std::ranges::all_of(m_filesToPreview, [](const auto &item) {
        return item.isMimeTypeKnown();
    }));

    for (const auto &file : std::as_const(m_filesToPreview)) {
        m_filesInPreviewGeneration.insert(file.url());
    }

    static const auto pluginLists = KIO::PreviewJob::availablePlugins();
    KIO::PreviewJob *job = KIO::filePreview(QList<KFileItem>(m_filesToPreview.cbegin(), m_filesToPreview.cend()), m_screenshotSize, &pluginLists);
    job->setIgnoreMaximumSize(true);
#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
    connect(job, &KIO::PreviewJob::generated, this, &AbstractImageModel::showPreview);
#else
    connect(job, &KIO::PreviewJob::gotPreview, this, &AbstractImageModel::showPreview);
#endif
    connect(job, &KIO::PreviewJob::failed, this, &AbstractImageModel::previewFailed);
    job->start();

    m_filesToPreview.clear();
}

QModelIndex AbstractImageModel::itemToIndex(const KFileItem &item)
{
    for (auto i = 0, count = rowCount(); i < count; i++) {
        const QUrl url(index(i, 0).data(AbstractImageModel::ImageUrlRole).toString());
        if (url == item.url()) {
            return index(i, 0);
        }
    }

    return {};
}

#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
void AbstractImageModel::showPreview(const KFileItem &item, const QImage &preview)
#else
void AbstractImageModel::showPreview(const KFileItem &item, const QPixmap &preview)
#endif
{
    const auto index = itemToIndex(item);
    m_filesInPreviewGeneration.remove(item.url());

    if (!index.isValid()) {
        return;
    }
    ItemData *itemData;
    if (m_itemData.contains(item.url())) {
        itemData = m_itemData[item.url()];
    } else {
        itemData = new ItemData(item, {});
        m_itemData.insert(item.url(), itemData);
    }

#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
    itemData->thumbnail = preview;
#else
    itemData->thumbnail = preview.toImage();
#endif

    // qDebug() << "preview size:" << preview.size();
    Q_EMIT dataChanged(index, index, {AbstractImageModel::ThumbnailRole});
}

void AbstractImageModel::previewFailed(const KFileItem &item)
{
    // Use folder image instead of displaying nothing then thumbnail generation fails
    const auto index = itemToIndex(item);
    m_filesInPreviewGeneration.remove(item.url());

    if (!index.isValid()) {
        return;
    }

    ItemData *itemData;
    if (m_itemData.contains(item.url())) {
        itemData = m_itemData[item.url()];
    } else {
        itemData = new ItemData(item, {});
        m_itemData.insert(item.url(), itemData);
    }

    itemData->thumbnail = QIcon::fromTheme(item.iconName()).pixmap(m_screenshotSize).toImage();
    Q_EMIT dataChanged(index, index, {AbstractImageModel::ThumbnailRole});
}
