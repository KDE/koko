/*
    SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#include <QMimeData>

#include <KIO/DropJob>
#include <KJobWindows>

#include "filedroparea.h"

FileDropArea::FileDropArea(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemAcceptsDrops, true);
}

void FileDropArea::setWindow(QQuickWindow *window)
{
    if (m_window == window) {
        return;
    }

    m_window = window;
    Q_EMIT windowChanged();
}

QQuickWindow *FileDropArea::window() const
{
    return m_window;
}

QUrl FileDropArea::rootUrl() const
{
    return m_rootUrl;
}

void FileDropArea::setRootUrl(const QUrl &url)
{
    if (m_rootUrl == url) {
        return;
    }

    m_rootUrl = url;
    Q_EMIT rootUrlChanged();
}

bool FileDropArea::enabled() const
{
    return m_enabled;
}

void FileDropArea::setEnabled(const bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }

    m_enabled = enabled;
    Q_EMIT enabledChanged();
}

bool FileDropArea::containsDrag() const
{
    return m_containsDrag;
}

void FileDropArea::dragEnterEvent(QDragEnterEvent *event)
{
    if (m_enabled && event->mimeData()->hasUrls()) {
        event->acceptProposedAction();

        setContainsDrag(true);
    }
}

void FileDropArea::dragMoveEvent(QDragMoveEvent *event)
{
    if (m_enabled && event->mimeData()->hasUrls()) {
        event->acceptProposedAction();

        setContainsDrag(true);
    }
}

void FileDropArea::dropEvent(QDropEvent *event)
{
    if (m_enabled && event->mimeData()->hasUrls()) {
        auto droppedUrls = std::make_shared<QList<QUrl>>();

        auto dropJob = KIO::drop(event, m_rootUrl);
        if (m_window) {
            KJobWindows::setWindow(dropJob, m_window);
        }
        connect(dropJob, &KIO::DropJob::itemCreated, this, [droppedUrls](const QUrl &url) {
            *droppedUrls << url;
        });
        connect(dropJob, &KJob::finished, this, [this, droppedUrls]() {
            if (!droppedUrls->isEmpty()) {
                Q_EMIT this->droppedUrls(*droppedUrls);
            }
        });

        event->acceptProposedAction();
    }

    setContainsDrag(false);
}

void FileDropArea::dragLeaveEvent(QDragLeaveEvent *event)
{
    Q_UNUSED(event)

    setContainsDrag(false);
}

void FileDropArea::setContainsDrag(const bool containsDrag)
{
    if (m_containsDrag == containsDrag) {
        return;
    }

    m_containsDrag = containsDrag;
    Q_EMIT containsDragChanged();
}
