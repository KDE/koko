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
#include <QUrl>

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
        db.transaction();
        return;
    }

    QSqlQuery query(db);
    query.exec("CREATE TABLE locations (id INTEGER PRIMARY KEY, country TEXT, state TEXT, city TEXT"
               "                        , UNIQUE(country, state, city) ON CONFLICT REPLACE"
               ")");
    query.exec("CREATE TABLE files (url TEXT NOT NULL UNIQUE PRIMARY KEY,"
               "                    location INTEGER,"
               "                    dateTime STRING,"
               "                    FOREIGN KEY(location) REFERENCES locations(id)"
               "                    )");

    db.transaction();
}

ImageStorage::~ImageStorage()
{
    QString name;
    {
        QSqlDatabase db = QSqlDatabase::database();
        db.commit();
        name = db.connectionName();
    }
    QSqlDatabase::removeDatabase(name);
}

ImageStorage* ImageStorage::instance()
{
    static ImageStorage storage;
    return &storage;
}

void ImageStorage::addImage(const ImageInfo& ii)
{
    QMutexLocker lock(&m_mutex);
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
        query.addBindValue(ii.dateTime.toString(Qt::ISODate));
        if (!query.exec()) {
            qDebug() << "FILE LOC INSERT" << query.lastError();
        }
    }
    else {
        QSqlQuery query;
        query.prepare("INSERT INTO FILES(url, dateTime) VALUES(?, ?)");
        query.addBindValue(ii.path);
        query.addBindValue(ii.dateTime.toString(Qt::ISODate));
        if (!query.exec()) {
            qDebug() << "FILE INSERT" << query.lastError();
        }
    }
}

void ImageStorage::commit()
{
    QMutexLocker lock(&m_mutex);
    QSqlDatabase db = QSqlDatabase::database();
    db.commit();
    db.transaction();
}

QList<QPair<QByteArray, QString> > ImageStorage::locations(ImageStorage::LocationGroup loca)
{
    QMutexLocker lock(&m_mutex);
    QList< QPair<QByteArray, QString> > list;

    if (loca == Country) {
        QSqlQuery query;
        query.prepare("SELECT DISTINCT country from locations");

        if (!query.exec()) {
            qDebug() << loca << query.lastError();
            return list;
        }

        while (query.next()) {
            QString val = query.value(0).toString();
            list << qMakePair(val.toUtf8(), val);
        }
        return list;
    }
    else if (loca == State) {
        QSqlQuery query;
        query.prepare("SELECT DISTINCT country, state from locations");

        if (!query.exec()) {
            qDebug() << loca << query.lastError();
            return list;
        }

        QStringList groups;
        while (query.next()) {
            QString country = query.value(0).toString();
            QString state = query.value(1).toString();
            QString display = state + ", " + country;

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << country << state;

            list << qMakePair(key, display);
        }
        return list;
    }
    else if (loca == City) {
        QSqlQuery query;
        query.prepare("SELECT DISTINCT country, state, city from locations");

        if (!query.exec()) {
            qDebug() << loca << query.lastError();
            return list;
        }

        while (query.next()) {
            QString country = query.value(0).toString();
            QString state = query.value(1).toString();
            QString city = query.value(2).toString();

            QString display;
            if (!city.isEmpty()) {
                display = city + ", " + state + ", " + country;
            } else {
                display = state + ", " + country;
            }

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << country << state << city;

            list << qMakePair(key, display);
        }
        return list;
    }

    return list;
}

QStringList ImageStorage::imagesForLocation(const QByteArray& name, ImageStorage::LocationGroup loc)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (loc == Country) {
        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND files.location = locations.id");
        query.addBindValue(QString::fromUtf8(name));
    }
    else if (loc == State) {
        QDataStream st(name);

        QString country;
        QString state;
        st >> country >> state;

        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND state = ? AND files.location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
        qDebug() << country << state;
    }
    else if (loc == City) {
        QDataStream st(name);

        QString country;
        QString state;
        QString city;
        st >> country >> state >> city;

        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND state = ? AND files.location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    }

    if (!query.exec()) {
        qDebug() << loc << query.lastError();
        return QStringList();
    }

    QStringList files;
    while (query.next()) {
        files << query.value(0).toString();
    }
    return files;
}

QString ImageStorage::imageForLocation(const QByteArray& name, ImageStorage::LocationGroup loc)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (loc == Country) {
        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND files.location = locations.id");
        query.addBindValue(QString::fromUtf8(name));
    }
    else if (loc == State) {
        QDataStream st(name);

        QString country;
        QString state;
        st >> country >> state;

        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND state = ? AND files.location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    }
    else if (loc == City) {
        QDataStream st(name);

        QString country;
        QString state;
        QString city;
        st >> country >> state >> city;

        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND state = ? AND files.location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    }

    if (!query.exec()) {
        qDebug() << loc << query.lastError();
        return QString();
    }

    if (query.next()) {
        return query.value(0).toString();
    }
    return QString();
}


QList<QPair<QByteArray, QString> > ImageStorage::timeGroups(ImageStorage::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    QList< QPair<QByteArray, QString> > list;

    QSqlQuery query;
    if (group == Year) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QString val = query.value(0).toString();
            list << qMakePair(val.toUtf8(), val);
        }
        return list;
    }
    else if (group == Month) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime), strftime('%m', dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return list;
        }

        QStringList groups;
        while (query.next()) {
            QString year = query.value(0).toString();
            QString month = query.value(1).toString();

            QString display = QDate::longMonthName(month.toInt()) + ", " + year;

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << year << month;

            list << qMakePair(key, display);
        }
        return list;
    }
    else if (group == Week) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime), strftime('%m', dateTime), strftime('%W', dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QString year = query.value(0).toString();
            QString month = query.value(1).toString();
            QString week = query.value(2).toString();

            QString display =  "Week " + week + ", " + QDate::longMonthName(month.toInt()) + ", " + year;

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << year << week;

            list << qMakePair(key, display);
        }
        return list;
    }
    else if (group == Day) {
        query.prepare("SELECT DISTINCT date(dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QDate date = query.value(0).toDate();

            QString display = date.toString(Qt::SystemLocaleLongDate);
            QByteArray key = date.toString(Qt::ISODate).toUtf8();

            list << qMakePair(key, display);
        }
        return list;
    }

    Q_ASSERT(0);
    return list;
}

QStringList ImageStorage::imagesForTime(const QByteArray& name, ImageStorage::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (group == Year) {
        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ?");
        query.addBindValue(QString::fromUtf8(name));
    }
    else if (group == Month) {
        QDataStream stream(name);
        QString year;
        QString month;
        stream >> year >> month;

        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%m', dateTime) = ?");
        query.addBindValue(year);
        query.addBindValue(month);
    }
    else if (group == Week) {
        QDataStream stream(name);
        QString year;
        QString week;
        stream >> year >> week;

        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%W', dateTime) = ?");
        query.addBindValue(year);
        query.addBindValue(week);
    }
    else if (group == Day) {
        QDate date = QDate::fromString(QString::fromUtf8(name), Qt::ISODate);

        query.prepare("SELECT DISTINCT url from files where date(dateTime) = ?");
        query.addBindValue(date);
    }

    if (!query.exec()) {
        qDebug() << group << query.lastError();
        return QStringList();
    }

    QStringList files;
    while (query.next()) {
        files << query.value(0).toString();
    }

    Q_ASSERT(!files.isEmpty());
    return files;
}

QString ImageStorage::imageForTime(const QByteArray& name, ImageStorage::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    Q_ASSERT(!name.isEmpty());

    QSqlQuery query;
    if (group == Year) {
        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? LIMIT 1");
        query.addBindValue(QString::fromUtf8(name));
    }
    else if (group == Month) {
        QDataStream stream(name);
        QString year;
        QString month;
        stream >> year >> month;

        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%m', dateTime) = ? LIMIT 1");
        query.addBindValue(year);
        query.addBindValue(month);
    }
    else if (group == Week) {
        QDataStream stream(name);
        QString year;
        QString week;
        stream >> year >> week;

        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%W', dateTime) = ? LIMIT 1");
        query.addBindValue(year);
        query.addBindValue(week);
    }
    else if (group == Day) {
        QDate date = QDate::fromString(QString::fromUtf8(name), Qt::ISODate);

        query.prepare("SELECT DISTINCT url from files where date(dateTime) = ? LIMIT 1");
        query.addBindValue(date);
    }

    if (!query.exec()) {
        qDebug() << group << query.lastError();
        return QString();
    }

    if (query.next()) {
        return query.value(0).toString();
    }

    Q_ASSERT(0);
    return QString();
}

QDate ImageStorage::dateForKey(const QByteArray& name, ImageStorage::TimeGroup group)
{
    if (group == Year) {
        return QDate(name.toInt(), 1, 1);
    }
    else if (group == Month) {
        QDataStream stream(name);
        QString year;
        QString month;
        stream >> year >> month;

        return QDate(year.toInt(), month.toInt(), 1);
    }
    else if (group == Week) {
        QDataStream stream(name);
        QString year;
        QString week;
        stream >> year >> week;

        int month = week.toInt() / 4;
        int day = week.toInt() % 4;
        return QDate(year.toInt(), month, day);
    }
    else if (group == Day) {
        return QDate::fromString(QString::fromUtf8(name), Qt::ISODate);
    }

    Q_ASSERT(0);
    return QDate();
}


QList<QPair<QByteArray, QString> > ImageStorage::folders() const
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    query.prepare("select distinct url from files");
    query.exec();

    //
    // FIXME: Figure out how to make sqlite do this operation
    QSet<QString> folderPaths;
    while (query.next()) {
        QString path = query.value(0).toString();
        QUrl url = QUrl::fromLocalFile(path);
        url = url.adjusted(QUrl::RemoveFilename | QUrl::StripTrailingSlash);

        folderPaths << url.toLocalFile();
    }

    QList< QPair<QByteArray, QString> > list;
    for (QString str : folderPaths) {
        QDir dir(str);

        // If a Folder is the only file in its parents folder, then lets use the parent
        // folder's name
        while (1) {
            dir.cdUp();
            QStringList entryList = dir.entryList(QDir::NoDotAndDotDot | QDir::Files | QDir::Dirs);
            if (entryList.size() == 1) {
                str = dir.absolutePath();
            } else {
                break;
            }
        }

        QByteArray key = str.toUtf8();
        QUrl url = QUrl::fromLocalFile(str);
        list << qMakePair(key, url.fileName());
    }

    return list;
}

QStringList ImageStorage::imagesForFolders(const QByteArray& key) const
{
    QMutexLocker lock(&m_mutex);
    QString strUrl = QString::fromUtf8(key);

    QString queryStr("select url from files where url like '");
    queryStr += strUrl;
    queryStr += "/%'";

    QSqlQuery query;
    query.prepare(queryStr);

    if (!query.exec()) {
        qDebug() << key << query.lastError();
        return QStringList();
    }

    QStringList files;
    while (query.next()) {
        files << query.value(0).toString();
    }
    return files;
}

QString ImageStorage::imageForFolders(const QByteArray& key) const
{
    QMutexLocker lock(&m_mutex);
    QString strUrl = QString::fromUtf8(key);

    QString queryStr("select url from files where url like '");
    queryStr += strUrl;
    queryStr += "/%' LIMIT 1";

    QSqlQuery query;
    query.prepare(queryStr);

    if (!query.exec()) {
        qDebug() << key << query.lastError();
        return QString();
    }

    if (query.next())
        return query.value(0).toString();

    return QString();
}

void ImageStorage::reset()
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/koko";
    QDir(dir).removeRecursively();
}
