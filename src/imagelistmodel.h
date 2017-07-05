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

#ifndef IMAGELISTMODEL_H
#define IMAGELISTMODEL_H

#include <QAbstractListModel>

class ImageListModel : public QAbstractListModel
{
    Q_OBJECT
    
    /*
     * imageList property is used to store the images of a particular collection
     */
    Q_PROPERTY(QStringList imageList READ imageList WRITE setImageList NOTIFY imageListChanged)
    
public:
    explicit ImageListModel(QObject* parent = 0);
    ~ImageListModel();
    
    virtual QHash< int, QByteArray > roleNames() const;
    virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    virtual int rowCount(const QModelIndex& parent = QModelIndex()) const;
    
    QStringList imageList() const;
    void setImageList(QStringList images);
    
Q_SIGNALS:
    void imageListChanged();
    
private:
    QStringList m_images;
};

#endif
