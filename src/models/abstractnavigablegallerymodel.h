/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <qqmlregistration.h>

#include "abstractgallerymodel.h"

/*!
 * Abstract model for a gallery in Koko supporting navigation via a path
 */
class AbstractNavigableGalleryModel : public AbstractGalleryModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Abstract type")

    Q_PROPERTY(QVariant path READ path WRITE setPath NOTIFY pathChanged)

public:
    ~AbstractNavigableGalleryModel() = default;

    Q_INVOKABLE virtual QString titleForPath(const QVariant &path) const = 0;

    virtual QVariant path() const = 0;

    virtual void setPath(const QVariant &path) = 0;

    Q_INVOKABLE virtual QVariant pathForIndex(const QModelIndex &index) const = 0;

Q_SIGNALS:
    void pathChanged();

protected:
    explicit AbstractNavigableGalleryModel(QObject *parent = nullptr);
};
