/* SPDX-FileCopyrightText: 2026 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "placeaction.h"

PlaceAction::PlaceAction(const QString &id, PhotosApplication::ModelType modelType, const QVariant &path, QObject *parent)
    : QAction(parent)
    , m_modelType(modelType)
    , m_path(path)
{
    setObjectName(id);
}

PhotosApplication::ModelType PlaceAction::modelType() const
{
    return m_modelType;
}

QVariant PlaceAction::path() const
{
    return m_path;
}
