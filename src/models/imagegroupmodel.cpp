/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagegroupmodel.h"
#include "imagestorage.h"

#include <QDebug>
#include <QMimeDatabase>

ImageGroupModel::ImageGroupModel(QObject *parent)
    : AbstractImageModel(parent)
{
    connect(this, &ImageGroupModel::locationGroupChanged, this, &ImageGroupModel::slotLocationGroupChanged);
    connect(this, &ImageGroupModel::timeGroupChanged, this, &ImageGroupModel::slotTimeGroupChanged);
    connect(this, &ImageGroupModel::queryChanged, this, &ImageGroupModel::slotResetModel);

    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageGroupModel::slotResetModel);
}

ImageGroupModel::~ImageGroupModel() = default;

void ImageGroupModel::slotLocationGroupChanged()
{
    if (m_locationGroup == ImageStorage::LocationGroup::NotSet) {
        return;
    }

    m_locations = ImageStorage::instance()->locations(m_locationGroup);
    m_queryType = ImageStorage::QueryType::Location;
    Q_EMIT queryTypeChanged();
}

void ImageGroupModel::slotTimeGroupChanged()
{
    if (m_timeGroup == ImageStorage::TimeGroup::NotSet) {
        return;
    }
    m_times = ImageStorage::instance()->timeTypes(m_timeGroup);
    m_queryType = ImageStorage::QueryType::Time;
    Q_EMIT queryTypeChanged();
}

void ImageGroupModel::slotResetModel()
{
    beginResetModel();
    if (m_queryType == ImageStorage::QueryType::Location) {
        m_images = ImageStorage::instance()->imagesForLocation(m_query, m_locationGroup);
    } else if (m_queryType == ImageStorage::QueryType::Time) {
        m_images = ImageStorage::instance()->imagesForTime(m_query, m_timeGroup);
    }
    endResetModel();
}

ImageStorage::LocationGroup ImageGroupModel::locationGroup() const
{
    return m_locationGroup;
}

void ImageGroupModel::setLocationGroup(const ImageStorage::LocationGroup &group)
{
    if (m_locationGroup == group) {
        return;
    }
    m_locationGroup = group;
    Q_EMIT locationGroupChanged();
}

ImageStorage::TimeGroup ImageGroupModel::timeGroup() const
{
    return m_timeGroup;
}

void ImageGroupModel::setTimeGroup(const ImageStorage::TimeGroup &group)
{
    if (m_timeGroup == group) {
        return;
    }
    m_timeGroup = group;
    Q_EMIT timeGroupChanged();
}

ImageStorage::QueryType ImageGroupModel::queryType() const
{
    return m_queryType;
}

void ImageGroupModel::setQueryType(const ImageStorage::QueryType &type)
{
    if (m_queryType == type) {
        return;
    }
    m_queryType = type;
    Q_EMIT queryTypeChanged();
}

QByteArray ImageGroupModel::query() const
{
    return m_query;
}
void ImageGroupModel::setQuery(const QByteArray &statement)
{
    if (m_query == statement) {
        return;
    }
    m_query = statement;
    Q_EMIT queryChanged();
}

QByteArray ImageGroupModel::queryForIndex(const int &index)
{
    if (m_queryType == ImageStorage::QueryType::Location) {
        return m_locations.at(index).key;
    } else if (m_queryType == ImageStorage::QueryType::Time) {
        return m_times.at(index).key;
    }
    return QByteArray();
}

QVariant ImageGroupModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));
    return dataFromItem(m_images.at(index.row()), role);
}

int ImageGroupModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_images.size();
}

#include "moc_imagegroupmodel.cpp"
