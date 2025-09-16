/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagetagsmodel.h"
#include "abstractimagemodel.h"
#include "imagestorage.h"

ImageTagsModel::ImageTagsModel(QObject *parent)
    : AbstractImageModel(parent)
    , m_tag(QString())
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageTagsModel::slotPopulate);
}

QVariant ImageTagsModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    const auto &item = m_images[index.row()];
    return dataFromItem(item, role);
}

int ImageTagsModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? m_images.size() : 0;
}

QString ImageTagsModel::tag() const
{
    return m_tag;
}

void ImageTagsModel::setTag(const QString &tag)
{
    if (m_tag == tag) {
        return;
    }

    m_tag = tag;
    Q_EMIT tagChanged();

    slotPopulate();
}

void ImageTagsModel::slotPopulate()
{
    if (m_tag.isEmpty()) {
        return;
    }

    beginResetModel();
    m_images = ImageStorage::instance()->imagesForTag(m_tag);
    endResetModel();
}
