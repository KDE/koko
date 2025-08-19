/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <QPainter>
#include <algorithm>

#include "checkerboardimageprovider.h"

CheckerboardImageProvider::CheckerboardImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
}

QPixmap CheckerboardImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    if (requestedSize.isEmpty()) {
        *size = QSize(32, 32);
    } else {
        *size = requestedSize * 2;
    }

    const int width = size->width();
    const int height = size->height();
    QPixmap pixmap(width, height);

    const QColor baseColor(id);
    const float baseValue = baseColor.valueF();
    const bool isLight = baseValue >= 0.5;

    QColor primaryColor;
    primaryColor.setHsvF(baseColor.hsvHueF(), baseColor.hsvSaturationF(), isLight ? baseValue - 0.2 : baseValue + 0.2);

    QColor secondaryColor;
    secondaryColor.setHsvF(baseColor.hsvHueF(), baseColor.hsvSaturationF(), isLight ? baseValue - 0.4 : baseValue + 0.4);

    QPainter painter(&pixmap);
    painter.fillRect(pixmap.rect(), secondaryColor);
    painter.fillRect(0, 0, width / 2, height / 2, primaryColor);
    painter.fillRect(width / 2, height / 2, width / 2, height / 2, primaryColor);

    return pixmap;
}
