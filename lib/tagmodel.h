/*
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

#ifndef TAGMODEL_H
#define TAGMODEL_H

#include <QAbstractListModel>

class TagModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QStringList tags READ tags WRITE setTags)

public:
    TagModel(QObject* parent = 0);

    enum Roles {
        ColorRole = Qt::UserRole + 1
    };

    virtual QHash<int, QByteArray> roleNames() const;
    virtual QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const;
    virtual int rowCount(const QModelIndex& parent = QModelIndex()) const;

public slots:
    virtual bool removeRows(int row, int count, const QModelIndex& parent = QModelIndex());

    QStringList tags() const;
    void setTags(const QStringList& tags);
    void addTag(const QString& tag);

private:
    QStringList m_tags;
};

#endif // TAGMODEL_H
