/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#pragma once

#include <QSortFilterProxyModel>
#include <qqmlregistration.h>

#include "gallerysortfilterproxymodel.h"

class MediaViewFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(GallerySortFilterProxyModel *gallerySortFilterProxyModel READ gallerySortFilterProxyModel WRITE setGallerySortFilterProxyModel NOTIFY
                   gallerySortFilterProxyModelChanged REQUIRED)

public:
    explicit MediaViewFilterModel(QObject *parent = nullptr);

    GallerySortFilterProxyModel *gallerySortFilterProxyModel() const;
    void setGallerySortFilterProxyModel(GallerySortFilterProxyModel *gallerySortFilterProxyModel);

Q_SIGNALS:
    void gallerySortFilterProxyModelChanged();

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;

private:
    GallerySortFilterProxyModel *m_gallerySortFilterProxyModel;
};
