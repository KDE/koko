/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include <QApplication>

#include "thumbnailmanager.h"

ThumbnailManager *ThumbnailManager::instance()
{
    static ThumbnailManager *instance = new ThumbnailManager(qApp);
    return instance;
};

ThumbnailManager::ThumbnailManager(QObject *parent)
    : QObject(parent)
{
}

void ThumbnailManager::registerItem(QPointer<ThumbnailItem> item)
{
}

void ThumbnailManager::updateItemPriority(QPointer<ThumbnailItem> item, int priority)
{
}

void ThumbnailManager::requestThumbnail(QPointer<ThumbnailItem> item, const QUrl &url, const QSize &size)
{
}
