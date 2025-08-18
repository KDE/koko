/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QImage>
#include <QPixmap>
#include <QQuickPaintedItem>

#include <KFileItem>

class ThumbnailItem : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(KFileItem fileItem READ fileItem WRITE setFileItem NOTIFY fileItemChanged REQUIRED)
    Q_PROPERTY(int priority READ priority WRITE setPriority NOTIFY priorityChanged REQUIRED)

public:
    explicit ThumbnailItem(QQuickItem *parent = nullptr);
    ~ThumbnailItem() override;

    KFileItem fileItem() const;
    void setFileItem(const KFileItem &fileItem);

    int priority() const;
    void setPriority(int priority);

    Q_INVOKABLE void colorsChanged();

    void setThumbnail(const QImage &image, const QUrl &url);

    void paint(QPainter *painter) override;

Q_SIGNALS:
    void fileItemChanged();
    void priorityChanged();

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;
    void itemChange(QQuickItem::ItemChange change, const QQuickItem::ItemChangeData &value) override;

private:
    void updateMimePixmap();
    void updatePaintedRect();
    void updateThumbnailSize();
    void updateThumbnailSize(qreal devicePixelRatio);

    QPointer<QQuickWindow> m_window = nullptr;

    KFileItem m_fileItem;
    int m_priority;

    qreal m_devicePixelRatio;

    QRect m_paintedRect;
    QSize m_thumbnailSize;
    QImage m_previewImage;

    QPixmap m_mimePixmap;
};
