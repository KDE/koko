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


#ifndef EXIV2EXTRACTOR_H
#define EXIV2EXTRACTOR_H

#include <exiv2/exiv2.hpp>

#include <QString>
#include <QDateTime>

class Exiv2Extractor
{
public:
    Exiv2Extractor();

    void extract(const QString& filePath);

    double gpsLatitude() { return m_latitude; }
    double gpsLongitude() { return m_longitude; }
    QDateTime dateTime() { return m_dateTime; }

private:
    double fetchGpsDouble(const Exiv2::ExifData& data, const char* name);
    QByteArray fetchByteArray(const Exiv2::ExifData& data, const char* name);

    double m_latitude;
    double m_longitude;
    QDateTime m_dateTime;
};

#endif // EXIV2EXTRACTOR_H
