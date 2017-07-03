/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
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

class ImageLocationModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(LocationGroup group READ group WRITE setGroup NOTIFY groupChanged)
public:
    explicit ImageLocationModel(QObject* parent = 0);

    virtual QHash< int, QByteArray > roleNames() const;
    virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    virtual int rowCount(const QModelIndex& parent = QModelIndex()) const;

    enum LocationGroup {
        Country,
        State,
        City
    };
    Q_ENUMS(LocationGroup)

    LocationGroup group() const;
    void setGroup(LocationGroup group);

signals:
    void groupChanged();

public slots:
    void removeImage(const QString& path, int index );
    
private slots:
    void slotPopulate();

private:
    LocationGroup m_group;
    QList<QPair<QByteArray, QString> > m_locations;
};

#endif // IMAGELOCATIONMODEL_H
