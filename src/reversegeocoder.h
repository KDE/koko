/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef KOKO_REVERSEGEOCODER_H
#define KOKO_REVERSEGEOCODER_H

#include <QMutexLocker>
#include <QVariantMap>
#include <kdtree.h>

namespace Koko
{
class ReverseGeoCoder
{
public:
    ~ReverseGeoCoder();

    void init();
    bool initialized();

    // Do nothing if it's already initialized
    void tryInitialization();

    /**
     * The ReverseGeoCoder consumes a significant amount of memory (around 100mb). It
     * makes sense to deinit it when it is not being used.
     */
    void deinit();

    QVariantMap lookup(double lat, double lon);

private:
    KdTree m_tree;
    QMap<QString, QString> m_countryMap;
    QMap<QString, QString> m_admin1Map;
    QMap<QString, QString> m_admin2Map;
    QMutex m_mutex;
};
}

#endif // KOKO_REVERSEGEOCODER_H
