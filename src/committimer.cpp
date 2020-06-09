/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#include "committimer.h"

using namespace Koko;

CommitTimer::CommitTimer(QObject *parent)
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
