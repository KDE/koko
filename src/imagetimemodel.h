/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef IMAGETIMEMODEL_H
#define IMAGETIMEMODEL_H

#include <QAbstractListModel>
#include <QStringList>

#include "types.h"

class ImageTimeModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Types::TimeGroup group READ group WRITE setGroup NOTIFY groupChanged)
public:
    explicit ImageTimeModel(QObject *parent = 0);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    Types::TimeGroup group() const;
    void setGroup(Types::TimeGroup group);

signals:
    void groupChanged();

private slots:
    void slotPopulate();

private:
    Types::TimeGroup m_group;
    QList<QPair<QByteArray, QString>> m_times;
};

#endif
