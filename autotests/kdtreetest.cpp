/*
 * SPDX-FileCopyrightText: (C) 2022 Silas Henrique <silash35@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "kdtree.h"
#include <QTest>
#include <QVariantMap>

class KdTreeTest : public QObject
{
    Q_OBJECT

private slots:
    void testSimple();
    void testSearch();
};

void KdTreeTest::testSimple()
{
    KdTree tree;

    QCOMPARE(tree.isEmpty(), true);
    QVariantMap sanFracisco = QVariantMap();
    sanFracisco.insert("name", "San Francisco, California, USA");
    tree.insert(-12.9442526, -38.4938602, sanFracisco);
    QCOMPARE(tree.isEmpty(), false);
    tree.clear();
    QCOMPARE(tree.isEmpty(), true);
}

void KdTreeTest::testSearch()
{
    KdTree tree;

    QVariantMap washington = QVariantMap();
    washington.insert("name", "Washington, District of Columbia, USA");
    tree.insert(38.893938, -77.1546608, washington);

    QVariantMap brasilia = QVariantMap();
    brasilia.insert("name", "Brasília, Federal District, Brazil");
    tree.insert(-15.721387, -48.0774441, brasilia);

    QVariantMap canberra = QVariantMap();
    canberra.insert("name", "Canberra, Australian Capital Territory, Australia");
    tree.insert(-35.3136188, 148.9896982, canberra);

    QVariantMap berlin = QVariantMap();
    berlin.insert("name", "Berlin, Germany");
    tree.insert(52.5069312, 13.1445517, berlin);

    KdNode *res = tree.findNearest(51.5287718, -0.2416818); // London, United Kingdom coordinates
    QCOMPARE(res->data.value("name"), berlin.value("name")); // Berlin is the nearest neighbour of London

    // Numbers should not lose precision (Apart from the normal loss with floats)
    // This prevents someone from using int variables to store the positions
    QCOMPARE(res->point.x(), 52.5069312);
    QCOMPARE(res->point.y(), 13.1445517);
}

QTEST_MAIN(KdTreeTest)

#include "kdtreetest.moc"
