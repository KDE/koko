/*
 *  SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <QTimer>

#include <KDirLister>

/*!
 * Wrapper for KDirLister, providing filtering by file extension and buffering
 *
 * Buffering helps us avoid inserting model items 200-at-a-time and causing
 * rapid model updates. Such updates cause thumbnail generation to spin up on a
 * bunch of unnecessary files and choke population.
 */
class KokoDirLister : public QObject
{
    Q_OBJECT

public:
    KokoDirLister(QObject *parent = nullptr);

    static bool fileItemMatchesFilter(const KFileItem &fileItem);

    QUrl url() const;
    void setUrl(const QUrl &url);

    void stop();

signals:
    void itemsAdded(const KFileItemList &items);
    void itemsDeleted(const KFileItemList &items);
    void completed();

private:
    KDirLister m_dirLister;

    QTimer m_bufferTimer;
    KFileItemList m_bufferedFileItems;

    void flushBufferedFileItems();
};
