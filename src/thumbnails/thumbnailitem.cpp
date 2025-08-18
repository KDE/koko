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

    updateMimePixmap();

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

void ThumbnailItem::colorsChanged()
{
    // Workaround for folders using accent colour, which must be updated if the accent color changes
    if (!m_fileItem.isFile()) {
        updateMimePixmap();
        update();

        ThumbnailManager::instance()->refreshThumbnail(m_fileItem.url());
    }
}

void ThumbnailItem::setThumbnail(const QImage &image, const QUrl &url)
{
    if (!image.isNull() && url != fileItem().url()) {
        // Ignore setting image for non-matching URL (probably an old request)
        return;
    }

    m_previewImage = image;
    updatePaintedRect();
    update();
}

void ThumbnailItem::paint(QPainter *painter)
{
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, smooth());
    painter->setRenderHint(QPainter::SmoothPixmapTransform, smooth());

    if (m_previewImage.isNull()) {
        // Show the mimetype icon
        painter->drawPixmap(boundingRect(), m_mimePixmap, m_mimePixmap.rect());
    } else {
        // Show a thumbnail
        painter->drawImage(m_paintedRect, m_previewImage, m_previewImage.rect());
    }

    painter->restore();
}

void ThumbnailItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    updatePaintedRect();
    updateThumbnailSize();
    updateMimePixmap();
}

void ThumbnailItem::itemChange(QQuickItem::ItemChange change, const QQuickItem::ItemChangeData &value)
{
    if (change == QQuickItem::ItemDevicePixelRatioHasChanged) {
        updateThumbnailSize(value.realValue);
        updateMimePixmap();
    }

    return QQuickItem::itemChange(change, value);
}

void ThumbnailItem::updateMimePixmap()
{
    const QIcon icon = QIcon::fromTheme(m_fileItem.iconName());

    if (icon.isNull()) {
        m_mimePixmap = QPixmap();
        return;
    }

    m_mimePixmap = icon.pixmap(m_thumbnailSize, m_devicePixelRatio);

    update();
}

void ThumbnailItem::updatePaintedRect()
{
    if (m_previewImage.isNull()) {
        return;
    }

    QRectF boundingRect = this->boundingRect();
    QSize imageSize = m_previewImage.size();

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

void ThumbnailItem::updateThumbnailSize()
{
    const auto window = this->window();
    if (!window) {
        return;
    }

    updateThumbnailSize(window->devicePixelRatio());
}

void ThumbnailItem::updateThumbnailSize(qreal devicePixelRatio)
{
    m_devicePixelRatio = devicePixelRatio;

    // Double size as noted above
    const QSize thumbnailSize = (size() * m_devicePixelRatio * 2).toSize();
    if (m_thumbnailSize != thumbnailSize) {
        m_thumbnailSize = thumbnailSize;

        ThumbnailManager::instance()->requestThumbnail(this, m_fileItem, m_thumbnailSize);
    }
}

#include "moc_thumbnailitem.cpp"
