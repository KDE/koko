/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#include "reversegeocoder.h"

#include <QFile>
#include <QStandardPaths>
#include <QTextStream>

#include <QDebug>

using namespace Koko;

ReverseGeoCoder::ReverseGeoCoder()
    : m_tree(0)
{
}

ReverseGeoCoder::~ReverseGeoCoder()
{
    deinit();
}

void ReverseGeoCoder::init()
{
    m_tree = kd_create(2);

    QString citiesPath = QStandardPaths::locate(QStandardPaths::DataLocation, "cities1000.txt");
    Q_ASSERT(!citiesPath.isEmpty());

    QFile file(citiesPath);
    if (!file.open(QIODevice::ReadOnly)) {
        Q_ASSERT_X(0, "", "Failed to open cities1000.txt file");
    }
    QTextStream fstream(&file);

    while (!fstream.atEnd()) {
        QString str = fstream.readLine();
        str.remove('\r');

        QStringList list = str.split('\t');

        // int geoId = list[0].toInt();
        // QString name = list[1];
        double lat = list[4].toDouble();
        double lon = list[5].toDouble();
        QString countryCode = list[8];
        QString admin1Code = list[10];
        QString admin2Code = list[11];

        QVariantMap *map = new QVariantMap();
        // map->insert("geoId", geoId);
        // map->insert("name", name);
        map->insert("countryCode", countryCode);
        map->insert("admin1Code", admin1Code);
        map->insert("admin2Code", admin2Code);

        kd_insert3(m_tree, lat, lon, 0.0, static_cast<void *>(map));
    }

    // Country
    QString countryPath = QStandardPaths::locate(QStandardPaths::DataLocation, "countries.csv");
    Q_ASSERT(!countryPath.isEmpty());

    QFile cFile(countryPath);
    if (!cFile.open(QIODevice::ReadOnly)) {
        Q_ASSERT_X(0, "", "Failed to open countries.csv file");
    }
    QTextStream cstream(&cFile);

    while (!cstream.atEnd()) {
        QString str = cstream.readLine();

        QStringList list = str.split(',');

        QString code = list[0];
        QString name = list[1];
        m_countryMap.insert(code, name);
    }
    Q_ASSERT_X(!m_countryMap.isEmpty(), "", "countries.csv file is empty. Packaging issue");

    // Admin1
    QString admin1Path = QStandardPaths::locate(QStandardPaths::DataLocation, "admin1Codes.txt");
    Q_ASSERT(!admin1Path.isEmpty());

    QFile admin1File(admin1Path);
    if (!admin1File.open(QIODevice::ReadOnly)) {
        Q_ASSERT_X(0, "", "Failed to open admin1Codes.txt file");
    }
    QTextStream a1fstream(&admin1File);

    while (!a1fstream.atEnd()) {
        QString str = a1fstream.readLine();
        str.remove('\r');

        QStringList list = str.split('\t');

        QString code = list[0];
        QString name = list[1];
        m_admin1Map.insert(code, name);
    }
    Q_ASSERT_X(!m_admin1Map.isEmpty(), "", "admin1Codes.txt file is empty. Packaging issue");

    // Admin2
    QString admin2Path = QStandardPaths::locate(QStandardPaths::DataLocation, "admin2Codes.txt");
    Q_ASSERT(!admin2Path.isEmpty());

    QFile admin2File(admin2Path);
    if (!admin2File.open(QIODevice::ReadOnly)) {
        Q_ASSERT_X(0, "", "Failed to open admin2Codes.txt file");
    }
    QTextStream a2fstream(&admin2File);

    while (!a2fstream.atEnd()) {
        QString str = a2fstream.readLine();
        str.remove('\r');

        QStringList list = str.split('\t');

        QString code = list[0];
        QString name = list[1];
        m_admin2Map.insert(code, name);
    }
    Q_ASSERT_X(!m_admin2Map.isEmpty(), "", "admin2Codes.txt file is empty. Packaging issue");
}

void ReverseGeoCoder::deinit()
{
    if (m_tree) {
        kd_free(m_tree);
        m_tree = 0;
    }

    m_countryMap.clear();
    m_admin1Map.clear();
    m_admin2Map.clear();
}

bool ReverseGeoCoder::initialized()
{
    return m_tree;
}

QVariantMap ReverseGeoCoder::lookup(double lat, double lon) const
{
    Q_ASSERT(m_tree);

    kdres *res = kd_nearest3(m_tree, lat, lon, 0.0);
    if (!res) {
        return QVariantMap();
    }

    void *data = kd_res_item_data(res);
    kd_res_free(res);

    QVariantMap map = *static_cast<QVariantMap *>(data);

    QString country = map.value("countryCode").toString();
    QString admin1 = country + '.' + map.value("admin1Code").toString();
    QString admin2 = admin1 + '.' + map.value("admin2Code").toString();

    QVariantMap vMap;
    vMap.insert("country", m_countryMap.value(country));
    vMap.insert("admin1", m_admin1Map.value(admin1));
    vMap.insert("admin2", m_admin2Map.value(admin2));

    return vMap;
}
