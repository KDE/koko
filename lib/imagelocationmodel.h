/*
 * <one line to give the library's name and an idea of what it does.>
 * Copyright (C) 2014  Vishesh Handa <me@vhanda.in>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifndef IMAGELOCATIONMODEL_H
#define IMAGELOCATIONMODEL_H

#include <QAbstractListModel>
#include <QStringList>
#include <QGeoLocation>

#include "imagelocationcategorizer.h"

class ImageLocationModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit ImageLocationModel(QObject* parent = 0);

    enum Roles {
        FilePathRole = Qt::UserRole + 1
    };

    virtual QHash< int, QByteArray > roleNames() const;
    virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    virtual int rowCount(const QModelIndex& parent = QModelIndex()) const;

private:
    ImageLocationCategorizer m_categorizer;
};

#endif // IMAGELOCATIONMODEL_H
