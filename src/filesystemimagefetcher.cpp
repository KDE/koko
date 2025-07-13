/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "filesystemimagefetcher.h"

#include <QDirIterator>
#include <QMimeDatabase>
#include <QTimer>

using namespace Qt::StringLiterals;

FileSystemImageFetcher::FileSystemImageFetcher(const QString &folder, QObject *parent)
    : QObject(parent)
    , m_folder(folder)
{
}

void FileSystemImageFetcher::fetch()
{
    QTimer::singleShot(0, this, &FileSystemImageFetcher::slotProcess);
}

void FileSystemImageFetcher::slotProcess()
{
    static QMimeDatabase mimeDb;

    QDirIterator it(m_folder, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        const QString filePath = it.next();
        const auto fileInfo = it.fileInfo();

        if (fileInfo.isDir() || fileInfo.isExecutable()) {
            continue;
        }

        static QMimeDatabase db;
        const auto mimetype = db.mimeTypeForFile(filePath, QMimeDatabase::MatchMode::MatchExtension).name();
        if (mimetype.startsWith("image/"_L1) || mimetype.startsWith("video/"_L1)) {
            Q_EMIT imageResult(QUrl::fromLocalFile(filePath));
        }
    }

    Q_EMIT finished();
}
