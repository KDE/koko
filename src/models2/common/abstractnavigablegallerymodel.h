/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <qqmlregistration.h>

#include "abstractgallerymodel.h"

/*!
 * Abstract model for a navigable gallery in Koko
 */

class AbstractNavigableGalleryModel : public AbstractGalleryModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Abstract type")

    Q_PROPERTY(QVariant path READ path WRITE setPath NOTIFY pathChanged)

public:
    ~AbstractNavigableGalleryModel() = default;

    virtual QVariant path() const
    {
        return QVariant();
    };

    virtual void setPath(const QVariant &path)
    {
        Q_UNUSED(path);
    };

    virtual QVariant pathForFileItem(const KFileItem &fileItem) const
    {
        Q_UNUSED(fileItem);
        return QVariant();
    };

Q_SIGNALS:
    void pathChanged();

protected:
    explicit AbstractNavigableGalleryModel(QObject *parent = nullptr);

private:
    QVariant m_path;
};
