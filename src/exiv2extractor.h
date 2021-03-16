/*
 * SPDX-FileCopyrightText: 2012-2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef EXIV2EXTRACTOR_H
#define EXIV2EXTRACTOR_H

#include <exiv2/exiv2.hpp>

#include "koko_export.h"
#include <QDateTime>
#include <QObject>
#include <QString>
#include <QUrl>

class KOKO_EXPORT Exiv2Extractor : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QUrl filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    Q_PROPERTY(double gpsLatitude READ gpsLatitude NOTIFY filePathChanged)
    Q_PROPERTY(double gpsLongitude READ gpsLongitude NOTIFY filePathChanged)
    Q_PROPERTY(QDateTime dateTime READ dateTime NOTIFY filePathChanged)
    Q_PROPERTY(QString simplifiedPath READ simplifiedPath NOTIFY filePathChanged)
    Q_PROPERTY(int height READ height NOTIFY filePathChanged)
    Q_PROPERTY(int width READ width NOTIFY filePathChanged)
    Q_PROPERTY(int size READ size NOTIFY filePathChanged)
    Q_PROPERTY(QString model READ model NOTIFY filePathChanged)
    Q_PROPERTY(QString time READ time NOTIFY filePathChanged)
    Q_PROPERTY(bool favorite READ favorite NOTIFY favoriteChanged)
    Q_PROPERTY(int rating READ rating WRITE setRating NOTIFY filePathChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY filePathChanged)
    Q_PROPERTY(QStringList tags READ tags WRITE setTags NOTIFY filePathChanged)

public:
    explicit Exiv2Extractor(QObject *parent = nullptr);
    ~Exiv2Extractor();

    void extract(const QString &filePath);
    Q_INVOKABLE void updateFavorite(const QString &filePath);
    Q_INVOKABLE void toggleFavorite(const QString &filePath);

    QUrl filePath() const;
    void setFilePath(const QUrl &filePath)
    {
        extract(filePath.toLocalFile());
    }

    double gpsLatitude() const
    {
        return m_latitude;
    }
    double gpsLongitude() const
    {
        return m_longitude;
    }

    QDateTime dateTime() const
    {
        return m_dateTime;
    }

    QString simplifiedPath() const;

    int height() const
    {
        return m_height;
    }
    int width() const
    {
        return m_width;
    }

    int size() const
    {
        return m_size;
    }

    QString model() const
    {
        return m_model;
    }

    QString time() const
    {
        return m_time;
    }

    bool favorite() const
    {
        return m_favorite;
    }

    int rating() const
    {
        return m_rating;
    }

    QString description() const
    {
        return m_description;
    }

    QStringList tags() const
    {
        return m_tags;
    }

    void setRating(const int &rating);
    void setDescription(const QString &description);
    void setTags(const QStringList &tags);

    bool error() const;

Q_SIGNALS:
    void filePathChanged();
    void favoriteChanged();

private:
    double fetchGpsDouble(const Exiv2::ExifData &data, const char *name);
    QByteArray fetchByteArray(const Exiv2::ExifData &data, const char *name);

    QString m_filePath;
    double m_latitude;
    double m_longitude;
    QDateTime m_dateTime;
    int m_height;
    int m_width;
    int m_size;
    QString m_model;
    QString m_time;
    bool m_favorite;
    int m_rating;
    QString m_description;
    QStringList m_tags;

    bool m_error;
};

#endif // EXIV2EXTRACTOR_H
