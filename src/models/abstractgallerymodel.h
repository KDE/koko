/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QAbstractListModel>
#include <qqmlregistration.h>

#include <KFileItem>

/*!
 * Abstract model for a gallery in Koko (folder views, collections)
 */
class AbstractGalleryModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Abstract type")

    Q_PROPERTY(QString title READ title NOTIFY titleChanged)

public:
    ~AbstractGalleryModel() = default;

    virtual QString title() const
    {
        return QString();
    }

    enum ItemType {
        Media, // This item is an image or video
        Folder, // This item is a folder
        Collection // Virtual 'folder' for database views
    };
    Q_ENUM(ItemType)

    enum ImageRoles {
        NameRole = Qt::UserRole + 1, // File name or collection name for display
        FileItemRole, // KFileItem
        ItemTypeRole, // Image/Folder/Collection
        MimeTypeRole, // MIME type
        UrlRole, // QUrl for item
        FileCountRole, // For folders or collections
        SizeRole, // File size
        ModifiedRole, // Date modified
        CreatedRole, // Date created
        AccessedRole, // Date accessed
    };
    Q_ENUM(ImageRoles)

    QHash<int, QByteArray> roleNames() const override;

    // For subclasses to indicate whether the model contents should be filtered
    virtual bool requiresFiltering() const
    {
        return false;
    }

Q_SIGNALS:
    void titleChanged();

protected:
    explicit AbstractGalleryModel(QObject *parent = nullptr);

    QVariant dataFromFileItem(const KFileItem &fileItem, int role) const;
};
