/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagetagsmodel.h"
#include "imagestorage.h"
#include "roles.h"

#include <kio/copyjob.h>
#include <kio/jobuidelegate.h>

ImageTagsModel::ImageTagsModel(QObject *parent)
    : OpenFileModel({}, parent)
    , m_tag(QString())
{
    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageTagsModel::slotPopulate);
    populateTags();
}

QString ImageTagsModel::tag() const
{
    return m_tag;
}

QStringList ImageTagsModel::tags() const
{
    return m_tags;
}

void ImageTagsModel::setTag(const QString &tag)
{
    if (m_tag == tag) {
        return;
    }

    m_tag = tag;

    emit tagChanged();

    slotPopulate();
}

void ImageTagsModel::slotPopulate()
{
    populateTags();

    if (m_tag == "") {
        return;
    }

    beginResetModel();
    m_images = ImageStorage::instance()->imagesForTag(m_tag);
    endResetModel();
}

void ImageTagsModel::populateTags()
{
    const QStringList tags = ImageStorage::instance()->tags();
    if (m_tags == tags) {
        return;
    }

    m_tags = tags;
    emit tagsChanged();
}
