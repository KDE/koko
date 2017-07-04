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
#include "types.h"
#include "roles.h"

#include <QMimeDatabase>
#include <QDebug>

ImageListModel::ImageListModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

ImageListModel::~ImageListModel()
{
}

QHash<int, QByteArray> ImageListModel::roleNames() const
{
    QHash<int, QByteArray> hash = QAbstractListModel::roleNames();
    hash.insert( Roles::ImageUrlRole, "imageurl");
    hash.insert( Roles::MimeTypeRole, "mimeType");
    hash.insert( Roles::ItemTypeRole, "itemType");
    
    return hash;
}

QVariant ImageListModel::data(const QModelIndex& index, int role) const
{
    if( !index.isValid()) {
        return QVariant();
    }
    
    int indexValue = index.row();
    QMimeDatabase db;
    QMimeType type = db.mimeTypeForFile(m_images.at(indexValue));
    
    switch( role) {
        case Qt::DisplayRole:
            //TODO: return the filename component
            return m_images.at(indexValue);
           
        case Roles::ImageUrlRole:
            return m_images.at(indexValue);
            
        case Roles::MimeTypeRole:
            return type.name();
            
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

QStringList ImageListModel::imageList() const
{
    return m_images;
}

void ImageListModel::setImageList(QStringList images)
{
    m_images = images;
    emit imageListChanged();
}

#include "moc_imagelistmodel.cpp"
