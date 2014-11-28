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

#include "reversegeocodelookupjob.h"

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrlQuery>
#include <QDebug>

#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonObject>

ReverseGeoCodeLookupJob::ReverseGeoCodeLookupJob(const QGeoCoordinate& coords, QObject* parent)
    : QObject(parent)
    , m_coords(coords)
{
    connect(&m_manager, SIGNAL(finished(QNetworkReply*)),
            this, SLOT(finished(QNetworkReply*)));
}

ReverseGeoCodeLookupJob::~ReverseGeoCodeLookupJob()
{
}

void ReverseGeoCodeLookupJob::start()
{
    QUrlQuery query;
    query.addQueryItem("format", "json");
    query.addQueryItem("lat", QString::number(m_coords.latitude()));
    query.addQueryItem("lon", QString::number(m_coords.longitude()));
    query.addQueryItem("addressdetails", "1");
    query.addQueryItem("email", "vhanda@kde.org");

    QUrl url("http://nominatim.openstreetmap.org/reverse");
    url.setQuery(query);

    QNetworkRequest request(url);
    m_manager.get(request);
}

void ReverseGeoCodeLookupJob::finished(QNetworkReply* reply)
{
    QGeoLocation location;
    location.setCoordinate(m_coords);

    if (reply->error() != QNetworkReply::NoError) {
        emit result(location);
        deleteLater();
        return;
    }

    QByteArray data = reply->readAll();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);
    if (error.error) {
        qDebug() << "JSON parsing error" << error.errorString();
        emit result(location);
        deleteLater();
        return;
    }

    const QVariantMap map = doc.object().toVariantMap();
    if (!map.contains("address")) {
        qDebug() << "No address found for" << m_coords;
        emit result(location);
        deleteLater();
        return;
    }

    const QVariantMap add = map.value("address").toMap();

    QGeoAddress address;
    address.setText(map.value("display_name").toString());
    address.setCity(add.value("city").toString());
    address.setCountry(add.value("country").toString());
    address.setCountryCode(add.value("country_code").toString());
    address.setState(add.value("state").toString());
    address.setPostalCode(add.value("postcode").toString());
    address.setDistrict(add.value("suburb").toString());

    location.setAddress(address);
    emit result(location);
    deleteLater();
}

