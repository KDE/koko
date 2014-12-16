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

#include <KVariantStore/KVariantQuery>

#include <QStandardPaths>
#include <QTimer>
#include <QVariantMap>
#include <QDir>
#include <QDebug>
#include <QTime>
#include <QEventLoop>

FileSystemTracker::FileSystemTracker(QObject* parent)
    : QThread(parent)
{
    static QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/koko/";
    QDir().mkpath(dir);

    m_db = new KVariantStore();
    m_db->setPath(dir + QStringLiteral("fstracker"));
    if (!m_db->open()) {
        Q_ASSERT_X(0, "", "FileSystemTracker could not open database");
    }
    m_coll = m_db->collection("images");
}

FileSystemTracker::~FileSystemTracker()
{
}

void FileSystemTracker::run()
{
    init();
    exec();
}

void FileSystemTracker::init()
{
    BalooImageFetcher* fetcher = new BalooImageFetcher();
    connect(fetcher, &BalooImageFetcher::imageResult,
            this, &FileSystemTracker::slotImageResult, Qt::QueuedConnection);
    connect(fetcher, &BalooImageFetcher::finished,
            this, &FileSystemTracker::slotFetchFinished, Qt::QueuedConnection);

    fetcher->fetch();
}

void FileSystemTracker::slotImageResult(const QString& filePath)
{
    QVariantMap map = {{"url", filePath}};
    if (m_coll.count(map) == 0) {
        m_coll.insert(map);
        emit imageAdded(filePath);
    }

    m_filePaths << filePath;
}

void FileSystemTracker::slotFetchFinished()
{
    KVariantQuery q = m_coll.find(QVariantMap());
    while (q.next()) {
        QVariantMap map = q.result();
        QString filePath = map.value("url").toString();

        if (!m_filePaths.contains(filePath)) {
            emit imageRemoved(filePath);
        }
    }

    m_filePaths.clear();
}
