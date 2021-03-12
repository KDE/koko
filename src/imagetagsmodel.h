/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#ifndef IMAGETAGSMODEL_H
#define IMAGETAGSMODEL_H

#include <QAbstractListModel>

#include "openfilemodel.h"

class ImageTagsModel : public OpenFileModel
{
    Q_OBJECT
    Q_PROPERTY(QString tag READ tag WRITE setTag NOTIFY tagChanged)
    Q_PROPERTY(QStringList tags READ tags NOTIFY tagsChanged)

public:
    explicit ImageTagsModel(QObject *parent = nullptr);

    QString tag() const;
    void setTag(const QString &tag);

    QStringList tags() const;

Q_SIGNALS:
    void tagChanged();
    void tagsChanged();

private Q_SLOTS:
    void slotPopulate();

private:
    void populateTags();

    QString m_tag;
    QStringList m_tags;
};

#endif // IMAGETAGSMODEL_H
