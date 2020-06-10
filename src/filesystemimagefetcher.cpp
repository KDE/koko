/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "filesystemimagefetcher.h"

#include <QDirIterator>
#include <QMimeDatabase>
#include <QTimer>

FileSystemImageFetcher::FileSystemImageFetcher(const QString &folder, QObject *parent)
    : QObject(parent)
    , m_folder(folder)
{
}

void FileSystemImageFetcher::fetch()
{
    QTimer::singleShot(0, this, SLOT(slotProcess()));
}

void FileSystemImageFetcher::slotProcess()
{
    QMimeDatabase mimeDb;

    QDirIterator it(m_folder, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString filePath = it.next();

        QString mimetype = mimeDb.mimeTypeForFile(filePath, QMimeDatabase::MatchExtension).name();
        if (!mimetype.startsWith("image/"))
            continue;

        Q_EMIT imageResult(filePath);
    }

    Q_EMIT finished();
}
