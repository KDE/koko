/*
 *  SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <QMimeDatabase>

#include "kokoconfig.h"
#include "kokodirlister.h"
#include "mimetypeshelper.h"

KokoDirLister::KokoDirLister(QObject *parent)
    : QObject(parent)
{
    m_dirLister.setNameFilter(MimeTypesHelper::relevantMimeTypes());

    m_bufferTimer.setSingleShot(true);
    m_bufferTimer.setInterval(200);

    connect(&m_dirLister, &KCoreDirLister::newItems, this, [this](const KFileItemList &items) {
        m_bufferedFileItems.append(items);

        if (!m_bufferTimer.isActive()) {
            m_bufferTimer.start();
        }
    });

    connect(&m_dirLister, &KCoreDirLister::itemsDeleted, this, [this](const KFileItemList &items) {
        KFileItemList deletedItems;

        for (const KFileItem &item : items) {
            if (!m_bufferedFileItems.removeOne(item)) {
                deletedItems.append(item);
            }
        }

        if (!deletedItems.isEmpty()) {
            Q_EMIT itemsDeleted(deletedItems);
        }
    });

    connect(&m_dirLister, &KCoreDirLister::completed, this, [this]() {
        flushBufferedFileItems();
        Q_EMIT completed();
    });

    connect(&m_bufferTimer, &QTimer::timeout, this, [this]() {
        flushBufferedFileItems();
    });

    Config *config = Config::self();
    connect(config, &Config::MediaTypesChanged, this, [this]() {
        m_dirLister.setNameFilter(MimeTypesHelper::relevantMimeTypes());
        m_dirLister.emitChanges();
    });
}

bool KokoDirLister::fileItemMatchesFilter(const KFileItem &fileItem)
{
    return MimeTypesHelper::relevantMimeTypes().contains(QStringLiteral("*.") + fileItem.suffix(), Qt::CaseInsensitive);
};

QUrl KokoDirLister::url() const
{
    return m_dirLister.url();
}

void KokoDirLister::setUrl(const QUrl &url)
{
    m_bufferTimer.stop();
    m_bufferedFileItems.clear();
    m_dirLister.openUrl(url);
}

void KokoDirLister::stop()
{
    m_dirLister.stop();
}

void KokoDirLister::flushBufferedFileItems()
{
    m_bufferTimer.stop();

    if (!m_bufferedFileItems.isEmpty()) {
        Q_EMIT itemsAdded(m_bufferedFileItems);
        m_bufferedFileItems.clear();
    }
}
