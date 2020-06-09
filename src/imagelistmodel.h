/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.0-or-later
 */

#ifndef IMAGELISTMODEL_H
#define IMAGELISTMODEL_H

#include <QAbstractListModel>

#include "types.h"

class ImageListModel : public QAbstractListModel
{
    Q_OBJECT
    
    Q_PROPERTY(Types::LocationGroup locationGroup READ locationGroup WRITE setLocationGroup NOTIFY locationGroupChanged)
    Q_PROPERTY(Types::TimeGroup timeGroup READ timeGroup WRITE setTimeGroup NOTIFY timeGroupChanged)
    Q_PROPERTY(Types::QueryType queryType READ queryType WRITE setQueryType)
    Q_PROPERTY(QByteArray query READ query WRITE setQuery NOTIFY queryChanged)
    
public:
    explicit ImageListModel(QObject* parent = 0);
    ~ImageListModel();
    
    QHash< int, QByteArray > roleNames() const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    
    Types::LocationGroup locationGroup() const;
    void setLocationGroup(const Types::LocationGroup &group);
    
    Types::TimeGroup timeGroup() const;
    void setTimeGroup(const Types::TimeGroup &group);
    
    Types::QueryType queryType() const;
    void setQueryType( const Types::QueryType &type);
    
    QByteArray query() const;
    void setQuery(const QByteArray &statement);
    
    Q_INVOKABLE QByteArray queryForIndex(const int &index);
    
    void slotLocationGroupChanged();
    void slotTimeGroupChanged();
    void slotResetModel();
    
Q_SIGNALS:
    void imageListChanged();
    void locationGroupChanged();
    void timeGroupChanged();
    void queryChanged();
    
private:
    QStringList m_images;
    Types::LocationGroup m_locationGroup;
    Types::TimeGroup m_timeGroup;
    Types::QueryType m_queryType;
    QByteArray m_query;
    
    QList< QPair<QByteArray, QString> > m_times;
    QList< QPair<QByteArray, QString> > m_locations;
};

#endif
