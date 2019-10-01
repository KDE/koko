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

#include "imageprocessorrunnable.h"

#include <QFileInfo>

#include "reversegeocoder.h"
#include "imagestorage.h"
#include "exiv2extractor.h"

using namespace Koko;

ImageProcessorRunnable::ImageProcessorRunnable(QString& filePath, ReverseGeoCoder* geoCoder)
    : QObject()
    , m_path(filePath)
    , m_geoCoder(geoCoder)
{
}


void ImageProcessorRunnable::run()
{
    ImageInfo ii;
    ii.path = m_path;

    Exiv2Extractor extractor;
    extractor.extract(m_path);
    if (extractor.error()) {
        emit finished();
        return;
    }

    double latitude = extractor.gpsLatitude();
    double longitude = extractor.gpsLongitude();

    if (latitude != 0.0 && longitude != 0.0) {
        if (!m_geoCoder->initialized()) {
            m_geoCoder->init();
        }
        QVariantMap map = m_geoCoder->lookup(latitude, longitude);

        QGeoAddress addr;
        addr.setCountry(map.value("country").toString());
        addr.setState(map.value("admin1").toString());
        addr.setCity(map.value("admin2").toString());
        ii.location.setAddress(addr);
    }

    ii.dateTime = extractor.dateTime();
    if (ii.dateTime.isNull()) {
        ii.dateTime = QFileInfo(m_path).created();
    }

    QMetaObject::invokeMethod(ImageStorage::instance(), "addImage", Qt::AutoConnection, Q_ARG(const ImageInfo&, ii));

    emit finished();
}
