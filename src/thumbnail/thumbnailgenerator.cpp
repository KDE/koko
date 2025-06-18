// SPDX-FileCopyrightText: 2012 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "thumbnailgenerator.h"

#include "jpegcontent.h"

// KDCRAW
#ifdef KDCRAW_FOUND
#include <KDCRAW/KDcraw>
#endif

#include <QBuffer>
#include <QCoreApplication>
#include <QImageReader>

bool ThumbnailContext::load(const QString &pixPath, int pixelSize)
{
    mImage = QImage();
    mNeedCaching = true;
    QImage originalImage;
    QSize originalSize;

    QByteArray formatHint = pixPath.section(QLatin1Char('.'), -1).toLocal8Bit().toLower();
    QImageReader reader(pixPath);

    JpegContent content;
    QByteArray format;
    QByteArray data;
    QBuffer buffer;
    int previewRatio = 1;

#ifdef KDCRAW_FOUND
    // raw images deserve special treatment
    if (KDcrawIface::KDcraw::rawFilesList().contains(QString::fromLatin1(formatHint))) {
        // use KDCraw to extract the preview
        bool ret = KDcrawIface::KDcraw::loadEmbeddedPreview(data, pixPath);

        // We need QImage. Loading JpegContent from QImage - exif lost
        // Loading QImage from JpegContent - unimplemented, would go with loadFromData
        if (!ret) {
            // if the embedded preview loading failed, load half preview instead. That's slower...
            if (!KDcrawIface::KDcraw::loadHalfPreview(data, pixPath)) {
                qWarning() << "unable to get preview for " << pixPath.toUtf8().constData();
                return false;
            }
            previewRatio = 2;
        }

        // And we need JpegContent too because of EXIF (orientation!).
        if (!content.loadFromData(data)) {
            qWarning() << "unable to load preview for " << pixPath.toUtf8().constData();
            return false;
        }

        buffer.setBuffer(&data);
        buffer.open(QIODevice::ReadOnly);
        reader.setDevice(&buffer);
        reader.setFormat("jpg");
    } else {
#else
    {
#endif
        if (QImageReader::imageFormat(pixPath) == QByteArray("raw")) {
            // make preview generation faster (same as KDcrawIface::KDcraw::loadHalfPreview)
            reader.setQuality(1);
            previewRatio = 2;
        }

        if (!reader.canRead()) {
            reader.setDecideFormatFromContent(true);
            // Set filename again, otherwise QImageReader won't restart from scratch
            reader.setFileName(pixPath);
        }

        if (reader.format() == "jpeg") {
            content.load(pixPath);
        }
    }

    // If there's jpeg content (from jpg or raw files), try to load an embedded thumbnail, if available.
    if (!content.rawData().isEmpty()) {
        QImage thumbnail = content.thumbnail();

        // If the user does not care about the generated thumbnails (by deleting them on exit), use ANY
        // embedded thumnail, even if it's too small.
        if (!thumbnail.isNull() && (qMax(thumbnail.width(), thumbnail.height()) >= pixelSize)) {
            mImage = std::move(thumbnail);
            mOriginalWidth = content.size().width();
            mOriginalHeight = content.size().height();
            return true;
        }
    }

    // Generate thumbnail from full image
    originalSize = reader.size();
    if (originalSize.isValid() && reader.supportsOption(QImageIOHandler::ScaledSize) && qMax(originalSize.width(), originalSize.height()) >= pixelSize) {
        QSizeF scaledSize = originalSize;
        scaledSize.scale(pixelSize, pixelSize, Qt::KeepAspectRatio);
        if (!scaledSize.isEmpty()) {
            reader.setScaledSize(scaledSize.toSize());
        }
    }

    // Rotate if necessary
    reader.setAutoTransform(true);

    // format() is empty after QImageReader::read() is called
    format = reader.format();
    if (!reader.read(&originalImage)) {
        return false;
    }

    if (!originalSize.isValid()) {
        originalSize = originalImage.size();
    }
    mOriginalWidth = originalSize.width() * previewRatio;
    mOriginalHeight = originalSize.height() * previewRatio;

    if (qMax(mOriginalWidth, mOriginalHeight) <= pixelSize) {
        mImage = originalImage;
        mNeedCaching = format != "png";
    } else {
        mImage = originalImage.scaled(pixelSize, pixelSize, Qt::KeepAspectRatio);
    }

    if (reader.autoTransform() && (reader.transformation() & QImageIOHandler::TransformationRotate90)) {
        std::swap(mOriginalWidth, mOriginalHeight);
    }

    return true;
}

ThumbnailGenerator::ThumbnailGenerator()
    : mCancel(false)
{
    connect(
        qApp,
        &QCoreApplication::aboutToQuit,
        this,
        [=]() {
            cancel();
            wait();
        },
        Qt::DirectConnection);
    start();
}

void ThumbnailGenerator::load(const QString &originalUri,
                              time_t originalTime,
                              KIO::filesize_t originalFileSize,
                              const QString &originalMimeType,
                              const QString &pixPath,
                              const QString &thumbnailPath,
                              ThumbnailGroup group)
{
    QMutexLocker lock(&mMutex);
    Q_ASSERT(mPixPath.isNull());

    mOriginalUri = originalUri;
    mOriginalTime = originalTime;
    mOriginalFileSize = originalFileSize;
    mOriginalMimeType = originalMimeType;
    mPixPath = pixPath;
    mThumbnailPath = thumbnailPath;
    mThumbnailGroup = group;
    mCond.wakeOne();
}

QString ThumbnailGenerator::originalUri() const
{
    return mOriginalUri;
}

bool ThumbnailGenerator::isStopped()
{
    QMutexLocker lock(&mMutex);
    return mStopped;
}

time_t ThumbnailGenerator::originalTime() const
{
    return mOriginalTime;
}

KIO::filesize_t ThumbnailGenerator::originalFileSize() const
{
    return mOriginalFileSize;
}

QString ThumbnailGenerator::originalMimeType() const
{
    return mOriginalMimeType;
}

bool ThumbnailGenerator::testCancel()
{
    QMutexLocker lock(&mMutex);
    return mCancel;
}

void ThumbnailGenerator::cancel()
{
    QMutexLocker lock(&mMutex);
    mCancel = true;
    mCond.wakeOne();
}

void ThumbnailGenerator::run()
{
    while (!testCancel()) {
        QString pixPath;
        int m_pixelSize;
        {
            QMutexLocker lock(&mMutex);
            // empty mPixPath means nothing to do
            if (mPixPath.isNull()) {
                mCond.wait(&mMutex);
            }
        }
        if (testCancel()) {
            break;
        }
        {
            QMutexLocker lock(&mMutex);
            pixPath = mPixPath;
            m_pixelSize = pixelSize(mThumbnailGroup);
        }

        Q_ASSERT(!pixPath.isNull());
        ThumbnailContext context;
        bool ok = context.load(pixPath, m_pixelSize);

        {
            QMutexLocker lock(&mMutex);
            if (ok) {
                mImage = context.mImage;
                mOriginalWidth = context.mOriginalWidth;
                mOriginalHeight = context.mOriginalHeight;
                if (context.mNeedCaching && mThumbnailGroup <= ThumbnailGroup::XXLarge) {
                    cacheThumbnail();
                }
            } else {
                // avoid emitting the thumb from the previous successful run
                mImage = QImage();
                qWarning() << "Could not generate thumbnail for file" << mOriginalUri;
            }
            mPixPath.clear(); // done, ready for next
        }
        if (testCancel()) {
            break;
        }
        {
            QSize size(mOriginalWidth, mOriginalHeight);
            QMutexLocker lock(&mMutex);
            Q_EMIT done(mImage, size);
        }
    }

    QMutexLocker lock(&mMutex);
    mStopped = true;
    deleteLater();
}

void ThumbnailGenerator::cacheThumbnail()
{
    mImage.setText(QStringLiteral("Thumb::URI"), mOriginalUri);
    mImage.setText(QStringLiteral("Thumb::MTime"), QString::number(mOriginalTime));
    mImage.setText(QStringLiteral("Thumb::Size"), QString::number(mOriginalFileSize));
    mImage.setText(QStringLiteral("Thumb::Mimetype"), mOriginalMimeType);
    mImage.setText(QStringLiteral("Thumb::Image::Width"), QString::number(mOriginalWidth));
    mImage.setText(QStringLiteral("Thumb::Image::Height"), QString::number(mOriginalHeight));
    mImage.setText(QStringLiteral("Software"), QStringLiteral("Gwenview"));

    Q_EMIT thumbnailReadyToBeCached(mThumbnailPath, mImage);
}

#include "moc_thumbnailgenerator.cpp"
