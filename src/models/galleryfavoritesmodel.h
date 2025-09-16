/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <qqmlregistration.h>

#include <KDirModel>

#include "abstractgallerymodel.h"

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
