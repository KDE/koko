/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#ifndef KOKO_COMMITTIMER_H
#define KOKO_COMMITTIMER_H

#include <QObject>
#include <QTimer>

namespace Koko
{
class CommitTimer : public QObject
{
    Q_OBJECT
public:
    explicit CommitTimer(QObject *parent = 0);

public slots:
    void start();

signals:
    void timeout();

private slots:
    void slotTimeout();

private:
    QTimer m_smallTimer;
    QTimer m_largeTimer;
};
}

#endif // KOKO_COMMITTIMER_H
