// SPDX-FileCopyrightText: 2014  Vishesh Handa <vhanda@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QDataStream>
#include <QDateTime>
#include <QGeoAddress>
#include <QGeoLocation>
#include <QMutex>
#include <QMutexLocker>
#include <QObject>
#include <qqmlregistration.h>

#include <KFileItem>

struct ImageInfo {
    Q_GADGET
public:
    QString path;
    QGeoLocation location;
    QDateTime dateTime;
    QStringList tags;
    bool favorite;
};

class ImageStorage : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Only enums are exposed to QML")

public:
    enum class TimeGroup {
        NotSet,
        Year,
        Month,
        Week,
        Day
    };
    Q_ENUM(TimeGroup)

    enum class LocationGroup {
        NotSet,
        Country,
        State,
        City
    };
    Q_ENUM(LocationGroup)

    enum class QueryType {
        NotSet,
        Location,
        Time
    };
    Q_ENUM(QueryType)

    struct Collection {
        QByteArray key;
        QString display;
        QueryType queryType;
    };

    ImageStorage(QObject *parent = nullptr);
    virtual ~ImageStorage();

    Q_INVOKABLE void addImage(const ImageInfo &ii);
    void removeImage(const QString &filePath);
    bool imageExists(const QString &filePath);
    void commit();

    static ImageStorage *instance();

    QList<Collection> locations(LocationGroup loca);
    KFileItemList imagesForLocation(const QByteArray &key, LocationGroup loc);
    KFileItem imageForLocation(const Collection &collection, LocationGroup loc);

    QList<Collection> timeTypes(TimeGroup group);
    KFileItemList imagesForTime(const QByteArray &key, TimeGroup group);
    KFileItem imageForTime(const Collection &collection, TimeGroup group);

    KFileItemList imagesForFavorites();

    QStringList tags();
    KFileItemList imagesForTag(const QString &tag);

    QDate dateForCollection(const Collection &collection, TimeGroup group);

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
