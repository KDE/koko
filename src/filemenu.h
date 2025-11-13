/*
    SPDX-FileCopyrightText: 2016, 2019 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#pragma once

#include <QMenu>
#include <QUrl>

class QQuickItem;

class FileMenu : public QMenu
{
    Q_OBJECT
    Q_PROPERTY(QList<QAction *> actions READ actions NOTIFY urlChanged FINAL)
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged FINAL)
    Q_PROPERTY(bool visible READ isVisible WRITE setVisible NOTIFY visibleChanged FINAL)
public:
    static FileMenu *instance();

    QUrl url() const;
    void setUrl(const QUrl &url);

    /**
     * Same as QMenu::setVisible, but it emits visibleChanged so it can be useful in QML bindings
     */
    void setVisible(bool visible) override;

    /**
     * Popup on the specified item
     */
    Q_INVOKABLE void popup(QQuickItem *item, qreal xOffset = 0, qreal yOffset = 0);

Q_SIGNALS:
    void urlChanged();
    void visibleChanged();

protected:
    void showEvent(QShowEvent *event) override;
    void hideEvent(QHideEvent *) override;

private:
    explicit FileMenu(QWidget *parent = nullptr);
    friend class FileMenuSingleton;
    QUrl m_url;
};
