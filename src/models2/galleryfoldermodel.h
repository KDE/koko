/*
 *  SPDX-FileCopyrightText: 2017 Atul Sharma <atulsharma406@gmail.com>
 *  SPDX-FileCopyrightText: 2017 Marco Martin <mart@kde.org>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <qqmlregistration.h>

#include <KDirModel>

#include "abstractgallerymodel.h"

class GalleryFolderModel : public AbstractGalleryModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)

public:
    explicit GalleryFolderModel(QObject *parent = nullptr);

    QUrl url() const;
    void setUrl(const QUrl &url);

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    bool requiresFiltering() const override
    {
        return true;
    };

Q_SIGNALS:
    void urlChanged();

private:
    KDirModel *const m_dirModel;
    KFileItemList m_items;
};
