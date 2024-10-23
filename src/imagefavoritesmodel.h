/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef IMAGEFAVORITESMODEL_H
#define IMAGEFAVORITESMODEL_H

#include <QAbstractListModel>
#include <qqmlregistration.h>

#include "openfilemodel.h"

class ImageFavoritesModel : public OpenFileModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ImageFavoritesModel(QObject *parent = nullptr);

private slots:
    void slotPopulate();
};

#endif // IMAGEFAVORITESMODEL_H
