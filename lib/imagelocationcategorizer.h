/*
 * <one line to give the library's name and an idea of what it does.>
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

#ifndef IMAGELOCATIONCATEGORIZER_H
#define IMAGELOCATIONCATEGORIZER_H

#include <QString>
#include <QVector>
#include <QHash>

#include "imagestorage.h"

class ImageLocationCategorizer : public QObject
{
    Q_OBJECT
public:
    ImageLocationCategorizer();

    void addImage(const ImageInfo& ii);

    QStringList countries() const;
    QStringList imagesForCountry(const QString& country) const;

    QStringList states() const;
    QStringList imagesForState(const QString& state) const;

    QStringList cities() const;
    QStringList imagesForCities(const QString& city) const;

    QStringList groupByHours(int hours) const;
    QStringList imagesForHours(int hours, const QString& groupName) const;

private:
    QVector<ImageInfo> m_images;
    QHash< QString, QList<ImageInfo> > m_countryHash;
    QHash< QString, QList<ImageInfo> > m_stateHash;
    QHash< QString, QList<ImageInfo> > m_cityHash;


    QHash< QString, QList<ImageInfo> > hourImages(int hour) const;
};

#endif // IMAGELOCATIONCATEGORIZER_H
