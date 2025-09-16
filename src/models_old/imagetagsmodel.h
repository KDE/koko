/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef IMAGETAGSMODEL_H
#define IMAGETAGSMODEL_H

#include <QAbstractListModel>
#include <qqmlregistration.h>

#include "abstractimagemodel.h"

class QAction;

class ImageTagsModel : public AbstractImageModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString tag READ tag WRITE setTag NOTIFY tagChanged)

public:
    explicit ImageTagsModel(QObject *parent = nullptr);

    QString tag() const;
    void setTag(const QString &tag);

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = {}) const override;

Q_SIGNALS:
    void tagChanged();

private Q_SLOTS:
    void slotPopulate();

private:
    QString m_tag;
    KFileItemList m_images;
};

#endif // IMAGETAGSMODEL_H
