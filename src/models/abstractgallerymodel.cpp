/*
 *  SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "abstractgallerymodel.h"

AbstractGalleryModel::AbstractGalleryModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

AbstractGalleryModel::Status AbstractGalleryModel::status() const
{
    return Loaded;
}

QHash<int, QByteArray> AbstractGalleryModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles[NameRole] = "name";
    roles[FileItemRole] = "fileItem";
    roles[ItemTypeRole] = "itemType";
    roles[MimeTypeRole] = "mimeType";
    roles[UrlRole] = "url";
    roles[FileCountRole] = "fileCount";
    roles[SizeRole] = "size";
    roles[ModifiedRole] = "modified";
    roles[CreatedRole] = "created";
    roles[AccessedRole] = "accessed";
    return roles;
}

bool AbstractGalleryModel::requiresFiltering() const
{
    return false;
}

QVariant AbstractGalleryModel::dataFromFileItem(const KFileItem &fileItem, int role) const
{
    switch (role) {
    case Qt::DisplayRole:
    case NameRole:
        return fileItem.name();
    case FileItemRole:
        return fileItem;
    case ItemTypeRole:
        return fileItem.isDir() ? ItemType::Folder : ItemType::Media;
    case MimeTypeRole:
        return fileItem.mimetype();
    case UrlRole:
        return fileItem.url();
    case FileCountRole:
        return 0;
    case SizeRole:
        return fileItem.size();
    case ModifiedRole:
        return fileItem.time(KFileItem::FileTimes::ModificationTime);
    case CreatedRole:
        return fileItem.time(KFileItem::FileTimes::CreationTime);
    case AccessedRole:
        return fileItem.time(KFileItem::FileTimes::AccessTime);
    default:
        return {};
    }
}
