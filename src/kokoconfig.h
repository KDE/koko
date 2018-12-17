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

#ifndef JUNGLE_JUNGLECONFIG_H
#define JUNGLE_JUNGLECONFIG_H

#include <QObject>
#include <KConfig>
#include <KConfigGroup>

class KokoConfig : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool initialRun READ initialRun WRITE setInitialRun)
    Q_PROPERTY(int iconSize READ iconSize WRITE setIconSize NOTIFY iconSizeChanged)
public:
    KokoConfig(QObject* parent = 0);
    virtual ~KokoConfig();

    bool initialRun() const;
    void setInitialRun(bool value);

    int iconSize() const;
    void setIconSize(int size);

    void reset();
Q_SIGNALS:
    void iconSizeChanged();

private:
    KConfig m_config;
};

#endif // JUNGLE_JUNGLECONFIG_H
