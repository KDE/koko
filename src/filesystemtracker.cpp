/*
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

#include "filesystemtracker.h"
#include "balooimagefetcher.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>

#include <QStandardPaths>
#include <QTimer>
#include <QVariantMap>
#include <QDir>
#include <QDebug>
#include <QTime>
#include <QEventLoop>

FileSystemTracker::FileSystemTracker(QObject* parent)
    : QObject(parent)
{
    static QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/koko/";
    QDir().mkpath(dir);

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("fstracker"));
    db.setDatabaseName(dir + "/fstracker.sqlite3");
    if (!db.open()) {
        qDebug() << "Failed to open db" << db.lastError().text();
        return;
    }

    if (db.tables().contains("files")) {
        return;
    }

    QSqlQuery query(db);
    bool ret = query.exec(QLatin1String("CREATE TABLE files("
                          "id INTEGER PRIMARY KEY, "
                          "url TEXT NOT NULL UNIQUE)"));
    if (!ret) {
        qDebug() << "Could not create files table" << query.lastError().text();
        return;
    }

    ret = query.exec(QLatin1String("CREATE INDEX fileUrl_index ON files (url)"));
    if (!ret) {
        qDebug() << "Could not create tags index" << query.lastError().text();
        return;
    }

    //
    // WAL Journaling mode has much lower io writes than the traditional journal
    // based indexing.
    //
    ret = query.exec(QLatin1String("PRAGMA journal_mode = WAL"));
    if (!ret) {
        qDebug() << "Could not set WAL journaling mode" << query.lastError().text();
        return;
    }
}

FileSystemTracker::~FileSystemTracker()
{
    QSqlDatabase::removeDatabase(QStringLiteral("fstracker"));
}

void FileSystemTracker::init()
{
    BalooImageFetcher* fetcher = new BalooImageFetcher(m_folder);
    connect(fetcher, &BalooImageFetcher::imageResult,
            this, &FileSystemTracker::slotImageResult, Qt::QueuedConnection);
    connect(fetcher, &BalooImageFetcher::finished,
            this, &FileSystemTracker::slotFetchFinished, Qt::QueuedConnection);

    fetcher->fetch();

    QSqlDatabase::database("fstracker").transaction();
}

void FileSystemTracker::slotImageResult(const QString& filePath)
{
    QSqlQuery query(QSqlDatabase::database("fstracker"));
    query.prepare("SELECT id from files where url = ?");
    query.addBindValue(filePath);
    if (!query.exec()) {
        qDebug() << query.lastError();
        return;
    }

    if (!query.next()) {
        QSqlQuery query(QSqlDatabase::database("fstracker"));
        query.prepare("INSERT into files(url) VALUES (?)");
        query.addBindValue(filePath);
        if (!query.exec()) {
            qDebug() << query.lastError();
            return;
        }
        qDebug() << "ADDED" << filePath;
        emit imageAdded(filePath);
    }

    m_filePaths << filePath;
}

void FileSystemTracker::slotFetchFinished()
{
    QSqlQuery query(QSqlDatabase::database("fstracker"));
    query.prepare("SELECT url from files");
    if (!query.exec()) {
        qDebug() << query.lastError();
        return;
    }

    while (query.next()) {
        QString filePath = query.value(0).toString();

        if (!m_filePaths.contains(filePath)) {
            qDebug() << "REMOVED" << filePath;
            emit imageRemoved(filePath);
            QSqlQuery query(QSqlDatabase::database("fstracker"));
            query.prepare("DELETE from files where url = ?");
            query.addBindValue(filePath);
            if (!query.exec()) {
                qDebug() << query.lastError();
            }
        }
    }

    QSqlDatabase::database("fstracker").commit();

    m_filePaths.clear();
    emit initialScanComplete();
}

void FileSystemTracker::setFolder(const QString& folder)
{
    m_folder = folder;
}

QString FileSystemTracker::folder() const
{
    return m_folder;
}
