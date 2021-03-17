// SPDX-FileCopyrightText: 2014  Vishesh Handa <vhanda@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#ifndef IMAGESTORAGE_H
#define IMAGESTORAGE_H

#include <QDataStream>
#include <QDateTime>
#include <QGeoAddress>
#include <QGeoLocation>
#include <QObject>

#include <QMutex>
#include <QMutexLocker>

#include "koko_export.h"
#include "types.h"

struct ImageInfo {
    QString path;
    QGeoLocation location;
    QDateTime dateTime;
    QStringList tags;
    bool favorite;
};

class KOKO_EXPORT ImageStorage : public QObject
{
    Q_OBJECT
public:
    ImageStorage(QObject *parent = nullptr);
    virtual ~ImageStorage();

    Q_INVOKABLE void addImage(const ImageInfo &ii);
    void removeImage(const QString &filePath);
    bool imageExists(const QString &filePath);
    void commit();

    static ImageStorage *instance();

    QList<QPair<QByteArray, QString>> locations(Types::LocationGroup loca);
    QStringList imagesForLocation(const QByteArray &name, Types::LocationGroup loc);
    QString imageForLocation(const QByteArray &name, Types::LocationGroup loc);

    QList<QPair<QByteArray, QString>> timeTypes(Types::TimeGroup group);
    QStringList imagesForTime(const QByteArray &name, Types::TimeGroup group);
    QString imageForTime(const QByteArray &name, Types::TimeGroup group);

    QStringList imagesForFavorites();

    QStringList tags();
    QStringList imagesForTag(const QString &tag);

    QDate dateForKey(const QByteArray &key, Types::TimeGroup group);

    /**
     * Fetch all the images ordered by descending date time.
     */
    QStringList allImages(int size = -1, int offset = 0);

    static void reset();
    static bool shouldReset();

signals:
    void storageModified();

private:
    mutable QMutex m_mutex;
};

Q_DECLARE_METATYPE(ImageInfo);

#endif // IMAGESTORAGE_H
