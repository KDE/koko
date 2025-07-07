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

private slots:
    void slotPopulate();
};
