/*
 *   Copyright 2017 by Atul Sharma <atulsharma406@gmail.com>
 * 
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "imagelistmodel.h"
#include "roles.h"
#include "imagestorage.h"

#include <QMimeDatabase>
#include <QDebug>

ImageListModel::ImageListModel(QObject* parent)
    : QAbstractListModel(parent)
{
    connect(this, &ImageListModel::locationGroupChanged, 
            this, &ImageListModel::slotLocationGroupChanged);
    connect(this, &ImageListModel::timeGroupChanged, 
            this, &ImageListModel::slotTimeGroupChanged);
    connect(this, &ImageListModel::queryChanged, 
            this, &ImageListModel::slotResetModel);
    
    connect(ImageStorage::instance(), &ImageStorage::storageModified, 
            this, &ImageListModel::slotResetModel);
}

ImageListModel::~ImageListModel()
{
}

QHash<int, QByteArray> ImageListModel::roleNames() const
{
    QHash<int, QByteArray> hash = QAbstractListModel::roleNames();
    hash.insert( Roles::ImageUrlRole, "imageurl");
    hash.insert( Roles::ItemTypeRole, "itemType");
    
    return hash;
}

QVariant ImageListModel::data(const QModelIndex& index, int role) const
{
    if( !index.isValid()) {
        return QVariant();
    }
    
    int indexValue = index.row();
    
    switch( role) {
        case Qt::DisplayRole:
            //TODO: return the filename component
            return m_images.at(indexValue);
           
        case Roles::ImageUrlRole:
            return m_images.at(indexValue);
            
        case Roles::ItemTypeRole:
            return Types::Image;
            
    }
    
    return QVariant();
}

int ImageListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent)
    return m_images.size();
}

void ImageListModel::slotLocationGroupChanged()
{
    if( m_locationGroup != -1) {
        m_locations = ImageStorage::instance()->locations( static_cast<Types::LocationGroup>(m_locationGroup));
        m_queryType = Types::LocationQuery;
    }
}

void ImageListModel::slotTimeGroupChanged()
{
    if( m_timeGroup != -1) {
        m_times = ImageStorage::instance()->timeTypes( static_cast<Types::TimeGroup>(m_timeGroup));
        m_queryType = Types::TimeQuery;
    }
}

void ImageListModel::slotResetModel()
{
    beginResetModel();
    if(m_queryType == Types::LocationQuery) {
        m_images = ImageStorage::instance()->imagesForLocation( m_query, static_cast<Types::LocationGroup>(m_locationGroup));
    } else if (m_queryType == Types::TimeQuery) {
        m_images = ImageStorage::instance()->imagesForTime( m_query, static_cast<Types::TimeGroup>(m_timeGroup));
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

void ImageListModel::setQueryType(const Types::QueryType& type)
{
    m_queryType = type;
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

QByteArray ImageListModel::queryForIndex(const QModelIndex &index)
{
    if(m_queryType == Types::LocationQuery) {
        return m_locations.at( index.row()).first;
    } else if( m_queryType == Types::TimeQuery) {
        return m_times.at( index.row()).first;
    }
    return QByteArray();
}

#include "moc_imagelistmodel.cpp"
