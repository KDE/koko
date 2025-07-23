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
{
    setFlag(ItemHasContents, true);

    ThumbnailManager::instance()->registerItem(this);

    connect(this, &QQuickItem::widthChanged, this, &ThumbnailItem::updateThumbnailSize);
    connect(this, &QQuickItem::heightChanged, this, &ThumbnailItem::updateThumbnailSize);
    connect(this, &QQuickItem::windowChanged, this, &ThumbnailItem::updateThumbnailSize);
    updateThumbnailSize();
}

ThumbnailItem::~ThumbnailItem()
{
}

QUrl ThumbnailItem::url() const
{
    return m_url;
}

void ThumbnailItem::setUrl(const QUrl &url)
{
    if (m_url == url) {
        return;
    }

    m_url = url;
    Q_EMIT urlChanged();

    m_image = QImage();
    ThumbnailManager::instance()->requestThumbnail(this, m_url, m_thumbnailSize);
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

    ThumbnailManager::instance()->updateItemPriority(this, m_priority);
}

void ThumbnailItem::paint(QPainter *painter)
{
    if (m_image.isNull()) {
        return;
    }

    painter->setRenderHint(QPainter::Antialiasing, smooth());
    painter->setRenderHint(QPainter::SmoothPixmapTransform, smooth());

    painter->drawImage(m_paintedRect, m_image, m_image.rect());

    painter->restore();
}

void ThumbnailItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    updatePaintedRect();
}

void ThumbnailItem::updatePaintedRect()
{
    if (m_image.isNull()) {
        return;
    }

    QSizeF scaled = m_image.size();
    scaled.scale(boundingRect().size(), Qt::KeepAspectRatioByExpanding);

    QRectF rect = QRectF(QPointF(0, 0), scaled);
    rect.moveCenter(boundingRect().center());

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

    m_thumbnailSize = (this->size() * window->devicePixelRatio()).toSize();

    if (!m_image.isNull()) {
        ThumbnailManager::instance()->requestThumbnail(this, m_url, m_thumbnailSize);
    }
}
