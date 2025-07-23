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

    QSizeF scaled(m_image.size());
    scaled.scale(boundingRect().size(), Qt::KeepAspectRatio);

    QRectF rect(QPointF(0, 0), scaled);
    rect.moveCenter(boundingRect().center());

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

    const QSize thumbnailSize = (size() * devicePixelRatio).toSize();
    if (m_thumbnailSize != thumbnailSize) {
        m_thumbnailSize = thumbnailSize;

        ThumbnailManager::instance()->requestThumbnail(this, m_fileItem, m_thumbnailSize);
    }
}

#include "moc_thumbnailitem.cpp"
