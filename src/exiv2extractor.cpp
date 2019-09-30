/*
    Copyright (C) 2012-15  Vishesh Handa <vhanda@kde.org>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/


#include "exiv2extractor.h"

#include <QDebug>
#include <QFile>

Exiv2Extractor::Exiv2Extractor()
    : m_latitude(0)
    , m_longitude(0)
    , m_error(true)
{
}

static QDateTime dateTimeFromString(const QString& dateString)
{
    QDateTime dateTime;

    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy-MM-dd"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd-MM-yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy-MM"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("MM-yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy.MM.dd"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd.MM.yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dd MMMM yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("MM.yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy.MM"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yy"));
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, Qt::ISODate);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("dddd d MMM yyyy h':'mm':'ss AP"));
        dateTime.setTimeSpec(Qt::LocalTime);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, QStringLiteral("yyyy:MM:dd hh:mm:ss"));
        dateTime.setTimeSpec(Qt::LocalTime);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, Qt::SystemLocaleDate);
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, Qt::SystemLocaleShortDate);
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(dateString, Qt::SystemLocaleLongDate);
        dateTime.setTimeSpec(Qt::UTC);
    }
    if (!dateTime.isValid()) {
        qWarning() << "Could not determine correct datetime format from:" << dateString;
        return QDateTime();
    }

    return dateTime;
}
static QDateTime toDateTime(const Exiv2::Value& value)
{
    if (value.typeId() == Exiv2::asciiString) {
        QDateTime val = dateTimeFromString(value.toString().c_str());
        if (val.isValid()) {
            // Datetime is stored in exif as local time.
            val.setUtcOffset(0);
            return val;
        }
    }

    return QDateTime();
}

void Exiv2Extractor::extract(const QString& filePath)
{
    QByteArray arr = QFile::encodeName(filePath);
    std::string fileString(arr.data(), arr.length());

    Exiv2::LogMsg::setLevel(Exiv2::LogMsg::mute);
#if EXIV2_TEST_VERSION(0, 27, 99)
    Exiv2::Image::UniquePtr image;
#else
     Exiv2::Image::AutoPtr image;
#endif
     try {
        image = Exiv2::ImageFactory::open(fileString);
    } catch (const std::exception&) {
        return;
    }
    if (!image.get()) {
        return;
    }

    if (!image->good()) {
        return;
    }

    try {
        image->readMetadata();
    } catch (const std::exception&) {
        return;
    }

    const Exiv2::ExifData& data = image->exifData();

    Exiv2::ExifData::const_iterator it = data.findKey(Exiv2::ExifKey("Exif.Photo.DateTimeOriginal"));
    if (it != data.end()) {
        m_dateTime = toDateTime(it->value());
    }
    if (m_dateTime.isNull()) {
        it = data.findKey(Exiv2::ExifKey("Exif.Image.DateTime"));
        if (it != data.end()) {
            m_dateTime = toDateTime(it->value());
        }
    }

    m_latitude = fetchGpsDouble(data, "Exif.GPSInfo.GPSLatitude");
    m_longitude = fetchGpsDouble(data, "Exif.GPSInfo.GPSLongitude");

    QByteArray latRef = fetchByteArray(data, "Exif.GPSInfo.GPSLatitudeRef");
    if (!latRef.isEmpty() && latRef[0] == 'S')
        m_latitude *= -1;

    QByteArray longRef = fetchByteArray(data, "Exif.GPSInfo.GPSLongitudeRef");
    if (!longRef.isEmpty() && longRef[0] == 'W')
        m_longitude *= -1;

    m_error = false;
}

double Exiv2Extractor::fetchGpsDouble(const Exiv2::ExifData& data, const char* name)
{
    Exiv2::ExifData::const_iterator it = data.findKey(Exiv2::ExifKey(name));
    if (it != data.end() && it->count() == 3) {
        double n = 0.0;
        double d = 0.0;

        n = (*it).toRational(0).first;
        d = (*it).toRational(0).second;

        if (d == 0) {
            return 0.0;
        }

        double deg = n / d;

        n = (*it).toRational(1).first;
        d = (*it).toRational(1).second;

        if (d == 0) {
            return deg;
        }

        double min = n / d;
        if (min != -1.0) {
            deg += min / 60.0;
        }

        n = (*it).toRational(2).first;
        d = (*it).toRational(2).second;

        if (d == 0) {
            return deg;
        }

        double sec = n / d;
        if (sec != -1.0) {
            deg += sec / 3600.0;
        }

        return deg;
    }

    return 0.0;
}

QByteArray Exiv2Extractor::fetchByteArray(const Exiv2::ExifData& data, const char* name)
{
    Exiv2::ExifData::const_iterator it = data.findKey(Exiv2::ExifKey(name));
    if (it != data.end()) {
        std::string str = it->value().toString();
        return QByteArray(str.c_str(), str.size());
    }

    return QByteArray();
}

bool Exiv2Extractor::error() const
{
    return m_error;
}

