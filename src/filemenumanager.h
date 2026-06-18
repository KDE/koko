/*
    SPDX-FileCopyrightText: 2016, 2019 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2025 Noah Davis <noahadvs@gmail.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#pragma once

#include <QObject>
#include <QQuickWindow>
#include <QUrl>
#include <qqmlregistration.h>

class QAction;

class QQuickItem;

class FileMenuManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QList<QUrl> urls READ urls WRITE setUrls NOTIFY urlsChanged FINAL)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged FINAL)
    Q_PROPERTY(QQuickWindow *window MEMBER m_window FINAL)

    Q_PROPERTY(bool canSaveAs READ canSaveAs NOTIFY canSaveAsChanged FINAL)
    Q_PROPERTY(bool canOpenFolder READ canOpenFolder NOTIFY canOpenFolderChanged FINAL)
    Q_PROPERTY(bool canOpenWith READ canOpenWith NOTIFY canOpenWithChanged FINAL)
    Q_PROPERTY(bool canCopy READ canCopy NOTIFY canCopyChanged FINAL)
    Q_PROPERTY(bool canCopyPath READ canCopyPath NOTIFY canCopyPathChanged FINAL)
    Q_PROPERTY(bool canRenameFile READ canRenameFile NOTIFY canRenameFileChanged FINAL)
    Q_PROPERTY(bool canMoveToTrash READ canMoveToTrash NOTIFY canMoveToTrashChanged FINAL)
    Q_PROPERTY(bool canDeleteFile READ canDeleteFile NOTIFY canDeleteFileChanged FINAL)
    Q_PROPERTY(bool canPrint READ canPrint NOTIFY canPrintChanged FINAL)
    Q_PROPERTY(bool canProperties READ canProperties NOTIFY canPropertiesChanged FINAL)

    QML_ELEMENT

public:
    explicit FileMenuManager(QObject *parent = nullptr);

    QList<QUrl> urls() const;
    void setUrls(const QList<QUrl> &urls);

    bool enabled() const;
    void setEnabled(const bool enabled);

    bool canSaveAs() const;
    bool canOpenFolder() const;
    bool canOpenWith() const;
    bool canCopy() const;
    bool canCopyPath() const;
    bool canRenameFile() const;
    bool canMoveToTrash() const;
    bool canDeleteFile() const;
    bool canPrint() const;
    bool canProperties() const;

Q_SIGNALS:
    void urlsChanged();
    void enabledChanged();
    void canSaveAsChanged();
    void canOpenFolderChanged();
    void canOpenWithChanged();
    void canCopyChanged();
    void canCopyPathChanged();
    void canRenameFileChanged();
    void canMoveToTrashChanged();
    void canDeleteFileChanged();
    void canPrintChanged();
    void canPropertiesChanged();

private:
    QList<QUrl> m_urls;
    bool m_enabled = false;
    QQuickWindow *m_window = nullptr;

    bool m_canSaveAs = false;
    bool m_canOpenFolder = false;
    bool m_canOpenWith = false;
    bool m_canCopy = false;
    bool m_canCopyPath = false;
    bool m_canRenameFile = false;
    bool m_canMoveToTrash = false;
    bool m_canDeleteFile = false;
    bool m_canPrint = false;
    bool m_canProperties = false;

    void updateActions();
};
