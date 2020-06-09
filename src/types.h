/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.0-or-later
 */

#ifndef ITEMTYPES_H
#define ITEMTYPES_H
#include <QObject>

class Types : public QObject
{
    Q_OBJECT
    Q_ENUMS(ItemTypes)
    Q_ENUMS(TimeGroup)
    Q_ENUMS(LocationGroup)
    Q_ENUMS(QueryType)
public:
    Types(QObject *parent);
    ~Types();

    enum ItemTypes { Album = 0, Folder, Image };

    enum TimeGroup { Year = 3, Month, Week, Day };

    enum LocationGroup { Country = 7, State, City };

    enum QueryType { LocationQuery = 10, TimeQuery };
};

#endif
