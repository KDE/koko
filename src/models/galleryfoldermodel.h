/*
 *  SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *  SPDX-FileCopyrightText: (C) 2017 by Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <qqmlregistration.h>

#include <KDirModel>

#include "abstractnavigablegallerymodel.h"

/*!
 * Model for browsing the filesystem
 */
class GalleryFolderModel : public AbstractNavigableGalleryModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GalleryFolderModel(QObject *parent = nullptr);

    QString title() const override;
    Status status() const override;

    QString titleForPath(const QVariant &path) const override;

    QVariant path() const override;
    void setPath(const QVariant &path) override;

    Q_INVOKABLE QVariant pathForIndex(const QModelIndex &index) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    bool requiresFiltering() const override
    {
        return true;
    };

Q_SIGNALS:
    void urlChanged();

private:
    Status m_status;
    KDirModel *const m_dirModel;
};
