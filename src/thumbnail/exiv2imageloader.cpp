// SPDX-FileCopyrightText: 2007 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "exiv2imageloader.h"

#include <QByteArray>
#include <QDebug>
#include <QFile>
#include <QString>

#include <exiv2/exiv2.hpp>

struct Exiv2ImageLoaderPrivate {
    std::unique_ptr<Exiv2::Image> mImage;
    QString mErrorMessage;
};

struct Exiv2LogHandler {
    static void handleMessage(int level, const char *message)
    {
        switch (level) {
        case Exiv2::LogMsg::debug:
            qDebug() << message;
            break;
        case Exiv2::LogMsg::info:
            qInfo() << message;
            break;
        case Exiv2::LogMsg::warn:
        case Exiv2::LogMsg::error:
        case Exiv2::LogMsg::mute:
            qWarning() << message;
            break;
        default:
            qWarning() << "unhandled log level" << level << message;
            break;
        }
    }

    Exiv2LogHandler()
    {
        Exiv2::LogMsg::setHandler(&Exiv2LogHandler::handleMessage);
    }
};

Exiv2ImageLoader::Exiv2ImageLoader()
    : d(std::make_unique<Exiv2ImageLoaderPrivate>())
{
    // This is a threadsafe way to ensure that we only register it once
    static Exiv2LogHandler handler;
}

Exiv2ImageLoader::~Exiv2ImageLoader() = default;

bool Exiv2ImageLoader::load(const QString &filePath)
{
    QByteArray filePathByteArray = QFile::encodeName(filePath);
    try {
        d->mImage.reset(Exiv2::ImageFactory::open(filePathByteArray.constData()).release());
        d->mImage->readMetadata();
    } catch (const Exiv2::Error &error) {
        d->mErrorMessage = QString::fromUtf8(error.what());
        return false;
    }
    return true;
}

bool Exiv2ImageLoader::load(const QByteArray &data)
{
    try {
        d->mImage.reset(Exiv2::ImageFactory::open((unsigned char *)data.constData(), data.size()).release());
        d->mImage->readMetadata();
    } catch (const Exiv2::Error &error) {
        d->mErrorMessage = QString::fromUtf8(error.what());
        return false;
    }
    return true;
}

QString Exiv2ImageLoader::errorMessage() const
{
    return d->mErrorMessage;
}

std::unique_ptr<Exiv2::Image> Exiv2ImageLoader::popImage()
{
    return std::move(d->mImage);
}
