/*
 * SPDX-FileCopyrightText: 2021 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef DISPLAYCOLORSPACE_H
#define DISPLAYCOLORSPACE_H

#include <QColorSpace>
#include <QObject>

/**
 * Provides access to the display color space from QML.
 */
class DisplayColorSpace : public QObject
{
    Q_OBJECT

public:
    DisplayColorSpace(QObject *parent = nullptr);

    /**
     * The color space of the display.
     *
     * This provides a QColorSpace instance that matches the color space of the
     * display. If the color space cannot be retrieved for whatever reason, a
     * default sRGB color space is returned.
     *
     * TODO: Handle screen changes.
     */
    Q_PROPERTY(QColorSpace colorSpace READ colorSpace CONSTANT)
    QColorSpace colorSpace() const;

private:
    void update();

    QColorSpace m_colorSpace;
};

#endif // DISPLAYCOLORSPACE_H
