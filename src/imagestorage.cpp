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

#include "imagestorage.h"

#include <QDebug>
#include <QGeoCoordinate>
#include <QGeoAddress>
#include <QDataStream>

#include <QStandardPaths>
#include <QDir>

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>

ImageStorage::ImageStorage(QObject* parent)
    : QObject(parent)
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/koko";
    QDir().mkpath(dir);

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    db.setDatabaseName(dir + "/imageData.sqlite3");

    if (!db.open()) {
        qDebug() << "Failed to open db" << db.lastError().text();
        return;
    }

    if (db.tables().contains("files")) {
        return;
    }

    QSqlQuery query(db);
    query.exec("CREATE TABLE locations (id INTEGER PRIMARY KEY, country TEXT, state TEXT, city TEXT)");
    query.exec("CREATE TABLE files (url TEXT NOT NULL UNIQUE PRIMARY KEY,"
               "                    location INTEGER,"
               "                    dateTime STRING,"
               "                    FOREIGN KEY(location) REFERENCES locations(id)"
               "                    )");
}

ImageStorage::~ImageStorage()
{
    QString name;
    {
        QSqlDatabase db = QSqlDatabase::database();
        name = db.connectionName();
    }
    QSqlDatabase::removeDatabase(name);
}

ImageStorage* ImageStorage::instance()
{
    static ImageStorage storage;
    return &storage;
}

QList<ImageInfo> ImageStorage::images()
{
    QList<ImageInfo> list;

    /*
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
    */

    return list;
}

void ImageStorage::addImage(const ImageInfo& ii)
{
    QGeoAddress addr = ii.location.address();

    if (!addr.country().isEmpty()) {
        QSqlQuery query;
        query.prepare("INSERT INTO LOCATIONS(country, state, city) VALUES (?, ?, ?)");
        query.addBindValue(addr.country());
        query.addBindValue(addr.state());
        query.addBindValue(addr.city());
        if (!query.exec()) {
            qDebug() << "LOC INSERT" << query.lastError();
        }

        int locId = query.lastInsertId().toInt();

        query.prepare("INSERT INTO FILES(url, location, dateTime) VALUES(?, ?, ?)");
        query.addBindValue(ii.path);
        query.addBindValue(locId);
        query.addBindValue(ii.date.toString(Qt::ISODate));
        if (!query.exec()) {
            qDebug() << "FILE LOC INSERT" << query.lastError();
        }
    }
    else {
        QSqlQuery query;
        query.prepare("INSERT INTO FILES(url, dateTime) VALUES(?, ?)");
        query.addBindValue(ii.path);
        query.addBindValue(ii.date.toString(Qt::ISODate));
        if (!query.exec()) {
            qDebug() << "FILE INSERT" << query.lastError();
        }
    }
}

QStringList ImageStorage::locations(ImageStorage::LocationGroup loca)
{

    return QStringList();
}

QStringList ImageStorage::imagesForLocation(const QString& name, ImageStorage::LocationGroup loc)
{

    return QStringList();
}

QStringList ImageStorage::timeGroups(ImageStorage::TimeGroup group)
{
    QSqlQuery query;
    if (group == Year) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return QStringList();
        }

        QStringList groups;
        while (query.next()) {
            groups << query.value(0).toString();
        }
        return groups;
    }
    else if (group == Month) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime), strftime('%m', dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return QStringList();
        }

        QStringList groups;
        while (query.next()) {
            QString year = query.value(0).toString();
            int month = query.value(1).toInt();

            qDebug() << year << month;
            groups << QDate::longMonthName(month) + ", " + year;
        }
        return groups;
    }
    else if (group == Week) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime), strftime('%m', dateTime), strftime('%W', dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return QStringList();
        }

        QStringList groups;
        while (query.next()) {
            QString year = query.value(0).toString();
            int month = query.value(1).toInt();
            int week = query.value(1).toInt();

            groups << "Week " + QString::number(week) + ", " + QDate::longMonthName(month) + ", " + year;
        }
        return groups;
    }
    else if (group == Day) {
        query.prepare("SELECT DISTINCT date(dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return QStringList();
        }

        QStringList groups;
        while (query.next()) {
            QDate date = query.value(0).toDate();

            groups << date.toString(Qt::SystemLocaleLongDate);
        }
        return groups;
    }

    Q_ASSERT(0);
    return QStringList();
}

QStringList ImageStorage::imagesForTime(const QString& name, ImageStorage::TimeGroup& group)
{
    QSqlQuery query;
    if (group == Year) {
        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ?");
        query.addBindValue(name);
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return QStringList();
        }

        QStringList files;
        while (query.next()) {
            files << query.value(0).toString();
        }
        return files;
    }
    else if (group == Month) {
        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%m', dateTime) = ?");

        QTextStream stream(&name);
        query.addBindValue(name);
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return QStringList();
        }

        QStringList files;
        while (query.next()) {
            files << query.value(0).toString();
        }
        return files;
    }
    else if (group == Week) {
    }
    else if (group == Day) {
    }

    return QStringList();
}

QStringList ImageStorage::folders() const
{

    return QStringList();
}

QStringList ImageStorage::imagesForFolders(const QString& folder) const
{
    return QStringList();
}
