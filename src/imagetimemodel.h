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

#ifndef IMAGETIMEMODEL_H
#define IMAGETIMEMODEL_H

#include <QAbstractListModel>
#include <QStringList>

class ImageTimeModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(TimeGroup group READ group WRITE setGroup NOTIFY groupChanged)
public:
    explicit ImageTimeModel(QObject* parent = 0);

    virtual QHash< int, QByteArray > roleNames() const;
    virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    virtual int rowCount(const QModelIndex& parent = QModelIndex()) const;

    enum TimeGroup {
        Year,
        Month,
        Week,
        Day
    };
    Q_ENUMS(TimeGroup)

    TimeGroup group() const;
    void setGroup(TimeGroup group);

signals:
    void groupChanged();

public slots:
    void removeImage(const QString& path, int index );
    
private slots:
    void slotPopulate();

private:
    TimeGroup m_group;
    QList< QPair<QByteArray, QString> > m_times;
};

#endif
