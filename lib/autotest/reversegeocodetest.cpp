/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
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

#include "../reversegeocodelookupjob.h"

class ReverseGeoCodeTest : public QObject
{
    Q_OBJECT

private slots:
    void testSimple();
};

void ReverseGeoCodeTest::testSimple()
{
    QGeoCoordinate coords(52.54877605, -1.81627023283164);

    ReverseGeoCodeLookupJob* job = new ReverseGeoCodeLookupJob(coords);

    QSignalSpy spy(job, SIGNAL(result(QGeoLocation)));
    job->start();
    spy.wait();

    QCOMPARE(spy.count(), 1);
    QGeoLocation loc = spy.takeFirst().first().value<QGeoLocation>();
    QGeoAddress addr = loc.address();

    QCOMPARE(addr.country(), QString("United Kingdom"));
    QCOMPARE(addr.countryCode(), QString("gb"));
    QCOMPARE(addr.city(), QString("Birmingham"));
    QCOMPARE(addr.state(), QString("England"));
    QCOMPARE(addr.postalCode(), QString("B72 1LH"));
}

QTEST_MAIN(ReverseGeoCodeTest)

#include "reversegeocodetest.moc"
