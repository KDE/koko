/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagetagsmodel.h"
#include "imagestorage.h"

ImageTagsModel::ImageTagsModel(QObject *parent)
    : OpenFileModel({}, parent)
    , m_tag(QString())
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageTagsModel::slotPopulate);
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
