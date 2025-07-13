/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "filesystemtracker.h"

#include <QDBusConnection>
#include <QDebug>
#include <QDir>
#include <QMimeDatabase>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

#include <KDirNotify>
#include <KDirWatch>

#include "filesystemimagefetcher.h"

FileSystemTracker::FileSystemTracker(QObject *parent)
    : QObject(parent)
{
    QObject::connect(KDirWatch::self(), &KDirWatch::dirty, this, &FileSystemTracker::setSubFolder);

    org::kde::KDirNotify *kdirnotify = new org::kde::KDirNotify(QString(), QString(), QDBusConnection::sessionBus(), this);

    connect(kdirnotify, &org::kde::KDirNotify::FilesRemoved, this, [this](const QStringList &files) {
        for (const QString &filePath : files) {
            removeFile(QUrl(filePath));
        }
    });
    connect(kdirnotify, &org::kde::KDirNotify::FilesAdded, this, &FileSystemTracker::setSubFolder);
    connect(kdirnotify, &org::kde::KDirNotify::FileRenamedWithLocalPath, this, [this](const QString &src, const QString &dst, const QString &) {
        removeFile(QUrl(src));
        slotNewFiles({dst});
    });
    connect(kdirnotify, &org::kde::KDirNotify::FilesChanged, this, [this](const QStringList &files) {
        for (const QString &filePath : files) {
            removeFile(QUrl(filePath));
        }
        slotNewFiles(files);
    });

    connect(this, &FileSystemTracker::subFolderChanged, this, &FileSystemTracker::reindexSubFolder);
}

void FileSystemTracker::setupDb()
{
    static QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/koko/";
    QDir().mkpath(dir);

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("fstracker"));
    db.setDatabaseName(dir + "/fstracker.sqlite3");
    if (!db.open()) {
        qWarning() << "Failed to open db" << db.lastError().text();
        return;
    }

    if (db.tables().contains("files")) {
        QSqlQuery query(db);
        query.prepare("PRAGMA table_info(files)");
        bool metadataChangeTime_present = false;
        if (!query.exec()) {
            qDebug() << "Failed to read db" << query.lastError();
            return;
        }
        while (query.next()) {
            if (query.value(1).toString() == "metadataChangeTime") {
                metadataChangeTime_present = true;
            }
        }
        if (metadataChangeTime_present) {
            return;
        } else {
            // reindex everything
            qDebug() << "REINDEXING files";
            query.exec("DROP TABLE files");
        }
    }

    QSqlQuery query(db);
    bool ret =
        query.exec(QLatin1String("CREATE TABLE files("
                                 "id INTEGER PRIMARY KEY, "
                                 "metadataChangeTime STRING NOT NULL,"
                                 "url TEXT NOT NULL UNIQUE)"));
    if (!ret) {
        qWarning() << "Could not create files table" << query.lastError().text();
        return;
    }

    ret = query.exec(QLatin1String("CREATE INDEX fileUrl_index ON files (url)"));
    if (!ret) {
        qWarning() << "Could not create tags index" << query.lastError().text();
        return;
    }

    //
    // WAL Journaling mode has much lower io writes than the traditional journal
    // based indexing.
    //
    ret = query.exec(QLatin1String("PRAGMA journal_mode = WAL"));
    if (!ret) {
        qWarning() << "Could not set WAL journaling mode" << query.lastError().text();
        return;
    }
}

FileSystemTracker::~FileSystemTracker()
{
    QSqlDatabase::removeDatabase(QStringLiteral("fstracker"));
}

void FileSystemTracker::slotImageResult(const QUrl &file)
{
    const auto filePath = file.toLocalFile();

    QSqlQuery query(QSqlDatabase::database("fstracker"));
    query.prepare("SELECT id, metadataChangeTime from files where url = ?");
    query.addBindValue(filePath);
    if (!query.exec()) {
        qWarning() << Q_FUNC_INFO << query.lastError() << file;
        return;
    }

    bool indexed = query.next();

    if (indexed && query.value(1).toString() != QFileInfo(filePath).metadataChangeTime().toString(Qt::ISODate)) {
        // reindex if metadata has changed
        removeFile(file);
        indexed = false;
        qDebug() << "REINDEXING" << file;
    }

    if (!indexed && !m_processingPaths.contains(file)) {
        // qDebug() << "ADDED" << file;
        Q_EMIT imageAdded(file);
    }

    m_processingPaths << file;
    m_filePaths << file;
}

void FileSystemTracker::fileProcessed(const QUrl &file)
{
    const auto filePath = file.toLocalFile();

    QSqlQuery query(QSqlDatabase::database("fstracker"));
    query.prepare("INSERT into files(url, metadataChangeTime) VALUES (?, ?)");
    query.addBindValue(filePath);
    query.addBindValue(QFileInfo(filePath).metadataChangeTime().toString(Qt::ISODate));
    if (!query.exec()) {
        qWarning() << Q_FUNC_INFO << query.lastError() << file;
    }

    m_filePaths.remove(file);
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
        const QString filePath = query.value(0).toString();

        if (filePath.contains(m_subFolder) && !m_filePaths.contains(QUrl::fromLocalFile(filePath))) {
            removeFile(QUrl::fromLocalFile(filePath));
        }
    }

    QSqlDatabase::database("fstracker").commit();

    m_filePaths.clear();
    emit initialScanComplete();
}

void FileSystemTracker::removeFile(const QUrl &file)
{
    QString filePath = file.toLocalFile();
    qDebug() << "REMOVED" << filePath;
    Q_EMIT imageRemoved(file);
    QSqlQuery query(QSqlDatabase::database("fstracker"));
    query.prepare("DELETE from files where url = ?");
    query.addBindValue(filePath);
    if (!query.exec()) {
        qWarning() << query.lastError();
    }
}

void FileSystemTracker::slotNewFiles(const QStringList &files)
{
    if (!m_filePaths.isEmpty()) {
        // A scan is already going on. No point interrupting it.
        return;
    }

    QMimeDatabase db;
    for (const QString &file : files) {
        QMimeType mimetype = db.mimeTypeForFile(file);
        if (mimetype.name().startsWith("image/") || mimetype.name().startsWith("video/")) {
            slotImageResult(QUrl(file));
        }
    }

    m_filePaths.clear();
}

void FileSystemTracker::setFolder(const QString &folder)
{
    if (m_folder == folder) {
        return;
    }

    KDirWatch::self()->removeDir(m_folder);
    m_folder = folder;
    KDirWatch::self()->addDir(m_folder, KDirWatch::WatchSubDirs);

    FileSystemImageFetcher *fetcher = new FileSystemImageFetcher(m_folder);
    connect(fetcher, &FileSystemImageFetcher::imageResult, this, &FileSystemTracker::slotImageResult, Qt::QueuedConnection);
    connect(
        fetcher,
        &FileSystemImageFetcher::finished,
        this,
        [this, fetcher] {
            slotFetchFinished();
            fetcher->deleteLater();
        },
        Qt::QueuedConnection);

    fetcher->fetch();

    QSqlDatabase::database("fstracker").transaction();
}

QString FileSystemTracker::folder() const
{
    return m_folder;
}

void FileSystemTracker::setSubFolder(const QString &folder)
{
    if (QFileInfo(folder).isDir()) {
        m_subFolder = folder;
        emit subFolderChanged();
    }
}

void FileSystemTracker::reindexSubFolder()
{
    FileSystemImageFetcher *fetcher = new FileSystemImageFetcher(m_subFolder);
    connect(fetcher, &FileSystemImageFetcher::imageResult, this, &FileSystemTracker::slotImageResult, Qt::QueuedConnection);
    connect(
        fetcher,
        &FileSystemImageFetcher::finished,
        this,
        [this, fetcher] {
            slotFetchFinished();
            fetcher->deleteLater();
        },
        Qt::QueuedConnection);

    fetcher->fetch();

    QSqlDatabase::database("fstracker").transaction();
}
