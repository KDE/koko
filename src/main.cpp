/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
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

#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QEventLoop>

#include <QStandardPaths>
#include <QDebug>
#include <QFileInfo>

#include <KFileMetaData/ExtractorCollection>
#include <KFileMetaData/Extractor>
#include <KFileMetaData/SimpleExtractionResult>

#include "filesystemtracker.h"
#include "reversegeocodelookupjob.h"
#include "imagestorage.h"

int main(int argc, char** argv)
{
    QApplication app(argc, argv);
    app.setApplicationDisplayName("Gallery");

    KFileMetaData::ExtractorCollection extractors;
    KFileMetaData::Extractor* imageExtractor = extractors.fetchExtractors("image/jpeg").first();

    auto func = [&](const QString& path) {
        ImageInfo ii;
        ii.path = path;

        KFileMetaData::SimpleExtractionResult result(path);
        imageExtractor->extract(&result);

        double latitude = result.properties().value(KFileMetaData::Property::PhotoGpsLatitude).toDouble();
        double longitude = result.properties().value(KFileMetaData::Property::PhotoGpsLongitude).toDouble();

        if (latitude && longitude) {
            qDebug() << path << latitude << longitude;

            ReverseGeoCodeLookupJob* job = new ReverseGeoCodeLookupJob(QGeoCoordinate(latitude, longitude));
            QEventLoop loop;
            QObject::connect(job, SIGNAL(result(QGeoLocation)), &loop, SLOT(quit()));
            QObject::connect(job, &ReverseGeoCodeLookupJob::result, [&](const QGeoLocation& result) {
                ii.location = result;
            });
            job->start();
            loop.exec();
        }

        ii.date = result.properties().value(KFileMetaData::Property::PhotoDateTimeOriginal).toDateTime();
        if (ii.date.isNull()) {
            ii.date = result.properties().value(KFileMetaData::Property::ImageDateTime).toDateTime();
        }
        if (ii.date.isNull()) {
            ii.date = QFileInfo(path).created();
        }

        qDebug() << path << ii.date;

        ImageStorage::instance()->addImage(ii);
    };

    FileSystemTracker tracker;
    QObject::connect(&tracker, &FileSystemTracker::imageAdded, func);

    qDebug() << "Starting QML";
    QQmlEngine engine;
    QQmlContext* objectContext = engine.rootContext();

    QString path = QStandardPaths::locate(QStandardPaths::DataLocation, "main4.qml");
    QQmlComponent component(&engine, path);
    component.create(objectContext);

    return app.exec();
}
