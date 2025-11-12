/*
    SPDX-FileCopyrightText: 2016, 2019 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#pragma once

#include <QMenu>

class QQuickItem;

class FileMenu : public QMenu
{
    Q_OBJECT
    Q_PROPERTY(bool visible READ isVisible WRITE setVisible NOTIFY visibleChanged FINAL)
public:
    FileMenu(QWidget *parent = nullptr);

    /**
     * Same as QMenu::setVisible, but it emits visibleChanged so it can be useful in QML bindings
     */
    void setVisible(bool visible) override;

    /**
     * Popup on the specified item
     */
    Q_INVOKABLE void popup(QQuickItem *item);

Q_SIGNALS:
    void visibleChanged();

protected:
    void showEvent(QShowEvent *event) override;
    void hideEvent(QHideEvent *) override;
};
