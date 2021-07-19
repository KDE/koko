/* SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#ifndef DRAGGABLESCROLLVIEW_H
#define DRAGGABLESCROLLVIEW_H

#include <QQuickItem>
#include <memory>

class DraggableScrollViewPrivate;

class DraggableScrollView : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QQuickItem *flickable READ flickable WRITE setFlickable NOTIFY flickableChanged FINAL)
    QML_NAMED_ELEMENT(DraggableScrollView)

public:
    explicit DraggableScrollView(QQuickItem *parent = nullptr);

    QQuickItem *flickable() const;
    void setFlickable(QQuickItem *flickable);

Q_SIGNALS:
    void flickableChanged();

protected:
    void componentComplete() override;
    void geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    const std::unique_ptr<DraggableScrollViewPrivate> d_ptr;
    Q_DECLARE_PRIVATE(DraggableScrollView)
    Q_DISABLE_COPY(DraggableScrollView)
};

QML_DECLARE_TYPE(DraggableScrollView)

#endif
