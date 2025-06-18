// Copied from Gwenview and is based on the ImagePreviewJob class from Konqueror
// SPDX-FileCopyrightText: 2012 Aurélien Gâteau <agateau@kde.org>
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "thumbnailwriter.h"

#include <QDebug>
#include <QImage>
#include <QTemporaryFile>

static void storeThumbnailToDiskCache(const QString &path, const QImage &image)
{
    QTemporaryFile tmp(path + QStringLiteral(".gwenview.tmpXXXXXX.png"));
    if (!tmp.open()) {
        qWarning() << "Could not create a temporary file.";
        return;
    }

    if (!image.save(tmp.fileName(), "png")) {
        qWarning() << "Could not save thumbnail";
        return;
    }

    QFile::rename(tmp.fileName(), path);
}

void ThumbnailWriter::queueThumbnail(const QString &path, const QImage &image)
{
    QMutexLocker locker(&mMutex);
    mCache.insert(path, image);
    start();
}

void ThumbnailWriter::run()
{
    QMutexLocker locker(&mMutex);
    while (!mCache.isEmpty() && !isInterruptionRequested()) {
        Cache::ConstIterator it = mCache.constBegin();
        const QString path = it.key();
        const QImage image = it.value();

        // This part of the thread is the most time consuming but it does not
        // depend on mCache so we can unlock here. This way other thumbnails
        // can be added or queried
        locker.unlock();
        storeThumbnailToDiskCache(path, image);
        locker.relock();

        mCache.remove(path);
    }
}

QImage ThumbnailWriter::value(const QString &path) const
{
    QMutexLocker locker(&mMutex);
    return mCache.value(path);
}

bool ThumbnailWriter::isEmpty() const
{
    QMutexLocker locker(&mMutex);
    return mCache.isEmpty();
}

#include "moc_thumbnailwriter.cpp"
