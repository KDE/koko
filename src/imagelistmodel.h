/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef IMAGELISTMODEL_H
#define IMAGELISTMODEL_H

#include <QAbstractListModel>

#include "openfilemodel.h"

class ImageListModel : public OpenFileModel
{
    Q_OBJECT

    Q_PROPERTY(Types::LocationGroup locationGroup READ locationGroup WRITE setLocationGroup NOTIFY locationGroupChanged)
    Q_PROPERTY(Types::TimeGroup timeGroup READ timeGroup WRITE setTimeGroup NOTIFY timeGroupChanged)
    Q_PROPERTY(Types::QueryType queryType READ queryType WRITE setQueryType NOTIFY queryTypeChanged)
    Q_PROPERTY(QByteArray query READ query WRITE setQuery NOTIFY queryChanged)

public:
    explicit ImageListModel(QObject *parent = nullptr);
    ~ImageListModel();

    Types::LocationGroup locationGroup() const;
    void setLocationGroup(const Types::LocationGroup &group);

    Types::TimeGroup timeGroup() const;
    void setTimeGroup(const Types::TimeGroup &group);

    Types::QueryType queryType() const;
    void setQueryType(const Types::QueryType &type);

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
    void queryTypeChanged();
    void queryChanged();

private:
    Types::LocationGroup m_locationGroup;
    Types::TimeGroup m_timeGroup;
    Types::QueryType m_queryType;
    QByteArray m_query;

    QList<QPair<QByteArray, QString>> m_times;
    QList<QPair<QByteArray, QString>> m_locations;
};

#endif
