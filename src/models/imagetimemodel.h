/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef IMAGETIMEMODEL_H
#define IMAGETIMEMODEL_H

#include "abstractimagemodel.h"
#include "imagestorage.h"
#include <QAbstractListModel>
#include <QStringList>
#include <qqmlregistration.h>

class ImageTimeModel : public AbstractImageModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(ImageStorage::TimeGroup group READ group WRITE setGroup NOTIFY groupChanged)
public:
    explicit ImageTimeModel(QObject *parent = nullptr);

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    ImageStorage::TimeGroup group() const;
    void setGroup(ImageStorage::TimeGroup group);

signals:
    void groupChanged();

private slots:
    void slotPopulate();

private:
    ImageStorage::TimeGroup m_group = ImageStorage::TimeGroup::NotSet;
    QList<ImageStorage::Collection> m_times;
};

#endif
