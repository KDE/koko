/*
    SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#include <QClipboard>
#include <QGuiApplication>
#include <QMimeData>
#include <QUrl>

#include "cutfilehelper.h"

CutFileHelper::CutFileHelper(QObject *parent)
    : QObject(parent)
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    connect(clipboard, &QClipboard::dataChanged, this, &CutFileHelper::refresh);

    refresh();
}

QList<QUrl> CutFileHelper::urls() const
{
    return m_urls;
}

void CutFileHelper::refresh()
{
    const QMimeData *mimeData = QGuiApplication::clipboard()->mimeData();

    QList<QUrl> urls;

    if (mimeData) {
        static const QString cutSelectionMime = QLatin1String("application/x-kde-cutselection");

        if (mimeData->hasFormat(cutSelectionMime) && mimeData->data(cutSelectionMime).trimmed() == "1") {
            urls = mimeData->urls();
        }
    }

    m_urls = std::move(urls);
    Q_EMIT urlsChanged();
}
