/*
    SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#pragma once

#include <QQuickItem>
#include <QQuickWindow>
#include <qqmlregistration.h>

class FileDropArea : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickWindow *window READ window WRITE setWindow NOTIFY windowChanged REQUIRED FINAL)
    Q_PROPERTY(QUrl rootUrl READ rootUrl WRITE setRootUrl NOTIFY rootUrlChanged REQUIRED FINAL)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged FINAL)

    Q_PROPERTY(bool containsDrag READ containsDrag NOTIFY containsDragChanged FINAL)

public:
    explicit FileDropArea(QQuickItem *parent = nullptr);

    [[nodiscard]] QQuickWindow *window() const;
    void setWindow(QQuickWindow *window);

    [[nodiscard]] QUrl rootUrl() const;
    void setRootUrl(const QUrl &url);

    [[nodiscard]] bool enabled() const;
    void setEnabled(const bool enabled);

    [[nodiscard]] bool containsDrag() const;

Q_SIGNALS:
    void windowChanged();
    void rootUrlChanged();
    void enabledChanged();
    void containsDragChanged();

    void droppedUrls(QList<QUrl> urls);

protected:
    void dragEnterEvent(QDragEnterEvent *event) override;
    void dragMoveEvent(QDragMoveEvent *event) override;
    void dragLeaveEvent(QDragLeaveEvent *event) override;
    void dropEvent(QDropEvent *event) override;

private:
    void setContainsDrag(const bool containsDrag);

    QPointer<QQuickWindow> m_window = nullptr;
    QUrl m_rootUrl;
    bool m_enabled = true;
    bool m_containsDrag = false;
};
