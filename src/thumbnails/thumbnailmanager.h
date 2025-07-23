/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QCache>

#include <KIO/PreviewJob>

#include "thumbnailitem.h"

class ThumbnailManager : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

public:
    static ThumbnailManager *instance();

    static ThumbnailManager *create(QQmlEngine *, QJSEngine *engine);

    void requestThumbnail(ThumbnailItem *item, const KFileItem &fileItem, const QSize &size);

    Q_INVOKABLE void refreshThumbnail(const QUrl &imageUrl);

Q_SIGNALS:
    void refreshedThumbnail(const QUrl &url);

private:
    explicit ThumbnailManager(QObject *parent = nullptr);

    struct QueueEntry {
        QPointer<ThumbnailItem> item;
        KFileItem fileItem;
        QSize size;
    };

    struct CacheEntry {
        KFileItem fileItem;
        QSize size;

        bool operator==(const CacheEntry &other) const
        {
            return fileItem == other.fileItem && size == other.size;
        }
    };

    friend size_t qHash(const ThumbnailManager::CacheEntry &, size_t) noexcept;

    void sortQueueLater();
    void generateLater();
    void sortQueue();
    void generate();

    bool m_sortQueued = false;
    bool m_generateQueued = false;

    QList<QueueEntry> m_thumbnailQueue;
    QCache<CacheEntry, QImage> m_thumbnailCache;

    QList<KIO::PreviewJob *> m_previewJobs;
};

inline size_t qHash(const ThumbnailManager::CacheEntry &key, size_t seed) noexcept
{
    return qHashMulti(seed, key.fileItem, key.size.width(), key.size.height());
}
