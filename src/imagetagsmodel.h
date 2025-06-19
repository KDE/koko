/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef IMAGETAGSMODEL_H
#define IMAGETAGSMODEL_H

#include <QAbstractListModel>
#include <qqmlregistration.h>

#include "openfilemodel.h"

class QAction;

class ImageTagsModel : public OpenFileModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString tag READ tag WRITE setTag NOTIFY tagChanged)

public:
    explicit ImageTagsModel(QObject *parent = nullptr);

    QString tag() const;
    void setTag(const QString &tag);

Q_SIGNALS:
    void tagChanged();

private Q_SLOTS:
    void slotPopulate();

private:
    QString m_tag;
};

#endif // IMAGETAGSMODEL_H
