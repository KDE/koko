/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#ifndef IMAGELOCATIONMODEL_H
#define IMAGELOCATIONMODEL_H

#include <QAbstractListModel>
#include <QGeoLocation>
#include <QStringList>

#include "types.h"

class ImageLocationModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Types::LocationGroup group READ group WRITE setGroup NOTIFY groupChanged)
public:
    explicit ImageLocationModel(QObject *parent = 0);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    Types::LocationGroup group() const;
    void setGroup(Types::LocationGroup group);

signals:
    void groupChanged();

private slots:
    void slotPopulate();

private:
    Types::LocationGroup m_group;
    QList<QPair<QByteArray, QString>> m_locations;
};

#endif // IMAGELOCATIONMODEL_H
