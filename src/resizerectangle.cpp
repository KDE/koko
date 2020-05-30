/*
 * SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "resizerectangle.h"

#include <cmath>

ResizeRectangle::ResizeRectangle(QQuickItem *parent)
    : QQuickItem(parent)
{
    setAcceptedMouseButtons(Qt::LeftButton);
}


void ResizeRectangle::mouseReleaseEvent(QMouseEvent *event)
{
    event->accept();
}

void ResizeRectangle::mousePressEvent(QMouseEvent *event)
{
    m_mouseDownPosition = event->windowPos();
    m_mouseDownGeometry = QPointF(x(), y());
    event->accept();
}

void ResizeRectangle::mouseMoveEvent(QMouseEvent *event)
{
    const QPointF difference = m_mouseDownPosition - event->windowPos();
    const qreal x = m_mouseDownGeometry.x() - difference.x();
    const qreal y = m_mouseDownGeometry.y() - difference.y();
    setX(x);
    setY(y);
}

void ResizeRectangle::mouseDoubleClickEvent(QMouseEvent *event)
{
    Q_EMIT acceptSize();
    event->accept();
}

#include "moc_resizerectangle.cpp"
