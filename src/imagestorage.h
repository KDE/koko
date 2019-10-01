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

#ifndef IMAGESTORAGE_H
#define IMAGESTORAGE_H

#include <QObject>
#include <QGeoLocation>
#include <QGeoAddress>
#include <QDateTime>
#include <QDataStream>

#include <QMutex>
#include <QMutexLocker>

#include "types.h"
#include "koko_export.h"

struct ImageInfo {
    QString path;
    QGeoLocation location;
    QDateTime dateTime;
};

class KOKO_EXPORT ImageStorage : public QObject
{
    Q_OBJECT
public:
    ImageStorage(QObject* parent = 0);
    virtual ~ImageStorage();

    Q_INVOKABLE void addImage(const ImageInfo& ii);
    void removeImage(const QString& filePath);
    void commit();

    static ImageStorage* instance();

    QList< QPair<QByteArray, QString> > locations(Types::LocationGroup loca);
    QStringList imagesForLocation(const QByteArray& name, Types::LocationGroup loc);
    QString imageForLocation(const QByteArray& name, Types::LocationGroup loc);

    QList< QPair<QByteArray, QString> > timeTypes(Types::TimeGroup group);
    QStringList imagesForTime(const QByteArray& name, Types::TimeGroup group);
    QString imageForTime(const QByteArray& name, Types::TimeGroup group);

    QDate dateForKey(const QByteArray& key, Types::TimeGroup group);

    /**
     * Fetch all the images ordered by descending date time.
     */
    QStringList allImages(int size = -1, int offset = 0);

    static void reset();

signals:
    void storageModified();

private:
    mutable QMutex m_mutex;
};


Q_DECLARE_METATYPE(ImageInfo);

#endif // IMAGESTORAGE_H
