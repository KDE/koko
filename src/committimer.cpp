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

#include "committimer.h"

using namespace Koko;

CommitTimer::CommitTimer(QObject* parent)
    : QObject(parent)
{
    m_smallTimer.setInterval(200);
    m_smallTimer.setSingleShot(true);
    connect(&m_smallTimer, &QTimer::timeout, this, &CommitTimer::slotTimeout);

    m_largeTimer.setSingleShot(true);
    m_largeTimer.setInterval(10000);
    connect(&m_largeTimer, &QTimer::timeout, this, &CommitTimer::slotTimeout);
}

void CommitTimer::start()
{
    m_smallTimer.start();
    if (!m_largeTimer.isActive()) {
        m_largeTimer.start();
    }
}

void CommitTimer::slotTimeout()
{
    m_smallTimer.stop();
    m_largeTimer.stop();

    Q_EMIT timeout();
}


