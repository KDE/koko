// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractListModel>

#include "types.h"

class OpenFileModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit OpenFileModel(const QStringList &images, QObject *parent = nullptr);
    ~OpenFileModel();

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

protected:
    QStringList m_images;
};
