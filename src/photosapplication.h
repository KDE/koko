// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>

#pragma once

#include <AbstractKirigamiApplication>

class PhotosApplication : public AbstractKirigamiApplication
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit PhotosApplication(QObject *parent = nullptr);
    ~PhotosApplication() override;

Q_SIGNALS:
    void filterBy(const QString &filter, const QString &query);

private:
    void setupActions() override;
};