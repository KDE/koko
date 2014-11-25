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
#include <KConfigGroup>

#include <QGeoCoordinate>
#include <QGeoAddress>
#include <QDataStream>
#include <QDebug>

ImageStorage::ImageStorage(QObject* parent)
    : QObject(parent)
    , m_config("gallerystorage")
{
}

ImageStorage::~ImageStorage()
{

}

bool ImageStorage::hasImage(const QString& path)
{
    return m_config.groupList().contains(path);
}

QList<ImageInfo> ImageStorage::images()
{
    QList<ImageInfo> list;
    QStringList groups = m_config.groupList();
    for (const QString& group : groups) {
        KConfigGroup kg = m_config.group(group);

        ImageInfo ii;
        ii.path = group;
        ii.date = kg.readEntry("date", QDate());

        double lat = kg.readEntry("loc_lat", static_cast<double>(0.0));
        double lon = kg.readEntry("loc_lon", static_cast<double>(0.0));
        double alt = kg.readEntry("loc_alt", static_cast<double>(0.0));

        ii.location.coordinate().setLatitude(lat);
        ii.location.coordinate().setLongitude(lon);
        ii.location.coordinate().setAltitude(alt);

        QByteArray arr = kg.readEntry("loc_addr", QByteArray());
        QDataStream stream(&arr, QIODevice::ReadOnly);
        QGeoAddress addr;
        stream >> addr;
        ii.location.setAddress(addr);

        list << ii;
    }

    return list;
}

void ImageStorage::addImage(const ImageInfo& ii)
{
    KConfigGroup kg = m_config.group(ii.path);
    kg.writeEntry("date", ii.date);
    kg.writeEntry("loc_lat", ii.location.coordinate().latitude());
    kg.writeEntry("loc_lon", ii.location.coordinate().longitude());
    kg.writeEntry("loc_alt", ii.location.coordinate().altitude());

    QByteArray arr;
    QDataStream st(&arr, QIODevice::WriteOnly);
    st << ii.location.address();

    kg.writeEntry("loc_addr", arr);
    kg.sync();
}

QDataStream& operator<<(QDataStream& stream, const QGeoAddress& addr)
{
    stream << addr.city() << addr.country() << addr.countryCode() << addr.district()
           << addr.postalCode() << addr.state() << addr.street() << addr.text();

    return stream;
}

QDataStream& operator>>(QDataStream& stream, QGeoAddress& addr)
{
    QString city;
    stream >> city;
    addr.setCity(city);

    QString country;
    stream >> country;
    addr.setCountry(country);

    QString countryCode;
    stream >> countryCode;
    addr.setCountryCode(countryCode);

    QString district;
    stream >> district;
    addr.setDistrict(district);

    QString postalCode;
    stream >> postalCode;
    addr.setPostalCode(postalCode);

    QString state;
    stream >> state;
    addr.setState(state);

    QString street;
    stream >> street;
    addr.setStreet(street);

    QString text;
    stream >> text;
    addr.setText(text);

    return stream;
}
