/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "vectorimage.h"
#include <QQuickWindow>

VectorImage::VectorImage(QQuickItem *parent)
    : QQuickPaintedItem(parent)
    , m_devicePixelRatio(0)
    , m_status(Null)
{
}

void VectorImage::setSourceClipRect(const QRectF &sourceClipRect)
{
    if (m_sourceClipRect == sourceClipRect) {
        return;
    }
    m_sourceClipRect = sourceClipRect;
    Q_EMIT sourceClipRectChanged();
    update();
}

void VectorImage::setSourceSize(const QSize &sourceSize)
{
    if (m_sourceSize == sourceSize) {
        return;
    }
    m_sourceSize = sourceSize;
    Q_EMIT sourceSizeChanged();
}

void VectorImage::setStatus(Status status)
{
    if (m_status == status) {
        return;
    }
    m_status = status;
    Q_EMIT statusChanged(m_status);
}

void VectorImage::setSource(const QUrl &source)
{
    if (m_source == source) {
        return;
    }
    m_source = source;
    Q_EMIT sourceChanged();

    if (m_source.isEmpty()) {
        setStatus(Null);
        m_viewBoxF = QRectF();
        setSourceSize(QSize());
        return;
    }

    setStatus(Loading);

    m_renderer = std::make_unique<QSvgRenderer>(m_source.toLocalFile());

    if (!m_renderer->isValid()) {
        setStatus(Error);
        m_viewBoxF = QRectF();
        setSourceSize(QSize());
        return;
    }

    m_renderer->setAspectRatioMode(Qt::KeepAspectRatio);

    setSourceSize(m_renderer->defaultSize());

    m_viewBoxF = m_renderer->viewBoxF();

    if (m_devicePixelRatio == 0) {
        m_devicePixelRatio = window()->effectiveDevicePixelRatio();
    }
    setStatus(Ready);
    update();
}

void VectorImage::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemDevicePixelRatioHasChanged && m_devicePixelRatio != value.realValue) {
        m_devicePixelRatio = value.realValue;
        update();
    }
    QQuickItem::itemChange(change, value);
}

void VectorImage::paint(QPainter *painter)
{
    if (m_status != Ready) {
        return;
    }

    auto scale_x = sourceSize().width() / width() / m_devicePixelRatio;
    auto zoom_x = sourceClipRect().width() / m_viewBoxF.width() * scale_x;

    auto scale_y = sourceSize().height() / height() / m_devicePixelRatio;
    auto zoom_y = sourceClipRect().height() / m_viewBoxF.height() * scale_y;

    QRectF clip(sourceClipRect().x() / zoom_x * scale_x + m_viewBoxF.x(),
                sourceClipRect().y() / zoom_y * scale_y + m_viewBoxF.y(),
                sourceSize().width() / zoom_x,
                sourceSize().height() / zoom_y);

    m_renderer->setViewBox(clip);
    m_renderer->render(painter);

    return;
}
