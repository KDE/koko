// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "abstractimagemodel.h"

using namespace Qt::StringLiterals;

AbstractImageModel::AbstractImageModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

QHash<int, QByteArray> AbstractImageModel::roleNames() const
{
    return {
        {Qt::DecorationRole, "decoration"},
        {FilesRole, "files"},
        {FileCountRole, "fileCount"},
        {ImageUrlRole, "imageurl"},
        {DateRole, "date"},
        {MimeTypeRole, "mimeType"},
        {ItemTypeRole, "itemType"},
        {ContentRole, "content"},
        {SelectedRole, "selected"},
        {ItemRole, "item"},
    };
}

QVariant AbstractImageModel::dataFromItem(const KFileItem &item, int role) const
{
    switch (role) {
    case ItemRole:
        return item;
    case ContentRole:
        return item.name();
    case ImageUrlRole:
        return item.url();
    case ItemTypeRole:
        return item.isDir() ? ItemType::Folder : ItemType::Image;
    case MimeTypeRole:
        return item.mimetype();
    case SelectedRole:
        return false;
    default:
        return {};
    }
}
