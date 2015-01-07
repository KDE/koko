/*
 * <one line to give the library's name and an idea of what it does.>
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
#include <QEventLoop>

#include "reversegeocodelookupjob.h"
#include "imagestorage.h"
#include "exiv2extractor.h"

using namespace Koko;

ImageProcessorRunnable::ImageProcessorRunnable(QString& filePath)
    : QObject()
    , m_path(filePath)
{
}


void ImageProcessorRunnable::run()
{
    ImageInfo ii;
    ii.path = m_path;

    Exiv2Extractor extractor;
    extractor.extract(m_path);

    double latitude = extractor.gpsLatitude();
    double longitude = extractor.gpsLongitude();

    if (latitude && longitude) {
        ReverseGeoCodeLookupJob* job = new ReverseGeoCodeLookupJob(QGeoCoordinate(latitude, longitude));
        QEventLoop loop;
        QObject::connect(job, SIGNAL(result(QGeoLocation)), &loop, SLOT(quit()));
        QObject::connect(job, &ReverseGeoCodeLookupJob::result, [&](const QGeoLocation& result) {
            ii.location = result;
        });
        job->start();
        loop.exec(QEventLoop::ExcludeUserInputEvents);
    }

    ii.dateTime = extractor.dateTime();
    if (ii.dateTime.isNull()) {
        ii.dateTime = QFileInfo(m_path).created();
    }

    ImageStorage::instance()->addImage(ii);

    emit finished();
}
