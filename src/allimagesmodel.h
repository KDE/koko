/*
 * SPDX-FileCopyrightText: (C) 2015 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef KOKO_ALLIMAGESMODEL_H
#define KOKO_ALLIMAGESMODEL_H

#include <QAbstractListModel>

class AllImagesModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit AllImagesModel(QObject *parent = 0);

    enum Roles { FilePathRole = Qt::UserRole + 1 };

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

private Q_SLOTS:
    void slotPopulate();

private:
    QStringList m_images;
};

#endif
