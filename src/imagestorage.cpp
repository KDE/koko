// SPDX-FileCopyrightText: 2014 Vishesh Handa <vhanda@kde.org>
// SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "imagestorage.h"

#include <QDataStream>
#include <QDebug>
#include <QGeoAddress>
#include <QGeoCoordinate>

#include <QDir>
#include <QStandardPaths>
#include <QUrl>

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

ImageStorage::ImageStorage(QObject *parent)
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
        QSqlQuery query(db);
        query.prepare("PRAGMA table_info(files)");
        bool favorites_present = false;
        if (!query.exec()) {
            qDebug() << "Failed to read db" << query.lastError();
            return;
        }
        while (query.next()) {
            if (query.value(1).toString() == "favorite") {
                favorites_present = true;
            }
        }
        if (!favorites_present) {
            // migrate to new table
            query.exec("ALTER TABLE files ADD COLUMN favorite INTEGER");
        }

        db.transaction();

        return;
    }

    QSqlQuery query(db);
    query.exec(
        "CREATE TABLE locations (id INTEGER PRIMARY KEY, country TEXT, state TEXT, city TEXT"
        "                        , UNIQUE(country, state, city) ON CONFLICT REPLACE"
        ")");
    query.exec("CREATE TABLE tags (url TEXT NOT NULL, tag TEXT)");
    query.exec(
        "CREATE TABLE files (url TEXT NOT NULL UNIQUE PRIMARY KEY,"
        "                    favorite INTEGER,"
        "                    location INTEGER,"
        "                    dateTime STRING NOT NULL,"
        "                    FOREIGN KEY(location) REFERENCES locations(id)"
        "                    FOREIGN KEY(url) REFERENCES tags(url)"
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

ImageStorage *ImageStorage::instance()
{
    static ImageStorage storage;
    return &storage;
}

void ImageStorage::addImage(const ImageInfo &ii)
{
    if (imageExists(ii.path)) {
        removeImage(ii.path);
    }
    QMutexLocker lock(&m_mutex);
    QGeoAddress addr = ii.location.address();

    if (!addr.country().isEmpty()) {
        int locId = -1;

        if (!addr.city().isEmpty()) {
            QSqlQuery query;
            query.prepare("SELECT id FROM LOCATIONS WHERE country = ? AND state = ? AND city = ?");
            query.addBindValue(addr.country());
            query.addBindValue(addr.state());
            query.addBindValue(addr.city());
            if (!query.exec()) {
                qDebug() << "LOC SELECT" << query.lastError();
            }

            if (query.next()) {
                locId = query.value(0).toInt();
            }
        } else {
            QSqlQuery query;
            query.prepare("SELECT id FROM LOCATIONS WHERE country = ? AND state = ?");
            query.addBindValue(addr.country());
            query.addBindValue(addr.state());
            if (!query.exec()) {
                qDebug() << "LOC SELECT" << query.lastError();
            }

            if (query.next()) {
                locId = query.value(0).toInt();
            }
        }

        if (locId == -1) {
            QSqlQuery query;
            query.prepare("INSERT INTO LOCATIONS(country, state, city) VALUES (?, ?, ?)");
            query.addBindValue(addr.country());
            query.addBindValue(addr.state());
            query.addBindValue(addr.city());
            if (!query.exec()) {
                qDebug() << "LOC INSERT" << query.lastError();
            }

            locId = query.lastInsertId().toInt();
        }

        QSqlQuery query;
        query.prepare("INSERT INTO FILES(url, favorite, location, dateTime) VALUES(?, ?, ?, ?)");
        query.addBindValue(ii.path);
        query.addBindValue(int(ii.favorite));
        query.addBindValue(locId);
        query.addBindValue(ii.dateTime.toString(Qt::ISODate));
        if (!query.exec()) {
            qDebug() << "FILE LOC INSERT" << query.lastError();
        }
    } else {
        QSqlQuery query;
        query.prepare("INSERT INTO FILES(url, favorite, dateTime) VALUES(?, ?, ?)");
        query.addBindValue(ii.path);
        query.addBindValue(int(ii.favorite));
        query.addBindValue(ii.dateTime.toString(Qt::ISODate));
        if (!query.exec()) {
            qDebug() << "FILE INSERT" << query.lastError();
        }
    }

    for (const auto &tag : std::as_const(ii.tags)) {
        QSqlQuery query;
        query.prepare("SELECT url FROM TAGS WHERE url = ? AND tag = ?");
        query.addBindValue(ii.path);
        query.addBindValue(tag);

        if (!query.exec()) {
            qDebug() << "tag select" << query.lastError();
        }

        if (!query.next()) {
            QSqlQuery query;
            query.prepare("INSERT INTO TAGS(url, tag) VALUES (?, ?)");
            query.addBindValue(ii.path);
            query.addBindValue(tag);
            if (!query.exec()) {
                qDebug() << "tag insert" << query.lastError();
            }
        }
    }
}

bool ImageStorage::imageExists(const QString &filePath)
{
    QMutexLocker lock(&m_mutex);

    QSqlQuery query;
    query.prepare("SELECT EXISTS(SELECT 1 FROM files WHERE url = ?)");
    query.addBindValue(filePath);

    if (!query.exec()) {
        qDebug() << query.lastError();
        return false;
    }

    return query.next();
}

void ImageStorage::removeImage(const QString &filePath)
{
    QMutexLocker lock(&m_mutex);

    QSqlQuery query;
    query.prepare("DELETE FROM FILES WHERE URL = ?");
    query.addBindValue(filePath);
    if (!query.exec()) {
        qDebug() << "FILE del" << query.lastError();
    }

    QSqlQuery query2;
    query2.prepare("DELETE FROM LOCATIONS WHERE id NOT IN (SELECT DISTINCT location FROM files WHERE location IS NOT NULL)");
    if (!query2.exec()) {
        qDebug() << "Loc del" << query2.lastError();
    }

    QSqlQuery query3;
    query3.prepare("DELETE FROM TAGS WHERE url NOT IN (SELECT DISTINCT url FROM files)");
    if (!query3.exec()) {
        qDebug() << "tag delete" << query3.lastError();
    }
}

void ImageStorage::commit()
{
    {
        QMutexLocker lock(&m_mutex);
        QSqlDatabase db = QSqlDatabase::database();
        db.commit();
        db.transaction();
    }

    emit storageModified();
}

QList<QPair<QByteArray, QString>> ImageStorage::locations(Types::LocationGroup loca)
{
    QMutexLocker lock(&m_mutex);
    QList<QPair<QByteArray, QString>> list;

    if (loca == Types::LocationGroup::Country) {
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
    } else if (loca == Types::LocationGroup::State) {
        QSqlQuery query;
        query.prepare("SELECT DISTINCT country, state from locations");

        if (!query.exec()) {
            qDebug() << loca << query.lastError();
            return list;
        }

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
    } else if (loca == Types::LocationGroup::City) {
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

QStringList ImageStorage::imagesForFavorites()
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;

    query.prepare("SELECT DISTINCT url from files where favorite = 1");

    if (!query.exec()) {
        qDebug() << "imagesForFavorites: " << query.lastError();
        return QStringList();
    }

    QStringList files;
    while (query.next()) {
        files << QString("file://" + query.value(0).toString());
    }

    return files;
}

QStringList ImageStorage::tags()
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;

    query.prepare("SELECT DISTINCT tag from tags");

    if (!query.exec()) {
        qDebug() << "tags: " << query.lastError();
        return QStringList();
    }

    QStringList tags;
    while (query.next()) {
        tags << query.value(0).toString();
    }

    return tags;
}

QStringList ImageStorage::imagesForTag(const QString &tag)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;

    query.prepare("SELECT DISTINCT url from tags where tag = ?");
    query.addBindValue(tag);

    if (!query.exec()) {
        qDebug() << "imagesForTag: " << query.lastError();
        return QStringList();
    }

    QStringList files;
    while (query.next()) {
        files << QString("file://" + query.value(0).toString());
    }

    return files;
}

QStringList ImageStorage::imagesForLocation(const QByteArray &name, Types::LocationGroup loc)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (loc == Types::LocationGroup::Country) {
        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND files.location = locations.id");
        query.addBindValue(QString::fromUtf8(name));
    } else if (loc == Types::LocationGroup::State) {
        QDataStream st(name);

        QString country;
        QString state;
        st >> country >> state;

        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND state = ? AND files.location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    } else if (loc == Types::LocationGroup::City) {
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
        qDebug() << "imagesForLocation: " << loc << query.lastError();
        return QStringList();
    }

    QStringList files;
    while (query.next()) {
        files << QString("file://" + query.value(0).toString());
    }
    return files;
}

QString ImageStorage::imageForLocation(const QByteArray &name, Types::LocationGroup loc)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (loc == Types::LocationGroup::Country) {
        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND files.location = locations.id");
        query.addBindValue(QString::fromUtf8(name));
    } else if (loc == Types::LocationGroup::State) {
        QDataStream st(name);

        QString country;
        QString state;
        st >> country >> state;

        query.prepare("SELECT DISTINCT url from files, locations where country = ? AND state = ? AND files.location = locations.id");
        query.addBindValue(country);
        query.addBindValue(state);
    } else if (loc == Types::LocationGroup::City) {
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
        qDebug() << "imageForLocation: " << loc << query.lastError();
        return QString();
    }

    if (query.next()) {
        return QString("file://" + query.value(0).toString());
    }
    return QString();
}

QList<QPair<QByteArray, QString>> ImageStorage::timeTypes(Types::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    QList<QPair<QByteArray, QString>> list;

    QSqlQuery query;
    if (group == Types::TimeGroup::Year) {
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
    } else if (group == Types::TimeGroup::Month) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime), strftime('%m', dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QString year = query.value(0).toString();
            QString month = query.value(1).toString();

            QString display = QLocale().monthName(month.toInt(), QLocale::LongFormat) + ", " + year;

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << year << month;

            list << qMakePair(key, display);
        }
        return list;
    } else if (group == Types::TimeGroup::Week) {
        query.prepare("SELECT DISTINCT strftime('%Y', dateTime), strftime('%m', dateTime), strftime('%W', dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QString year = query.value(0).toString();
            QString month = query.value(1).toString();
            QString week = query.value(2).toString();

            QString display = "Week " + week + ", " + QLocale().monthName(month.toInt(), QLocale::LongFormat) + ", " + year;

            QByteArray key;
            QDataStream stream(&key, QIODevice::WriteOnly);
            stream << year << week;

            list << qMakePair(key, display);
        }
        return list;
    } else if (group == Types::TimeGroup::Day) {
        query.prepare("SELECT DISTINCT date(dateTime) from files");
        if (!query.exec()) {
            qDebug() << group << query.lastError();
            return list;
        }

        while (query.next()) {
            QDate date = query.value(0).toDate();

            QString display = QLocale::system().toString(date, QLocale::LongFormat);
            QByteArray key = date.toString(Qt::ISODate).toUtf8();

            list << qMakePair(key, display);
        }
        return list;
    }

    Q_ASSERT(0);
    return list;
}

QStringList ImageStorage::imagesForTime(const QByteArray &name, Types::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    QSqlQuery query;
    if (group == Types::TimeGroup::Year) {
        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ?");
        query.addBindValue(QString::fromUtf8(name));
    } else if (group == Types::TimeGroup::Month) {
        QDataStream stream(name);
        QString year;
        QString month;
        stream >> year >> month;

        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%m', dateTime) = ?");
        query.addBindValue(year);
        query.addBindValue(month);
    } else if (group == Types::TimeGroup::Week) {
        QDataStream stream(name);
        QString year;
        QString week;
        stream >> year >> week;

        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%W', dateTime) = ?");
        query.addBindValue(year);
        query.addBindValue(week);
    } else if (group == Types::TimeGroup::Day) {
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
        files << QString("file://" + query.value(0).toString());
    }

    return files;
}

QString ImageStorage::imageForTime(const QByteArray &name, Types::TimeGroup group)
{
    QMutexLocker lock(&m_mutex);
    Q_ASSERT(!name.isEmpty());

    QSqlQuery query;
    if (group == Types::TimeGroup::Year) {
        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? LIMIT 1");
        query.addBindValue(QString::fromUtf8(name));
    } else if (group == Types::TimeGroup::Month) {
        QDataStream stream(name);
        QString year;
        QString month;
        stream >> year >> month;

        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%m', dateTime) = ? LIMIT 1");
        query.addBindValue(year);
        query.addBindValue(month);
    } else if (group == Types::TimeGroup::Week) {
        QDataStream stream(name);
        QString year;
        QString week;
        stream >> year >> week;

        query.prepare("SELECT DISTINCT url from files where strftime('%Y', dateTime) = ? AND strftime('%W', dateTime) = ? LIMIT 1");
        query.addBindValue(year);
        query.addBindValue(week);
    } else if (group == Types::TimeGroup::Day) {
        QDate date = QDate::fromString(QString::fromUtf8(name), Qt::ISODate);

        query.prepare("SELECT DISTINCT url from files where date(dateTime) = ? LIMIT 1");
        query.addBindValue(date);
    }

    if (!query.exec()) {
        qDebug() << group << query.lastError();
        return QString();
    }

    if (query.next()) {
        return QString("file://" + query.value(0).toString());
    }

    Q_ASSERT(0);
    return QString();
}

QDate ImageStorage::dateForKey(const QByteArray &key, Types::TimeGroup group)
{
    if (group == Types::TimeGroup::Year) {
        return QDate(key.toInt(), 1, 1);
    } else if (group == Types::TimeGroup::Month) {
        QDataStream stream(key);
        QString year;
        QString month;
        stream >> year >> month;

        return QDate(year.toInt(), month.toInt(), 1);
    } else if (group == Types::TimeGroup::Week) {
        QDataStream stream(key);
        QString year;
        QString week;
        stream >> year >> week;

        int month = week.toInt() / 4;
        int day = week.toInt() % 4;
        return QDate(year.toInt(), month, day);
    } else if (group == Types::TimeGroup::Day) {
        return QDate::fromString(QString::fromUtf8(key), Qt::ISODate);
    }

    Q_ASSERT(0);
    return QDate();
}

void ImageStorage::reset()
{
    qDebug() << "Resetting database";
    QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/koko";
    QDir(dir).removeRecursively();
}

bool ImageStorage::shouldReset()
{
    bool shouldReset = false;
    {
        QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/koko";
        QDir().mkpath(dir);

        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("resetChecker"));
        db.setDatabaseName(dir + "/imageData.sqlite3");

        if (!db.open()) {
            qDebug() << "Failed to open db" << db.lastError().text();
            shouldReset = true;
        } else if (db.tables().contains("files") == true && db.tables().contains("tags") == false) {
            shouldReset = true;
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(QStringLiteral("resetChecker"));
    return shouldReset;
}

QStringList ImageStorage::allImages(int size, int offset)
{
    QMutexLocker lock(&m_mutex);

    QSqlQuery query;
    if (size == -1) {
        query.prepare("SELECT DISTINCT url from files ORDER BY dateTime DESC");
    } else {
        query.prepare("SELECT DISTINCT url from files ORDER BY dateTime DESC LIMIT ? OFFSET ?");
        query.addBindValue(size);
        query.addBindValue(offset);
    }

    if (!query.exec()) {
        qDebug() << query.lastError();
        return QStringList();
    }

    QStringList imageList;
    while (query.next())
        imageList << query.value(0).toString();

    return imageList;
}
