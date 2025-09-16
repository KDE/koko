/*
 *  SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <qqmlregistration.h>

#include <KDirModel>

#include "abstractgallerymodel.h"

/*!
 * Model for content marked as favorite
 */
class GalleryFavoritesModel : public AbstractGalleryModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GalleryFavoritesModel(QObject *parent = nullptr);

    QString title() const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    bool requiresFiltering() const override
    {
        return false;
    };

private:
    void populate();

    KFileItemList m_fileItems;
};
