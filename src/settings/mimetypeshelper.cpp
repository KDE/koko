/*
 *  SPDX-FileCopyrightText: 2026 Jan Rathmann <jan.rathmann@gmx.de>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <QMimeDatabase>

#include "kokoconfig.h"
#include "mimetypeshelper.h"

const QStringList MimeTypesHelper::s_imageFileExtensions = MimeTypesHelper::extensionsFromMimeDB(QStringLiteral("image/"));
const QStringList MimeTypesHelper::s_videoFileExtensions = MimeTypesHelper::extensionsFromMimeDB(QStringLiteral("video/"));

QString MimeTypesHelper::relevantMimeTypes()
{
    QStringList types = s_imageFileExtensions;
    if (Config::self()->mediaTypes() == Config::EnumMediaTypes::ImagesAndVideos) {
        types << s_videoFileExtensions;
    }
    types.removeDuplicates();

    for (auto &t : types) {
        t.prepend(QStringLiteral("*."));
    }

    return types.join(QLatin1Char(' '));
}

QStringList MimeTypesHelper::extensionsFromMimeDB(QString mimeTypesPrefix)
{
    QStringList suffixes;
    for (const auto &mimeType : QMimeDatabase().allMimeTypes()) {
        const auto name = mimeType.name();
        if (name.startsWith(mimeTypesPrefix)) {
            suffixes << mimeType.suffixes();
        }
    }

    suffixes.removeDuplicates();
    return suffixes;
}
