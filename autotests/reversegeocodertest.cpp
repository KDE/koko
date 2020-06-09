/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#include <QDebug>
#include <QSignalSpy>
#include <QTest>

#include <QCoreApplication>
#include <QTime>

#include "reversegeocoder.h"

class ReverseGeoCoderTest : public QObject
{
    Q_OBJECT

private slots:
    void testSimple();
};

using namespace Koko;

void ReverseGeoCoderTest::testSimple()
{
    QCoreApplication::instance()->setApplicationName("koko");

    ReverseGeoCoder coder;
    QCOMPARE(coder.initialized(), false);
    coder.init();
    QCOMPARE(coder.initialized(), true);

    double lat = 52.54877605;
    double lon = -1.81627023283164;

    QVariantMap data = coder.lookup(lat, lon);
    QCOMPARE(data.value("country").toString(), QString("United Kingdom"));
    QCOMPARE(data.value("admin1").toString(), QString("England"));
    QCOMPARE(data.value("admin2").toString(), QString("City and Borough of Birmingham"));
}

QTEST_MAIN(ReverseGeoCoderTest)

#include "reversegeocodertest.moc"
