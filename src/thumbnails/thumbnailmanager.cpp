/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <ranges>

#include <QIcon>

#include "thumbnailmanager.h"

// How many images we keep in our local cache (KIO's cache is utilised,
// but this lets us avoid going to disk)
static constexpr int s_cacheSize = 2000;

// How many preview jobs we allow to exist at the same time, so that KIO
// is kept well-fed with thumbnailing work. Best kept low to avoid working
// on too many queued images that might be updated (e.g. during model
// population) or that might be reduced in priority. Currently, it is set
// to the number of kioworkers that are going to chew away at preview
// generation, which is a comfortable value.
static constexpr int s_previewJobLimit = 5;

ThumbnailManager *ThumbnailManager::instance()
{
    static ThumbnailManager *instance = new ThumbnailManager(QCoreApplication::instance());
    return instance;
};

ThumbnailManager *ThumbnailManager::create(QQmlEngine *, QJSEngine *)
{
    return instance();
}

ThumbnailManager::ThumbnailManager(QObject *parent)
    : QObject(parent)
    , m_thumbnailCache(s_cacheSize)
{
}

void ThumbnailManager::requestThumbnail(ThumbnailItem *item, const KFileItem &fileItem, const QSize &size)
{
    if (size.isEmpty()) {
        // ThumbnailItem will re-request with a valid size later
        return;
    }

    // Check if thumbnail exists in cache first
    CacheEntry cacheKey{fileItem, size};
    if (const QImage *cachedImage = m_thumbnailCache.object(cacheKey); cachedImage) {
        item->setThumbnail(*cachedImage, fileItem.url());
        return;
    }

    // Find any queued request by this item
    auto it = std::ranges::find_if(m_thumbnailQueue, [&item](const QueueEntry &entry) {
        return entry.item == item;
    });

    if (it != m_thumbnailQueue.end()) {
        // Replace already queued request
        it->fileItem = fileItem;
        it->size = size;
    } else {
        // Add new request
        m_thumbnailQueue.append({item, fileItem, size});
    }

    sortQueueLater();
    generateLater();
}

void ThumbnailManager::refreshThumbnail(const QUrl &url)
{
    for (const CacheEntry &key : m_thumbnailCache.keys()) {
        if (key.fileItem.url() == url) {
            m_thumbnailCache.remove(key);
        }
    }

    Q_EMIT refreshedThumbnail(url);
}

void ThumbnailManager::sortQueueLater()
{
    if (!m_sortQueued) {
        m_sortQueued = true;
        QMetaObject::invokeMethod(this, &ThumbnailManager::sortQueue, Qt::QueuedConnection);
    }
}

void ThumbnailManager::generateLater()
{
    if (!m_generateQueued) {
        m_generateQueued = true;
        QMetaObject::invokeMethod(this, &ThumbnailManager::generate, Qt::QueuedConnection);
    }
}

void ThumbnailManager::sortQueue()
{
    m_sortQueued = false;

    m_thumbnailQueue.removeIf([](const QueueEntry &entry) {
        return !entry.item;
    });

    std::ranges::sort(m_thumbnailQueue.begin(), m_thumbnailQueue.end(), [](const QueueEntry &a, const QueueEntry &b) {
        return a.item->priority() < b.item->priority();
    });
}

void ThumbnailManager::generate()
{
    m_generateQueued = false;

    if (m_previewJobs.count() >= s_previewJobLimit || m_thumbnailQueue.isEmpty()) {
        return;
    }

    const QueueEntry entry = m_thumbnailQueue.takeFirst();

    if (!entry.item) {
        generate();
        return;
    }

    CacheEntry cacheKey{entry.fileItem, entry.size};
    if (const QImage *cachedImage = m_thumbnailCache.object(cacheKey); cachedImage) {
        entry.item->setThumbnail(*cachedImage, entry.fileItem.url());

        generateLater();
        return;
    }

    static const auto plugins = KIO::PreviewJob::availablePlugins();

    KIO::PreviewJob *previewJob = KIO::filePreview({entry.fileItem}, entry.size, &plugins);
    previewJob->setIgnoreMaximumSize(true);
    m_previewJobs.append(previewJob);

#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
    connect(previewJob, &KIO::PreviewJob::generated, this, [this, previewJob, entry, cacheKey](const KFileItem &item, const QImage &preview) {
        Q_UNUSED(item)

        m_thumbnailCache.insert(cacheKey, new QImage(preview));

        if (entry.item) {
            entry.item->setThumbnail(preview, entry.fileItem.url());
        }

        m_previewJobs.removeAll(previewJob);
        generateLater();
    });
#else
    connect(previewJob, &KIO::PreviewJob::gotPreview, this, [this, previewJob, entry, cacheKey](const KFileItem &item, const QPixmap &preview) {
        Q_UNUSED(item)

        const QImage image = preview.toImage();

        m_thumbnailCache.insert(cacheKey, new QImage(image));

        if (entry.item) {
            entry.item->setThumbnail(image, entry.fileItem.url());
        }

        m_previewJobs.removeAll(previewJob);
        generateLater();
    });
#endif

    connect(previewJob, &KIO::PreviewJob::failed, this, [this, previewJob, entry, cacheKey](const KFileItem &item) {
        // Use file icon when preview generation fails
        const QImage image = QIcon::fromTheme(item.iconName()).pixmap(entry.size).toImage();

        m_thumbnailCache.insert(cacheKey, new QImage(image));

        if (entry.item) {
            entry.item->setThumbnail(image, entry.fileItem.url());
        }

        m_previewJobs.removeAll(previewJob);
        generateLater();
    });

    generateLater();
}

#include "moc_thumbnailmanager.cpp"
