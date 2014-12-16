/*
 * Copyright (C) 2014  Vishesh Handa <me@vhanda.in>
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

#include "processor.h"
#include "reversegeocodelookupjob.h"
#include "imagestorage.h"

#include <QTimer>
#include <QFileInfo>
#include <QEventLoop>

#include <KFileMetaData/SimpleExtractionResult>

Processor::Processor(QObject* parent)
    : QObject(parent)
    , m_numFiles(0)
    , m_processing(false)
{
    m_imageExtractor = m_extractors.fetchExtractors("image/jpeg").first();
}

Processor::~Processor()
{

}

void Processor::addFile(const QString& filePath)
{
    m_files << filePath;
    m_numFiles++;

    QTimer::singleShot(0, this, SLOT(process()));
}

void Processor::removeFile(const QString& filePath)
{
    Q_UNUSED(filePath);
    // FIXME: Implement this!
}

float Processor::initialProgress()
{
    if (m_numFiles) {
        return 1.0 - (m_files.size() * 1.0 / m_numFiles);
    }

    return 0;
}

void Processor::process()
{
    if (m_processing)
        return;

    if (m_files.isEmpty()) {
        return;
    }

    m_processing = true;
    QString path = m_files.takeLast();

    ImageInfo ii;
    ii.path = path;

    KFileMetaData::SimpleExtractionResult result(path);
    m_imageExtractor->extract(&result);

    double latitude = result.properties().value(KFileMetaData::Property::PhotoGpsLatitude).toDouble();
    double longitude = result.properties().value(KFileMetaData::Property::PhotoGpsLongitude).toDouble();

    if (latitude && longitude) {
        ReverseGeoCodeLookupJob* job = new ReverseGeoCodeLookupJob(QGeoCoordinate(latitude, longitude));
        QEventLoop loop;
        QObject::connect(job, SIGNAL(result(QGeoLocation)), &loop, SLOT(quit()));
        QObject::connect(job, &ReverseGeoCodeLookupJob::result, [&](const QGeoLocation& result) {
            ii.location = result;
        });
        job->start();
        loop.exec();
    }

    ii.dateTime = result.properties().value(KFileMetaData::Property::PhotoDateTimeOriginal).toDateTime();
    if (ii.dateTime.isNull()) {
        ii.dateTime = result.properties().value(KFileMetaData::Property::ImageDateTime).toDateTime();
    }
    if (ii.dateTime.isNull()) {
        ii.dateTime = QFileInfo(path).created();
    }

    qDebug() << path << ii.dateTime;

    ImageStorage::instance()->addImage(ii);

    m_processing = false;
    QTimer::singleShot(0, this, SLOT(process()));

    emit initialProgressChanged();
}
