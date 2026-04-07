/* SPDX-FileCopyrightText: 2026 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include "navigationactions.h"
#include <QAction>

class PlaceAction : public QAction
{
    Q_OBJECT
    Q_PROPERTY(NavigationActions::ModelType modelType READ modelType CONSTANT)
    Q_PROPERTY(QVariant path READ path CONSTANT)
public:
    explicit PlaceAction(const QString &id, NavigationActions::ModelType modelType, const QVariant &path, QObject *parent = nullptr);
    NavigationActions::ModelType modelType() const;
    QVariant path() const;
private:
    const NavigationActions::ModelType m_modelType{};
    const QVariant m_path{};
};
