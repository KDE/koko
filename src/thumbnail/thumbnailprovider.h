// Copied from Gwenview and is based on the ImagePreviewJob class from Konqueror
// SPDX-FileCopyrightText: 2000 David Faure <faure@kde.org>
// SPDX-FileCopyrightText: 2012 Aurélien Gâteau <agateau@kde.org>
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QImage>
#include <QPixmap>
#include <QPointer>

#include <KFileItem>
#include <KIO/Job>

#include "thumbnailgroup.h"

class ThumbnailGenerator;
class ThumbnailWriter;

/**
 * A job that determines the thumbnails for the images in the current directory
 */
class ThumbnailProvider : public KIO::Job
{
    Q_OBJECT
public:
    ThumbnailProvider();
    ~ThumbnailProvider() override;

    void stop();

    /**
     * To be called whenever items are removed from the view
     */
    void removeItems(const KFileItemList &itemList);

    /**
     * Remove all pending items
     */
    void removePendingItems();

    /**
     * Returns the list of items waiting for a thumbnail
     */
    const KFileItemList &pendingItems() const;

    /**
     * Add items to the job
     */
    void appendItems(const KFileItemList &items);

    /**
     * Defines size of thumbnails to generate
     */
    void setThumbnailGroup(ThumbnailGroup);

    bool isRunning() const;

    /**
     * Returns the thumbnail base dir, independent of the thumbnail size
     */
    static QString thumbnailBaseDir();

    /**
     * Sets the thumbnail base dir, useful for unit-testing
     */
    static void setThumbnailBaseDir(const QString &);

    /**
     * Returns the thumbnail base dir, for the @p group
     */
    static QString thumbnailBaseDir(ThumbnailGroup group);

    /**
     * Delete the thumbnail for the @p url
     */
    static void deleteImageThumbnail(const QUrl &url);

    /**
     * Move a thumbnail to match a file move
     */
    static void moveThumbnail(const QUrl &oldUrl, const QUrl &newUrl);

    /**
     * Returns true if all thumbnails have been written to disk. Useful for
     * unit-testing.
     */
    static bool isThumbnailWriterEmpty();

Q_SIGNALS:
    /**
     * Emitted when the thumbnail for the @p item has been loaded
     */
    void thumbnailLoaded(const KFileItem &item, const QPixmap &, const QSize &, qulonglong);

    void thumbnailLoadingFailed(const KFileItem &item);

    /**
     * Queue is empty
     */
    void finished();

protected:
    void slotResult(KJob *job) override;

private Q_SLOTS:
    void determineNextIcon();
    void slotGotPreview(const KFileItem &, const QPixmap &);
    void checkThumbnail();
    void thumbnailReady(const QImage &, const QSize &);
    void emitThumbnailLoadingFailed();

private:
    enum {
        STATE_STATORIG,
        STATE_DOWNLOADORIG,
        STATE_PREVIEWJOB,
        STATE_NEXTTHUMB,
    } mState;

    KFileItemList mItems;
    KFileItem mCurrentItem;

    // The Url of the current item (always equivalent to m_items.first()->item()->url())
    QUrl mCurrentUrl;

    // The Uri of the original image (might be different from mCurrentUrl.url())
    QString mOriginalUri;

    // The modification time of the original image
    time_t mOriginalTime;

    // The file size of the original image
    KIO::filesize_t mOriginalFileSize;

    // The thumbnail path
    QString mThumbnailPath;

    // The temporary path for remote urls
    QString mTempPath;

    // Thumbnail group
    ThumbnailGroup mThumbnailGroup;

    ThumbnailGenerator *mThumbnailGenerator;
    QPointer<ThumbnailGenerator> mPreviousThumbnailGenerator;

    QStringList mPreviewPlugins;

    void createNewThumbnailGenerator();
    void abortSubjob();
    void startCreatingThumbnail(const QString &path);

    void emitThumbnailLoaded(const QImage &img, const QSize &size);

    QImage loadThumbnailFromCache() const;
};
