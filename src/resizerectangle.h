/*
 * SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#pragma once

#include <QQuickItem>

class ResizeRectangle : public QQuickItem
{
    Q_OBJECT
    
public:
    ResizeRectangle(QQuickItem *parent = nullptr);
    ~ResizeRectangle() = default;
    
protected:
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mousePressEvent(QMouseEvent * event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseDoubleClickEvent(QMouseEvent *event) override;
    
Q_SIGNALS:
    /// Double click event signal
    void acceptSize();
    
private:
    QPointF m_mouseDownPosition;
    QPointF m_mouseDownGeometry;
};
