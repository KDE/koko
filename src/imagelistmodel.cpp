/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.0-or-later
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
    hash.insert( Roles::MimeTypeRole, "mimeType");
    
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
            
        case Roles::MimeTypeRole: {
            QMimeDatabase db;
            QMimeType type = db.mimeTypeForFile( m_images.at(indexValue));
            return type.name();
        }
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

QByteArray ImageListModel::queryForIndex(const int& index)
{
    if(m_queryType == Types::LocationQuery) {
        return m_locations.at( index).first;
    } else if( m_queryType == Types::TimeQuery) {
        return m_times.at( index).first;
    }
    return QByteArray();
}

#include "moc_imagelistmodel.cpp"
