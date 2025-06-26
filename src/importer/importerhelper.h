// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <QObject>
#include <qqmlregistration.h>

class ImporterHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isMtpWorkerAvailable READ isMtpWorkerAvailable NOTIFY isMtpWorkerAvailableChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool discoverAvailable READ discoverAvailable CONSTANT)

public:
    explicit ImporterHelper(QObject *parent = nullptr);

    bool isMtpWorkerAvailable() const;
    bool loading() const;
    bool discoverAvailable() const;

public Q_SLOTS:
    void installKioWorker();

Q_SIGNALS:
    void isMtpWorkerAvailableChanged() const;
    void loadingChanged() const;
    void errorOccured(const QString &error) const;

private:
    bool m_isMtpWorkerAvailable = false;
    bool m_loading = true;
    bool m_discoverAvailable;
};
