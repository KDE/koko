/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef IMAGELOCATIONMODEL_H
#define IMAGELOCATIONMODEL_H

#include "models/imagestorage.h"
#include <QAbstractListModel>
#include <QGeoLocation>
#include <QStringList>
#include <qqmlintegration.h>

class ImageLocationModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(ImageStorage::LocationGroup group READ group WRITE setGroup NOTIFY groupChanged)
public:
    explicit ImageLocationModel(QObject *parent = nullptr);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    ImageStorage::LocationGroup group() const;
    void setGroup(ImageStorage::LocationGroup group);

signals:
    void groupChanged();

private slots:
    void slotPopulate();

private:
    ImageStorage::LocationGroup m_group;
    QList<QPair<QByteArray, QString>> m_locations;
};

#endif // IMAGELOCATIONMODEL_H
