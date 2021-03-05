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
#include <QString>
#include <QUrl>
#include <QObject>

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

public:
    explicit Exiv2Extractor(QObject *parent = nullptr);
    ~Exiv2Extractor();

    void extract(const QString &filePath);

    QUrl filePath() const;
    void setFilePath(const QUrl &filePath) {
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

    bool error() const;

Q_SIGNALS:
    void filePathChanged();

private:
    double fetchGpsDouble(const Exiv2::ExifData &data, const char *name);
    QByteArray fetchByteArray(const Exiv2::ExifData &data, const char *name);

    QString m_filePath;
    double m_latitude;
    double m_longitude;
    QDateTime m_dateTime;
    int m_height;
    int m_width;

    bool m_error;
};

#endif // EXIV2EXTRACTOR_H
