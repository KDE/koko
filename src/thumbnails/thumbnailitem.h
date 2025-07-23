/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QImage>
#include <QQuickPaintedItem>

#include <KFileItem>

class ThumbnailItem : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(KFileItem fileItem READ fileItem WRITE setFileItem NOTIFY fileItemChanged REQUIRED)
    Q_PROPERTY(int priority READ priority WRITE setPriority NOTIFY priorityChanged REQUIRED)
    Q_PROPERTY(bool thumbnailReady READ thumbnailReady NOTIFY thumbnailReadyChanged)

public:
    explicit ThumbnailItem(QQuickItem *parent = nullptr);
    ~ThumbnailItem() override;

    KFileItem fileItem() const;
    void setFileItem(const KFileItem &fileItem);

    int priority() const;
    void setPriority(int priority);

    bool thumbnailReady() const;
    void setThumbnail(const QImage &image, const QUrl &url);

    void paint(QPainter *painter) override;

Q_SIGNALS:
    void fileItemChanged();
    void priorityChanged();
    void thumbnailReadyChanged();

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;
    void itemChange(QQuickItem::ItemChange change, const QQuickItem::ItemChangeData &value) override;

private:
    void updatePaintedRect();
    void updateThumbnailSize(qreal devicePixelRatio = 0);

    QPointer<QQuickWindow> m_window = nullptr;

    QImage m_image;
    QRect m_paintedRect;

    KFileItem m_fileItem;
    QSize m_thumbnailSize;
    int m_priority;
    bool m_thumbnailReady;
};
