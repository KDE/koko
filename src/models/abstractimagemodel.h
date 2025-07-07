// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <KFileItem>
#include <QAbstractListModel>

#include <qqmlregistration.h>

/*!
 * Absteact model for images, this is based on a list of KFileItem
 */
class AbstractImageModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Abstract type")

public:
    ~AbstractImageModel() = default;

    KFileItemList images() const;
    void setImages(const KFileItemList &images);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

protected:
    explicit AbstractImageModel(QObject *parent = nullptr);

protected:
    KFileItemList m_images;
};
