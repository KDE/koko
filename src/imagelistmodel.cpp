/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "imagelistmodel.h"
#include "imagestorage.h"
#include "roles.h"

#include <QDebug>
#include <QMimeDatabase>

ImageListModel::ImageListModel(QObject *parent)
    : OpenFileModel({}, parent)
{
    connect(this, &ImageListModel::locationGroupChanged, this, &ImageListModel::slotLocationGroupChanged);
    connect(this, &ImageListModel::timeGroupChanged, this, &ImageListModel::slotTimeGroupChanged);
    connect(this, &ImageListModel::queryChanged, this, &ImageListModel::slotResetModel);

    connect(ImageStorage::instance(), &ImageStorage::storageModified, this, &ImageListModel::slotResetModel);
}

ImageListModel::~ImageListModel()
{
}

void ImageListModel::slotLocationGroupChanged()
{
    if (m_locationGroup != -1) {
        m_locations = ImageStorage::instance()->locations(static_cast<Types::LocationGroup>(m_locationGroup));
        m_queryType = Types::LocationQuery;
        emit queryTypeChanged();
    }
}

void ImageListModel::slotTimeGroupChanged()
{
    if (m_timeGroup != -1) {
        m_times = ImageStorage::instance()->timeTypes(static_cast<Types::TimeGroup>(m_timeGroup));
        m_queryType = Types::TimeQuery;
        emit queryTypeChanged();
    }
}

void ImageListModel::slotResetModel()
{
    beginResetModel();
    if (m_queryType == Types::LocationQuery) {
        m_images = ImageStorage::instance()->imagesForLocation(m_query, static_cast<Types::LocationGroup>(m_locationGroup));
    } else if (m_queryType == Types::TimeQuery) {
        m_images = ImageStorage::instance()->imagesForTime(m_query, static_cast<Types::TimeGroup>(m_timeGroup));
    }
    endResetModel();
}

Types::LocationGroup ImageListModel::locationGroup() const
{
    return m_locationGroup;
}

void ImageListModel::setLocationGroup(const Types::LocationGroup &group)
{
    m_locationGroup = group;
    emit locationGroupChanged();
}

Types::TimeGroup ImageListModel::timeGroup() const
{
    return m_timeGroup;
}

void ImageListModel::setTimeGroup(const Types::TimeGroup &group)
{
    m_timeGroup = group;
    emit timeGroupChanged();
}

Types::QueryType ImageListModel::queryType() const
{
    return m_queryType;
}

void ImageListModel::setQueryType(const Types::QueryType &type)
{
    m_queryType = type;
    emit queryTypeChanged();
}

QByteArray ImageListModel::query() const
{
    return m_query;
}
void ImageListModel::setQuery(const QByteArray &statement)
{
    m_query = statement;
    emit queryChanged();
}

QByteArray ImageListModel::queryForIndex(const int &index)
{
    if (m_queryType == Types::LocationQuery) {
        return m_locations.at(index).first;
    } else if (m_queryType == Types::TimeQuery) {
        return m_times.at(index).first;
    }
    return QByteArray();
}

#include "moc_imagelistmodel.cpp"
