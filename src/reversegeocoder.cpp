/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "reversegeocoder.h"

#include <QFile>
#include <QStandardPaths>
#include <QTextStream>

#include <QDebug>
#include <QMutexLocker>

using namespace Koko;

ReverseGeoCoder::~ReverseGeoCoder()
{
    deinit();
}

void ReverseGeoCoder::init()
{
    QString citiesPath = QStandardPaths::locate(QStandardPaths::AppDataLocation, "cities1000.txt");
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

        QVariantMap map = QVariantMap();
        // map.insert("geoId", geoId);
        // map.insert("name", name);
        map.insert("countryCode", countryCode);
        map.insert("admin1Code", admin1Code);
        map.insert("admin2Code", admin2Code);

        m_tree.insert(lat, lon, map);
    }

    // Country
    QString countryPath = QStandardPaths::locate(QStandardPaths::AppDataLocation, "countries.csv");
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
    QString admin1Path = QStandardPaths::locate(QStandardPaths::AppDataLocation, "admin1Codes.txt");
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
    QString admin2Path = QStandardPaths::locate(QStandardPaths::AppDataLocation, "admin2Codes.txt");
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
    QMutexLocker locker(&m_mutex);

    m_tree.clear();
    m_countryMap.clear();
    m_admin1Map.clear();
    m_admin2Map.clear();
}

bool ReverseGeoCoder::initialized()
{
    return !m_tree.isEmpty();
}

QVariantMap ReverseGeoCoder::lookup(double lat, double lon)
{
    QMutexLocker locker(&m_mutex);
    if (!initialized()) {
        init();
    }
    Q_ASSERT(!m_tree.isEmpty());

    KdNode *res = m_tree.findNearest(lat, lon);
    if (res == nullptr) {
        return QVariantMap();
    }

    QVariantMap map = res->data;

    QString country = map.value("countryCode").toString();
    QString admin1 = country + '.' + map.value("admin1Code").toString();
    QString admin2 = admin1 + '.' + map.value("admin2Code").toString();

    QVariantMap vMap;
    vMap.insert("country", m_countryMap.value(country));
    vMap.insert("admin1", m_admin1Map.value(admin1));
    vMap.insert("admin2", m_admin2Map.value(admin2));

    return vMap;
}
