/*
 * <one line to give the library's name and an idea of what it does.>
 * Copyright (C) 2015  Vishesh Handa <vhanda@kde.org>
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

#include "reversegeocoder.h"

#include <QStandardPaths>
#include <QFile>
#include <QTextStream>

#include <QDebug>

using namespace Koko;

ReverseGeoCoder::ReverseGeoCoder()
    : m_tree(0)
{
}

ReverseGeoCoder::~ReverseGeoCoder()
{
    if (m_tree) {
        kd_free(m_tree);
    }
}

void ReverseGeoCoder::init()
{
    m_tree = kd_create(2);

    QString path = QStandardPaths::locate(QStandardPaths::DataLocation, "cities1000.txt");
    Q_ASSERT(!path.isEmpty());

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        Q_ASSERT_X(0, "", "Failed to open cities1000.txt file");
    }
    QTextStream fstream(&file);

    while (!fstream.atEnd()) {
        QString str = fstream.readLine();
        str.remove('\r');

        QStringList list = str.split('\t');

        int geoId = list[0].toInt();
        QString name = list[1];
        double lat = list[4].toDouble();
        double lon = list[5].toDouble();
        QString countryCode = list[8];
        QString admin1Code = list[10];
        QString admin2Code = list[11];

        QVariantMap* map = new QVariantMap();
        map->insert("geoId", geoId);
        map->insert("name", name);
        map->insert("countryCode", countryCode);
        map->insert("admin1Code", admin1Code);
        map->insert("admin2Code", admin2Code);

        kd_insert3(m_tree, lat, lon, 0.0, static_cast<void*>(map));
    }
}

bool ReverseGeoCoder::initialized()
{
    return m_tree;
}

QVariantMap ReverseGeoCoder::lookup(double lat, double lon) const
{
    Q_ASSERT(m_tree);

    kdres* res = kd_nearest3(m_tree, lat, lon, 0.0);
    if (!res) {
        return QVariantMap();
    }

    void* data = kd_res_item_data(res);
    kd_res_free(res);

    return *static_cast<QVariantMap*>(data);
}
