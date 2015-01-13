/*
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

#include <QTest>
#include <QSignalSpy>
#include <QDebug>

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
