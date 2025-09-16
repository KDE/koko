/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "abstractgallerymodel.h"

AbstractGalleryModel::AbstractGalleryModel(QObject *parent)
    : QAbstractListModel(parent)
{
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
    return roles;
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
