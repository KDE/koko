/*
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
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

#include "types.h"

class ImageTimeModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Types::TimeGroup group READ group WRITE setGroup NOTIFY groupChanged)
public:
    explicit ImageTimeModel(QObject* parent = 0);

    QHash< int, QByteArray > roleNames() const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole)     const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;

    Types::TimeGroup group() const;
    void setGroup(Types::TimeGroup group);

signals:
    void groupChanged();
    
private slots:
    void slotPopulate();

private:
    Types::TimeGroup m_group;
    QList< QPair<QByteArray, QString> > m_times;
};

#endif
