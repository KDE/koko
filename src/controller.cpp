// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "controller.h"

#ifndef Q_OS_ANDROID
#include <KConfigGroup>
#include <KSharedConfig>
#include <KWindowConfig>
#include <QQuickWindow>
#endif

void Controller::saveWindowGeometry(QQuickWindow *window)
{
#ifndef Q_OS_ANDROID
    KConfig dataResource(QStringLiteral("data"), KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
    KConfigGroup windowGroup(&dataResource, QStringLiteral("Window"));
    KWindowConfig::saveWindowPosition(window, windowGroup);
    KWindowConfig::saveWindowSize(window, windowGroup);
    dataResource.sync();
#endif
}