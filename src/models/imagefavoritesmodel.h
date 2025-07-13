/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <qqmlregistration.h>

#include "abstractimagemodel.h"

class ImageFavoritesModel : public AbstractImageModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ImageFavoritesModel(QObject *parent = nullptr);
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

private:
    void slotPopulate();

    KFileItemList m_images;
};
