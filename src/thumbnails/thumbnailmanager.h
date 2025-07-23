/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QCache>

#include "thumbnailitem.h"

class ThumbnailManager : public QObject
{
    Q_OBJECT

public:
    static ThumbnailManager *instance();

    void registerItem(QPointer<ThumbnailItem> item);
    void updateItemPriority(QPointer<ThumbnailItem> item, int priority);
    void requestThumbnail(QPointer<ThumbnailItem> item, const QUrl &url, const QSize &size);

private:
    explicit ThumbnailManager(QObject *parent = nullptr);

    QMap<QPointer<ThumbnailItem>, int> m_itemPriorities;

    struct QueueEntry {
        QList<QPointer<ThumbnailItem>> items;
        QUrl url;
        QSize size;
    };
    QList<QueueEntry> m_thumbnailQueue;

    struct CacheEntry {
        QUrl url;
        QSize size;
    };
    QCache<CacheEntry, QImage> m_thumbnailCache;
};
