// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "openfilemodel.h"

#include "abstractimagemodel.h"
#include "imagestorage.h"

#include <QMimeDatabase>

OpenFileModel::OpenFileModel(QObject *parent)
    : AbstractImageModel(parent)
{
}

OpenFileModel::~OpenFileModel() = default;

QVariant OpenFileModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const auto &item = m_images[index.row()];
    return dataFromItem(item, role);
}

int OpenFileModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? m_images.size() : 0;
}

void OpenFileModel::updateOpenFiles(const QStringList &images)
{
    beginResetModel();
    m_images.clear();

    std::ranges::transform(images, std::back_inserter(m_images), [](const auto &image) {
        auto item = KFileItem(image);
        item.setDelayedMimeTypes(true);
        return item;
    });

    endResetModel();
    Q_EMIT itemToOpenChanged();
    Q_EMIT updatedImages();
}

KFileItem OpenFileModel::itemToOpen() const
{
    if (m_images.length() == 1) {
        return m_images.value(0);
    }
    return {};
}
