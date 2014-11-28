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

#ifndef REVERSEGEOCODELOOKUPJOB_H
#define REVERSEGEOCODELOOKUPJOB_H

#include <QObject>
#include <QGeoLocation>
#include <QGeoCoordinate>
#include <QGeoAddress>
#include <QNetworkAccessManager>

class ReverseGeoCodeLookupJob : public QObject
{
    Q_OBJECT
public:
    ReverseGeoCodeLookupJob(const QGeoCoordinate& coords, QObject* parent = 0);
    virtual ~ReverseGeoCodeLookupJob();

    void start();

signals:
    void result(const QGeoLocation& location);

private slots:
    void finished(QNetworkReply* reply);

private:
    QGeoCoordinate m_coords;
    QNetworkAccessManager m_manager;
};

#endif // REVERSEGEOCODELOOKUPJOB_H
