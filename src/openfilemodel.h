// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractListModel>

#include "types.h"

class OpenFileModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString urlToOpen READ urlToOpen NOTIFY urlToOpenChanged)

public:
    explicit OpenFileModel(const QStringList &images, QObject *parent = nullptr);
    ~OpenFileModel() = default;

    void updateOpenFiles(const QStringList &images);
    QString urlToOpen() const;

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

Q_SIGNALS:
    void updatedImages();
    void urlToOpenChanged();

protected:
    QStringList m_images;
};
