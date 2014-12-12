/*
 * Copyright (C) 2014 Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.0

GridView {
    id: gridView
    cellWidth: cellActualWidth + columnSpacing
    cellHeight: cellActualHeight + minRowSpacing

    property int minColumnSpacing : 50
    property int minRowSpacing : 100

    property int columnSpacing : minColumnSpacing
    property int cellActualWidth: 300
    property int cellActualHeight: 300

    function calculateSpacing()
    {
        var minItemWidth = cellActualWidth + minColumnSpacing
        var numCol = Math.min(count, Math.floor(gridView.width / minItemWidth))
        if (numCol <= 0) {
            columnSpacing = minColumnSpacing
            return
        }

        var minSpaceConsumed = numCol * minItemWidth;
        var extraSpace = gridView.width - minSpaceConsumed;
        columnSpacing = minColumnSpacing + (extraSpace / numCol);
    }

    onWidthChanged: calculateSpacing()
}
