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

#include "imagestorage.h"

#include <QDebug>
#include <QGeoCoordinate>
#include <QGeoAddress>
#include <QDataStream>

#include <QStandardPaths>
#include <QDir>

#include <KVariantStore/KVariantQuery>

ImageStorage::ImageStorage(QObject* parent)
    : QObject(parent)
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/gallery";
    QDir().mkpath(dir);

    m_db.setPath(dir + "/db");
    if (!m_db.open()) {
        qDebug() << "Could not open db";
        return;
    }

    m_coll = m_db.collection("images");
}

ImageStorage::~ImageStorage()
{

}

bool ImageStorage::hasImage(const QString& path)
{
    QVariantMap map{{"path", path}};
    return !m_coll.findOne(map).isEmpty();
}

QList<ImageInfo> ImageStorage::images()
{
    QList<ImageInfo> list;

    auto query = m_coll.find(QVariantMap());
    while (query.next()) {
        QVariantMap map = query.result();

        ImageInfo ii;
        ii.path = map.value("path").toString();
        ii.date = map.value("dt").toDateTime();

        ii.location.coordinate().setLatitude(map.value("lat").toDouble());
        ii.location.coordinate().setLongitude(map.value("lon").toDouble());
        ii.location.coordinate().setAltitude(map.value("alt").toDouble());

        QGeoAddress addr;
        addr.setCity(map.value("city").toString());
        addr.setCountry(map.value("country").toString());
        addr.setCountryCode(map.value("countryCode").toString());
        addr.setDistrict(map.value("district").toString());
        addr.setPostalCode(map.value("postalCode").toString());
        addr.setState(map.value("state").toString());
        addr.setStreet(map.value("street").toString());
        addr.setText(map.value("text").toString());

        ii.location.setAddress(addr);

        list << ii;
    }

    return list;
}

void ImageStorage::addImage(const ImageInfo& ii)
{
    QVariantMap map;
    map["path"] = ii.path;
    map["dt"] = ii.date;
    map["lat"] = ii.location.coordinate().latitude();
    map["lon"] = ii.location.coordinate().longitude();
    map["alt"] = ii.location.coordinate().altitude();

    QGeoAddress addr = ii.location.address();
    map["city"] = addr.city();
    map["country"] = addr.country();
    map["countryCode"] = addr.countryCode();
    map["district"] = addr.district();
    map["postalCode"] = addr.postalCode();
    map["state"] = addr.state();
    map["street"] = addr.street();
    map["text"] = addr.text();

    m_coll.insert(map);
}
