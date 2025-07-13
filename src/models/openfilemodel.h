// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "abstractimagemodel.h"
#include <qqmlregistration.h>

class OpenFileModel : public AbstractImageModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(KFileItem itemToOpen READ itemToOpen NOTIFY itemToOpenChanged)

public:
    explicit OpenFileModel(QObject *parent = nullptr);
    ~OpenFileModel() override;

    void updateOpenFiles(const QStringList &images);
    KFileItem itemToOpen() const;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

Q_SIGNALS:
    void updatedImages();
    void itemToOpenChanged();

protected:
    KFileItemList m_images;
};
