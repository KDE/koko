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

#ifndef JUNGLE_SORTMODEL_H
#define JUNGLE_SORTMODEL_H

#include <QSortFilterProxyModel>
#include <QItemSelectionModel>

namespace Jungle {

class SortModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QByteArray sortRoleName READ sortRoleName WRITE setSortRoleName)
public:
    explicit SortModel(QObject* parent = 0);
    virtual ~SortModel();

    QByteArray sortRoleName() const;
    void setSortRoleName(const QByteArray& name);

    virtual void setSourceModel(QAbstractItemModel* sourceModel);
    
    Q_INVOKABLE void setSelected( int indexValue);
    Q_INVOKABLE void toggleSelected( int indexValue);

private:
    QByteArray m_sortRoleName;
    QItemSelectionModel *m_selectionModel;
};
}

#endif // JUNGLE_SORTMODEL_H
