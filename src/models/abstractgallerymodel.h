/*
 *  SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
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
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)

public:
    ~AbstractGalleryModel() = default;

    enum Status {
        Unloaded,
        Loading,
        Loaded
    };
    Q_ENUM(Status)

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

    virtual QString title() const = 0;

    // For models which are not immediately populated
    virtual Status status() const;

    QHash<int, QByteArray> roleNames() const override;

    // For subclasses to indicate whether the model contents should be filtered
    virtual bool requiresFiltering() const;

Q_SIGNALS:
    void titleChanged();
    void statusChanged();

protected:
    explicit AbstractGalleryModel(QObject *parent = nullptr);

    QVariant dataFromFileItem(const KFileItem &fileItem, int role) const;
};
