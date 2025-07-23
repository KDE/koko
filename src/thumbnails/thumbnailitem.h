/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QImage>
#include <QQuickPaintedItem>

// TODO:
// size change: Keep QImage, make request
// url change: Empty QImage, make request
// priority change: update request

class ThumbnailItem : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged REQUIRED)
    Q_PROPERTY(int priority READ priority WRITE setPriority NOTIFY priorityChanged REQUIRED)

public:
    explicit ThumbnailItem(QQuickItem *parent = nullptr);
    ~ThumbnailItem() override;

    QUrl url() const;
    void setUrl(const QUrl &url);

    int priority() const;
    void setPriority(int priority);

    void paint(QPainter *painter) override;

Q_SIGNALS:
    void urlChanged();
    void priorityChanged();

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    void updatePaintedRect();
    void updateThumbnailSize();

    QImage m_image;
    QRect m_paintedRect;

    QUrl m_url;
    int m_priority;
    QSize m_thumbnailSize;
};
