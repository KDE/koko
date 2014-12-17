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

    void addImage(const ImageInfo& ii);
    void commit();

    static ImageStorage* instance();

    enum LocationGroup {
        Country,
        State,
        City
    };
    QList< QPair<QByteArray, QString> > locations(LocationGroup loca);
    QStringList imagesForLocation(const QByteArray& name, LocationGroup loc);
    QString imageForLocation(const QByteArray& name, LocationGroup loc);

    enum TimeGroup {
        Year,
        Month,
        Week,
        Day
    };
    QList< QPair<QByteArray, QString> > timeGroups(TimeGroup group);
    QStringList imagesForTime(const QByteArray& name, TimeGroup group);
    QString imageForTime(const QByteArray& name, TimeGroup group);

    QDate dateForKey(const QByteArray& key, TimeGroup group);

    QList< QPair<QByteArray, QString> > folders() const;
    QStringList imagesForFolders(const QByteArray& key) const;
    QString imageForFolders(const QByteArray& key) const;

private:
    mutable QMutex m_mutex;
};


Q_DECLARE_METATYPE(ImageInfo);

#endif // IMAGESTORAGE_H
