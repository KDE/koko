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

    QVariantMap lookup(double lat, double lon) const;

private:
    kdtree* m_tree;
};
}

#endif // KOKO_REVERSEGEOCODER_H
