/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "filesystemimagefetcher.h"

#include <QDirIterator>
#include <QMimeDatabase>
#include <QTimer>
#include <array>

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

    static constexpr auto allowedExtensions = std::to_array<QLatin1StringView>({
        "png"_L1,
        "jpg"_L1,
        "jpeg"_L1,
        "heic"_L1,
    });

    QDirIterator it(m_folder, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        const QString filePath = it.next();
        const auto fileInfo = it.fileInfo();

        if (fileInfo.isDir() || fileInfo.isExecutable()) {
            continue;
        }

        const auto extension = QStringView(filePath).split('.').constLast();
        if (std::ranges::find_if(allowedExtensions,
                                 [&extension](const QLatin1StringView &allowedExtension) -> bool {
                                     return allowedExtension == extension;
                                 })
            != allowedExtensions.cend()) {
            Q_EMIT imageResult(filePath);
            return;
        }

        const QString mimetype = mimeDb.mimeTypeForFile(filePath).name();
        if (!mimetype.startsWith("image/"_L1) && !mimetype.startsWith("video/"_L1))
            continue;

        Q_EMIT imageResult(filePath);
    }

    Q_EMIT finished();
}
