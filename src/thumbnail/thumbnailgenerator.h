// SPDX-FileCopyrightText: 2012 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include "thumbnailgroup.h"

#include <KFileItem>

#include <QImage>
#include <QMutex>
#include <QThread>
#include <QWaitCondition>

struct ThumbnailContext {
    QImage mImage;
    int mOriginalWidth;
    int mOriginalHeight;
    bool mNeedCaching;

    bool load(const QString &pixPath, int pixelSize);
};

class ThumbnailGenerator : public QThread
{
    Q_OBJECT
public:
    ThumbnailGenerator();

    // Because we override run(), like you're not really supposed to do, we
    // can't trust isRunning()
    bool isStopped();

    void load(const QString &originalUri,
              time_t originalTime,
              KIO::filesize_t originalFileSize,
              const QString &originalMimeType,
              const QString &pixPath,
              const QString &thumbnailPath,
              ThumbnailGroup group);

    void cancel();

    QString originalUri() const;
    time_t originalTime() const;
    KIO::filesize_t originalFileSize() const;
    QString originalMimeType() const;

protected:
    void run() override;

Q_SIGNALS:
    void done(const QImage &, const QSize &);
    void thumbnailReadyToBeCached(const QString &thumbnailPath, const QImage &);

private:
    bool testCancel();
    void cacheThumbnail();
    QImage mImage;
    QString mPixPath;
    QString mThumbnailPath;
    QString mOriginalUri;
    time_t mOriginalTime;
    KIO::filesize_t mOriginalFileSize;
    QString mOriginalMimeType;
    int mOriginalWidth;
    int mOriginalHeight;
    QMutex mMutex;
    QWaitCondition mCond;
    ThumbnailGroup mThumbnailGroup;
    bool mCancel;
    bool mStopped = false;
};
