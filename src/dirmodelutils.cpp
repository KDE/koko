// SPDX-FileCopyrightText: 2019 Linus Jahn <lnj@kaidan.im>
//
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "dirmodelutils.h"

#include <QStandardPaths>

#include <KIO/MkdirJob>
#include <QDir>
#include <QStandardPaths>

DirModelUtils::DirModelUtils(QObject *parent)
    : QObject(parent)
{
}

bool DirModelUtils::inHome(const QUrl &url) const
{
    const auto homes = QStandardPaths::standardLocations(QStandardPaths::HomeLocation);
    QString home;
    if (homes.count() > 0) {
        home = homes[0];
    }
    return !home.isEmpty() && url.path().startsWith(home) && url.path() != home;
}

QUrl DirModelUtils::home() const
{
    const auto homes = QStandardPaths::standardLocations(QStandardPaths::HomeLocation);
    if (homes.count() > 0) {
        return homes[0];
    }
    return {};
}

QUrl DirModelUtils::pictures() const
{
    const auto pictures = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
    if (pictures.count() > 0) {
        return pictures[0];
    }
    return {};
}

QUrl DirModelUtils::videos() const
{
    const auto videos = QStandardPaths::standardLocations(QStandardPaths::MoviesLocation);
    if (videos.count() > 0) {
        return videos[0];
    }
    return {};
}

bool DirModelUtils::canBeSimplified(const QUrl &url) const
{
    const auto homes = QStandardPaths::standardLocations(QStandardPaths::HomeLocation);
    QString home;
    if (homes.count() > 0) {
        home = homes[0];
    }
    return !home.isEmpty() && url.path() != home;
}

QStringList DirModelUtils::getUrlParts(const QUrl &url) const
{
    if (url.path() == QStringLiteral("/"))
        return {};

    const auto homes = QStandardPaths::standardLocations(QStandardPaths::HomeLocation);
    QString home;
    if (homes.count() > 0) {
        home = homes[0];
    }
    if (!home.isEmpty() && url.path() != home) {
        return url.path().replace(home, "").split(QStringLiteral("/")).mid(1);
    }
    return url.path().split(QStringLiteral("/")).mid(1);
}

QUrl DirModelUtils::partialUrlForIndex(QUrl url, int index) const
{
    const auto homes = QStandardPaths::standardLocations(QStandardPaths::HomeLocation);
    QString home;
    if (homes.count() > 0) {
        home = homes[0];
    }
    QStringList urlParts;
    bool inHome = false;
    if (!home.isEmpty() && url.path().startsWith(home) && url.path() != home) {
        urlParts = url.path().replace(home, "/").split(QStringLiteral("/")).mid(1);
        inHome = true;
    } else {
        urlParts = url.path().split(QStringLiteral("/")).mid(1);
    }
    QString path = QStringLiteral("/");
    for (int i = 0; i < index + int(inHome); i++) {
        if (urlParts.at(i) != "") {
            path += urlParts.at(i);
            path += QStringLiteral("/");
        }
    }
    if (inHome) {
        url.setPath(home + path);
    } else {
        url.setPath(path);
    }

    return url;
}

QUrl DirModelUtils::directoryOfUrl(const QString &path) const
{
    const int index = path.lastIndexOf(QLatin1Char('/'));
    return QUrl::fromLocalFile(path.mid(0, index));
}

QString DirModelUtils::fileNameOfUrl(const QString &path) const
{
    const int index = path.lastIndexOf(QLatin1Char('/'));
    return path.mid(index + 1);
}

void DirModelUtils::mkdir(const QUrl &path) const
{
    KIO::mkdir(path);
}

QUrl DirModelUtils::parentOfUrl(const QUrl &url) const
{
    auto path = QDir(url.toLocalFile());
    path.cdUp();
    return QUrl(path.absolutePath());
}
