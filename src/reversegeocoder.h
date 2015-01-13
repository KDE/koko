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

#ifndef KOKO_REVERSEGEOCODER_H
#define KOKO_REVERSEGEOCODER_H

#include <kdtree.h>
#include <QVariantMap>

namespace Koko {

class ReverseGeoCoder
{
public:
    ReverseGeoCoder();
    ~ReverseGeoCoder();

    void init();
    bool initialized();

    /**
     * The ReverseGeoCoder consumes a significant amount of memory (around 100mb). It
     * makes sense to deinit it when it is not being used.
     */
    void deinit();

    QVariantMap lookup(double lat, double lon) const;

private:
    kdtree* m_tree;
    QMap<QString, QString> m_countryMap;
    QMap<QString, QString> m_admin1Map;
    QMap<QString, QString> m_admin2Map;
};
}

#endif // KOKO_REVERSEGEOCODER_H
