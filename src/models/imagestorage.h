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
    enum class ItemTypes {
        NotSet,
        Album,
        Folder,
        Image
    };
    Q_ENUM(ItemTypes)

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

    ImageStorage(QObject *parent = nullptr);
    virtual ~ImageStorage();

    Q_INVOKABLE void addImage(const ImageInfo &ii);
    void removeImage(const QString &filePath);
    bool imageExists(const QString &filePath);
    void commit();

    static ImageStorage *instance();

    QList<QPair<QByteArray, QString>> locations(LocationGroup loca);
    KFileItemList imagesForLocation(const QByteArray &name, LocationGroup loc);
    QString imageForLocation(const QByteArray &name, LocationGroup loc);

    QList<QPair<QByteArray, QString>> timeTypes(TimeGroup group);
    KFileItemList imagesForTime(const QByteArray &name, TimeGroup group);
    QString imageForTime(const QByteArray &name, TimeGroup group);

    KFileItemList imagesForFavorites();

    QStringList tags();
    QStringList imagesForTag(const QString &tag);

    QDate dateForKey(const QByteArray &key, TimeGroup group);

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
