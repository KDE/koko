/*
 * Copyright (C) 2015  Vishesh Handa <vhanda@kde.org>
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

#include "filesystemimagefetcher.h"

#include <QTimer>
#include <QDirIterator>
#include <QMimeDatabase>

FileSystemImageFetcher::FileSystemImageFetcher(const QString& folder, QObject* parent)
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
