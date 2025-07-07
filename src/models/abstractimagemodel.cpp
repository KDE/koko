// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "abstractimagemodel.h"

#include "imagestorage.h"
#include "roles.h"

#include <QMimeDatabase>

AbstractImageModel::AbstractImageModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

QHash<int, QByteArray> AbstractImageModel::roleNames() const
{
    return Roles::roleNames();
}

QVariant AbstractImageModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const int indexValue = index.row();
    const auto &image = m_images.at(indexValue);

    switch (role) {
    case Roles::ItemRole:
        return image;

    case Roles::ContentRole:
        return image.name();

    case Roles::ImageUrlRole:
        return image.url();

    case Roles::ItemTypeRole:
        return QVariant::fromValue(ImageStorage::ItemTypes::Image);

    case Roles::MimeTypeRole:
        return image.mimetype();

    case Roles::SelectedRole:
        return false;

    default:
        return {};
    }
}

int AbstractImageModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_images.size();
}

void AbstractImageModel::setImages(const KFileItemList &images)
{
    if (m_images == images) {
        return;
    }

    beginResetModel();
    m_images = images;
    for (auto &image : m_images) {
        image.setDelayedMimeTypes(true);
    }
    endResetModel();
}
