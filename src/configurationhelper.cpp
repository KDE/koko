/*
   SPDX-FileCopyrightText: 2017 (c) Matthieu Gallien <matthieu_gallien@yahoo.fr>
   SPDX-FileCopyrightText: 2020 (c) Carl Schwan <carl@carlschwan.eu>

   SPDX-License-Identifier: LGPL-3.0-or-later
 */

#include "configurationhelper.h"

#include <QStandardPaths>
#include <QUrl>
#include <QFileInfo>

ConfigurationHelper::ConfigurationHelper(QObject *parent)
    : QObject(parent)
{
}

QStringList ConfigurationHelper::processPaths(const QStringList &paths) const
{
    QStringList value;
    for (const auto &path : paths) {
        auto workPath = path;
        if (workPath.startsWith(QLatin1String("file:/"))) {
            auto urlPath = QUrl{workPath};
            workPath = urlPath.toLocalFile();
        }

        const QFileInfo pathFileInfo(workPath);
        const auto directoryPath = pathFileInfo.canonicalFilePath();
        if (!directoryPath.isEmpty()) {
            value.append(directoryPath);
        }
    }

    if (value.isEmpty()) {
        auto systemPicturesPaths = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
        for (const auto &picturePath : qAsConst(systemPicturesPaths)) {
            value.append(picturePath);
        }
    }
    return value;
}



#include "moc_configurationhelper.cpp"
