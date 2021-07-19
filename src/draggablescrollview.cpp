/* SPDX-FileCopyrightText: 2017 The Qt Company Ltd.
 * SPDX-FileCopyrightText: 2020 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-3.0-only OR GPL-2.0-or-later
 */

#include "draggablescrollview.h"

#include <QGuiApplication>

#include <cmath>
#include <unordered_map>

static QRectF alignedRect(bool mirrored, Qt::Alignment alignment, const QSizeF &size, const QRectF &rectangle)
{
    Qt::Alignment halign = alignment & Qt::AlignHorizontal_Mask;
    if (mirrored && (halign & Qt::AlignRight) == Qt::AlignRight) {
        halign = Qt::AlignLeft;
    } else if (mirrored && (halign & Qt::AlignLeft) == Qt::AlignLeft) {
        halign = Qt::AlignRight;
    }
    qreal x = rectangle.x();
    qreal y = rectangle.y();
    const qreal w = size.width();
    const qreal h = size.height();
    if ((alignment & Qt::AlignVCenter) == Qt::AlignVCenter)
        y += rectangle.height() / 2 - h / 2;
    else if ((alignment & Qt::AlignBottom) == Qt::AlignBottom)
        y += rectangle.height() - h;
    if ((halign & Qt::AlignRight) == Qt::AlignRight)
        x += rectangle.width() - w;
    else if ((halign & Qt::AlignHCenter) == Qt::AlignHCenter)
        x += rectangle.width() / 2 - w / 2;
    return QRectF(x, y, w, h);
}

class DraggableScrollViewPrivate
{
    Q_DECLARE_PUBLIC(DraggableScrollView)
public:
    DraggableScrollViewPrivate(DraggableScrollView *q)
        : q_ptr(q)
    {
    }

    DraggableScrollView *const q_ptr;
    QQuickItem *flickable = nullptr;
};

DraggableScrollView::DraggableScrollView(QQuickItem *parent)
    : QQuickItem(parent)
    , d_ptr(new DraggableScrollViewPrivate(this))
{
}

void DraggableScrollView::componentComplete()
{
    QQuickItem::componentComplete();
    relayout();
}

void DraggableScrollView::geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    if (newGeometry != oldGeometry) {
        setAvailableWidth();
        setAvailableHeight();
        relayout();
    }
    QQuickItem::geometryChanged(newGeometry, oldGeometry);
}
