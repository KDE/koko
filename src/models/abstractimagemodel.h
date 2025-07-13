// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "imagestorage.h"

#include <QAbstractListModel>
#include <QCache>
#include <QImage>
#include <QSize>
#include <qqmlregistration.h>

#include <KFileItem>
#include <kio_version.h>

class QTimer;

/*!
 * Abstract model for images, take care of generating previews
 */
class AbstractImageModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Abstract type")

public:
    enum RoleNames {
        ImageUrlRole = Qt::UserRole + 1,
        MimeTypeRole,
        ItemTypeRole,
        FilesRole,
        FileCountRole,
        DateRole,
        SelectedRole,
        ContentRole,
        ItemRole,
        ThumbnailRole,
    };
    Q_ENUM(RoleNames);

    enum ItemType {
        Image,
        Folder,
        Collection,
    };
    Q_ENUM(ItemType);

    ~AbstractImageModel() = default;

    QHash<int, QByteArray> roleNames() const override;

    QVariant dataFromItem(const KFileItem &item, int role) const;

protected:
    explicit AbstractImageModel(QObject *parent = nullptr);
    QVariant thumbnailForItem(const KFileItem &item) const;

private:
#if KIO_VERSION >= QT_VERSION_CHECK(6, 15, 0)
    void showPreview(const KFileItem &item, const QImage &preview);
#else
    void showPreview(const KFileItem &item, const QPixmap &preview);
#endif
    void previewFailed(const KFileItem &item);
    void delayedPreview();
    QModelIndex itemToIndex(const KFileItem &item);

    QTimer *m_previewTimer;
    QSize m_screenshotSize;

    struct ItemData {
        KFileItem item;
        QImage thumbnail;
    };
    QCache<QUrl, ItemData> m_itemData;
    mutable QList<QUrl> m_filesInMimeTypeResolution;
    mutable QList<KFileItem> m_filesToPreview;
    QSet<QUrl> m_filesInPreviewGeneration;
};
