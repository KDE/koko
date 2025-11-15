/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QQuickItem>

#include <KFileItem>

class QSGTexture;

class ThumbnailItem : public QQuickItem
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

Q_SIGNALS:
    void fileItemChanged();
    void priorityChanged();
    void thumbnailReadyChanged();

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;
    void itemChange(QQuickItem::ItemChange change, const QQuickItem::ItemChangeData &value) override;
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
    QRectF paintedRect() const;
    void updateThumbnailSize(qreal devicePixelRatio = 0);

    // We have to do this weird double-pairing because the scene graph *really* doesn't like it when you pull a texture out from underneath it.
    QSGTexture *m_texture;
    QSGTexture *m_newTexture;

    KFileItem m_fileItem;
    QSize m_thumbnailSize;
    int m_priority;
};
