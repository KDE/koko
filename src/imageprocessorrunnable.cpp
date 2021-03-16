/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "imageprocessorrunnable.h"

#include <QFileInfo>

#include "exiv2extractor.h"
#include "imagestorage.h"
#include "reversegeocoder.h"

using namespace Koko;

ImageProcessorRunnable::ImageProcessorRunnable(const QString &filePath, ReverseGeoCoder *geoCoder)
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
        QVariantMap map = m_geoCoder->lookup(latitude, longitude);

        QGeoAddress addr;
        addr.setCountry(map.value("country").toString());
        addr.setState(map.value("admin1").toString());
        addr.setCity(map.value("admin2").toString());
        ii.location.setAddress(addr);
    }

    if (extractor.favorite()) {
        ii.favorite = true;
    }

    ii.tags = extractor.tags();

    ii.dateTime = extractor.dateTime();
    if (ii.dateTime.isNull()) {
        ii.dateTime = QFileInfo(m_path).birthTime();
    }

    QMetaObject::invokeMethod(ImageStorage::instance(), "addImage", Qt::AutoConnection, Q_ARG(const ImageInfo &, ii));

    emit finished();
}
