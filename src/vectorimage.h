/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef VECTOR_IMAGE_H
#define VECTOR_IMAGE_H

#include <QPainter>
#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QSvgRenderer>
#include <memory>

class VectorImage : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(Status status READ status NOTIFY statusChanged) // read only
    Q_PROPERTY(QRectF sourceClipRect READ sourceClipRect WRITE setSourceClipRect NOTIFY sourceClipRectChanged)
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QSize sourceSize READ sourceSize NOTIFY sourceSizeChanged) // read only
public:
    VectorImage(QQuickItem *parent = nullptr);

    enum Status { Null, Ready, Loading, Error };
    Q_ENUM(Status)

    void paint(QPainter *painter) override;
    void itemChange(ItemChange change, const ItemChangeData &value) override;

    QRectF sourceClipRect() const
    {
        return m_sourceClipRect;
    }

    QUrl source() const
    {
        return m_source;
    }

    QSize sourceSize() const
    {
        return m_sourceSize;
    }

    Status status() const
    {
        return m_status;
    }

    void setSourceClipRect(const QRectF &sourceClipRect);
    void setSource(const QUrl &source);
    void setSourceSize(const QSize &sourceSize);
    void setStatus(Status status);

Q_SIGNALS:
    void sourceClipRectChanged();
    void sourceChanged();
    void sourceSizeChanged();
    void statusChanged(VectorImage::Status);

private:
    QUrl m_source;
    std::unique_ptr<QSvgRenderer> m_renderer;
    QRectF m_sourceClipRect;
    QRectF m_viewBoxF;
    QSize m_sourceSize;
    qreal m_devicePixelRatio;
    Status m_status;
};

#endif // VECTOR_IMAGE_H
