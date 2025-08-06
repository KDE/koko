/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <QPainter>
#include <QQuickWindow>

#include "thumbnailmanager.h"

#include "thumbnailitem.h"

ThumbnailItem::ThumbnailItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
    , m_priority(std::numeric_limits<int>::max())
    , m_thumbnailReady(false)
{
    setFlag(ItemHasContents, true);

    // If an image has changed, we must re-request the thumbnail
    connect(ThumbnailManager::instance(), &ThumbnailManager::refreshedThumbnail, this, [this](const QUrl &url) {
        if (m_fileItem.url() == url) {
            ThumbnailManager::instance()->requestThumbnail(this, m_fileItem, m_thumbnailSize);
        }
    });
}

ThumbnailItem::~ThumbnailItem() = default;

KFileItem ThumbnailItem::fileItem() const
{
    return m_fileItem;
}

void ThumbnailItem::setFileItem(const KFileItem &fileItem)
{
    if (m_fileItem == fileItem) {
        return;
    }

    m_fileItem = fileItem;
    Q_EMIT fileItemChanged();

    // Remove current thumbnail
    setThumbnail(QImage(), QUrl());

    ThumbnailManager::instance()->requestThumbnail(this, m_fileItem, m_thumbnailSize);
}

int ThumbnailItem::priority() const
{
    return m_priority;
}

void ThumbnailItem::setPriority(int priority)
{
    if (priority < 0) {
        priority = std::numeric_limits<int>::max();
    }

    if (m_priority == priority) {
        return;
    }

    m_priority = priority;
    Q_EMIT priorityChanged();
}

bool ThumbnailItem::thumbnailReady() const
{
    return m_thumbnailReady;
}

void ThumbnailItem::setThumbnail(const QImage &image, const QUrl &url)
{
    if (!image.isNull() && url != fileItem().url()) {
        // Ignore setting image for non-matching URL (probably an old request)
        return;
    }

    m_image = image;
    updatePaintedRect();
    update();

    if (m_thumbnailReady != !m_image.isNull()) {
        m_thumbnailReady = !m_image.isNull();
        Q_EMIT thumbnailReadyChanged();
    }
}

void ThumbnailItem::paint(QPainter *painter)
{
    if (m_image.isNull()) {
        return;
    }

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, smooth());
    painter->setRenderHint(QPainter::SmoothPixmapTransform, smooth());

    painter->drawImage(m_paintedRect, m_image, m_image.rect());

    painter->restore();
}

void ThumbnailItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    updatePaintedRect();
    updateThumbnailSize();
}

void ThumbnailItem::itemChange(QQuickItem::ItemChange change, const QQuickItem::ItemChangeData &value)
{
    if (change == QQuickItem::ItemDevicePixelRatioHasChanged) {
        updateThumbnailSize(value.realValue);
    }

    return QQuickItem::itemChange(change, value);
}

void ThumbnailItem::updatePaintedRect()
{
    if (m_image.isNull()) {
        return;
    }

    QRectF boundingRect = this->boundingRect();
    QSize imageSize = m_image.size();

    QSizeF scaled(imageSize);

    // NOTE:
    // KIO::PreviewJob returns an image smaller than the bounds when the aspect ratio is not square.
    // In order to show at least most images square, we ask for a preview twice as big as needed and
    // can therefore fill when the image has an aspect of less than or equal to 2:1 or 1:2, else fit.
    //
    // In the future, we should have a better solution for getting a preview that can fill the size
    // we specify, so all thumbnails are filled.
    const Qt::AspectRatioMode aspectRatioMode =
        (boundingRect.width() <= imageSize.width() && boundingRect.height() <= imageSize.height()) ? Qt::KeepAspectRatioByExpanding : Qt::KeepAspectRatio;

    scaled.scale(boundingRect.size(), aspectRatioMode);
    QRectF rect(QPointF(0, 0), scaled);
    rect.moveCenter(boundingRect.center());

    if (m_paintedRect != rect) {
        m_paintedRect = rect.toRect();
    }
}

void ThumbnailItem::updateThumbnailSize(qreal devicePixelRatio)
{
    if (devicePixelRatio == 0) {
        const auto window = this->window();
        if (!window) {
            return;
        }

        devicePixelRatio = window->devicePixelRatio();
    }

    // Double size as noted above
    const QSize thumbnailSize = (size() * devicePixelRatio * 2).toSize();
    if (m_thumbnailSize != thumbnailSize) {
        m_thumbnailSize = thumbnailSize;

        ThumbnailManager::instance()->requestThumbnail(this, m_fileItem, m_thumbnailSize);
    }
}

#include "moc_thumbnailitem.cpp"
