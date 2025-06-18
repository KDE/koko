/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#pragma once

#include <QItemSelectionModel>
#include <QJsonArray>
#include <QSize>
#include <QSortFilterProxyModel>
#include <QTimer>
#include <QVariant>

#include "thumbnail/thumbnailprovider.h"
#include <kdirmodel.h>
#include <kimagecache.h>
#include <kshareddatacache.h>
#include <qqmlregistration.h>

const int SMOOTH_DELAY = 500;

const int WHEEL_ZOOM_MULTIPLIER = 4;

static KFileItem fileItemForIndex(const QModelIndex &index)
{
    if (!index.isValid()) {
        return {};
    }
    QVariant data = index.data(KDirModel::FileItemRole);
    return qvariant_cast<KFileItem>(data);
}

static QUrl urlForIndex(const QModelIndex &index)
{
    KFileItem item = fileItemForIndex(index);
    return item.isNull() ? QUrl() : item.url();
}

struct Thumbnail {
    Thumbnail(const QPersistentModelIndex &index_, const QDateTime &mtime)
        : mIndex(index_)
        , mModificationTime(mtime)
        , mFileSize(0)
        , mRough(true)
        , mWaitingForThumbnail(true)
    {
    }

    Thumbnail()
        : mFileSize(0)
        , mRough(true)
        , mWaitingForThumbnail(true)
    {
    }

    /**
     * Init the thumbnail based on a icon
     */
    void initAsIcon(const QPixmap &pix)
    {
        mGroupPix = pix;
        int largeGroupSize = pixelSize(ThumbnailGroup::Large);
        mFullSize = QSize(largeGroupSize, largeGroupSize);
    }

    bool isGroupPixAdaptedForSize(int size) const
    {
        if (mWaitingForThumbnail) {
            return false;
        }
        if (mGroupPix.isNull()) {
            return false;
        }
        const int groupSize = qMax(mGroupPix.width(), mGroupPix.height());
        if (groupSize >= size) {
            return true;
        }

        // groupSize is less than size, but this may be because the full image
        // is the same size as groupSize
        return groupSize == qMax(mFullSize.width(), mFullSize.height());
    }

    void prepareForRefresh(const QDateTime &mtime)
    {
        mModificationTime = mtime;
        mFileSize = 0;
        mGroupPix = QPixmap();
        mAdjustedPix = QPixmap();
        mFullSize = QSize();
        mRealFullSize = QSize();
        mRough = true;
        mWaitingForThumbnail = true;
    }

    QPersistentModelIndex mIndex;
    QDateTime mModificationTime;
    /// The pix loaded from .thumbnails/{large,normal}
    QPixmap mGroupPix;
    /// Scaled version of mGroupPix, adjusted to ThumbnailView::thumbnailSize
    QPixmap mAdjustedPix;
    /// Size of the full image
    QSize mFullSize;
    /// Real size of the full image, invalid unless the thumbnail
    /// represents a raster image (not an icon)
    QSize mRealFullSize;
    /// File size of the full image
    KIO::filesize_t mFileSize;
    /// Whether mAdjustedPix represents has been scaled using fast or smooth
    /// transformation
    bool mRough;
    /// Set to true if mGroupPix should be replaced with a real thumbnail
    bool mWaitingForThumbnail;
};

using ThumbnailForUrl = QHash<QUrl, Thumbnail>;
using UrlQueue = QQueue<QUrl>;

class SortModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QByteArray sortRoleName READ sortRoleName WRITE setSortRoleName NOTIFY sortRoleNameChanged)
    Q_PROPERTY(bool containImages READ containImages WRITE setContainImages NOTIFY containImagesChanged)
    Q_PROPERTY(bool hasSelectedImages READ hasSelectedImages NOTIFY selectedImagesChanged)
public:
    explicit SortModel(QObject *parent = nullptr);
    virtual ~SortModel();

    QByteArray sortRoleName() const;
    void setSortRoleName(const QByteArray &name);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override;

    void setSourceModel(QAbstractItemModel *sourceModel) override;
    bool containImages();
    bool hasSelectedImages();

    Q_INVOKABLE void setSelected(int indexValue);
    Q_INVOKABLE void toggleSelected(int indexValue);
    Q_INVOKABLE void clearSelections();
    Q_INVOKABLE void selectAll();
    Q_INVOKABLE void deleteSelection();
    Q_INVOKABLE void restoreSelection();
    Q_INVOKABLE int proxyIndex(const int &indexValue);
    Q_INVOKABLE int sourceIndex(const int &indexValue);
    Q_INVOKABLE QJsonArray selectedImages();
    Q_INVOKABLE QJsonArray selectedImagesMimeTypes();
    Q_INVOKABLE int indexForUrl(const QString &url);

protected Q_SLOTS:
    void setContainImages(bool);
    void showPreview(const KFileItem &item, const QPixmap &preview);
    void previewFailed(const KFileItem &item);
    void delayedPreview();

signals:
    void sortRoleNameChanged();
    void containImagesChanged();
    void selectedImagesChanged();

private:
    void scheduleThumbnailGeneration();
    void generateThumbnailsForItems();

    QByteArray m_sortRoleName;
    QItemSelectionModel *m_selectionModel;
    ThumbnailForUrl mThumbnailForUrl;

    QTimer *m_previewTimer;
    QHash<QUrl, QPersistentModelIndex> m_filesToPreview;

    QSize m_screenshotSize;
    QHash<QUrl, QPersistentModelIndex> m_previewJobs;
    QTimer mScheduledThumbnailGenerationTimer;
    KImageCache *m_imageCache;
    bool m_containImages;

    QPixmap mWaitingThumbnail;
    QPointer<ThumbnailProvider> mThumbnailProvider;
};
