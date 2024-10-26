/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef ITEMTYPES_H
#define ITEMTYPES_H
#include "exiv2extractor.h"
#include <QObject>
#include <qqmlintegration.h>

class Types : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("ENUM")

    Q_ENUMS(ItemTypes)
    Q_ENUMS(TimeGroup)
    Q_ENUMS(LocationGroup)
    Q_ENUMS(QueryType)
public:
    using QObject::QObject;
    ~Types() = default;

    enum ItemTypes { Album = 0, Folder, Image };

    enum TimeGroup { Year = 3, Month, Week, Day };

    enum LocationGroup { Country = 7, State, City };

    enum QueryType { LocationQuery = 10, TimeQuery };
};

class Exiv2ExtractorForeign
{
    Q_GADGET
    QML_NAMED_ELEMENT(Exiv2Extractor)
    QML_FOREIGN(Exiv2Extractor)
};

#endif
