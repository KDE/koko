/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <qqmlregistration.h>

#include "imagestorage.h"

#include "abstractnavigablegallerymodel.h"

/*!
 * Model for browsing content by time
 */
class GalleryTimeModel : public AbstractNavigableGalleryModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GalleryTimeModel(QObject *parent = nullptr);

    QString title() const override;

    QString titleForPath(const QVariant &path) const override;

    QVariant path() const override;
    void setPath(const QVariant &path) override;

    Q_INVOKABLE QVariant pathForIndex(const QModelIndex &index) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    bool requiresFiltering() const override
    {
        return false;
    };

Q_SIGNALS:
    void urlChanged();

private:
    void populate(const QStringList &path);

    enum Mode {
        None,
        ParentCollectionMode,
        CollectionMode,
        FileItemMode
    };

    Mode m_mode;
    QStringList m_path;
    QList<ImageStorage::Collection> m_collections;
    KFileItemList m_fileItems;
};
