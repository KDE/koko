// SPDX-FileCopyrightText: 2007 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include "orientation.h"

#include <QByteArray>

class QImage;
class QSize;
class QString;
class QIODevice;

namespace Exiv2
{
class Image;
}

class JpegContent
{
public:
    JpegContent();
    ~JpegContent();

    Orientation orientation() const;
    void resetOrientation();

    int dotsPerMeterX() const;
    int dotsPerMeterY() const;

    QSize size() const;

    QString comment() const;
    void setComment(const QString &);

    void transform(Orientation);

    QImage thumbnail() const;
    void setThumbnail(const QImage &);

    // Recreate raw data to represent image
    // Note: thumbnail must be updated separately
    void setImage(const QImage &image);

    bool load(const QString &file);
    bool loadFromData(const QByteArray &rawData);
    /**
     * Use this version of loadFromData if you already have an Exiv2::Image*
     */
    bool loadFromData(const QByteArray &rawData, Exiv2::Image *);
    bool save(const QString &file);
    bool save(QIODevice *);

    QByteArray rawData() const;

    QString errorString() const;

private:
    struct Private;
    Private *d;

    JpegContent(const JpegContent &) = delete;
    void operator=(const JpegContent &) = delete;
    void applyPendingTransformation();
    int dotsPerMeter(const QString &keyName) const;
};
