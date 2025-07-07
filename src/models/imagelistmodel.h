/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <qqmlregistration.h>

#include "abstractimagemodel.h"
#include "models/imagestorage.h"

/*!
 * Model for images grouped by location, time or a custom query.
 */
class ImageGroupModel : public AbstractImageModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(ImageStorage::LocationGroup locationGroup READ locationGroup WRITE setLocationGroup NOTIFY locationGroupChanged)
    Q_PROPERTY(ImageStorage::TimeGroup timeGroup READ timeGroup WRITE setTimeGroup NOTIFY timeGroupChanged)
    Q_PROPERTY(ImageStorage::QueryType queryType READ queryType WRITE setQueryType NOTIFY queryTypeChanged)
    Q_PROPERTY(QByteArray query READ query WRITE setQuery NOTIFY queryChanged)

public:
    explicit ImageGroupModel(QObject *parent = nullptr);
    ~ImageGroupModel();

    ImageStorage::LocationGroup locationGroup() const;
    void setLocationGroup(const ImageStorage::LocationGroup &group);

    ImageStorage::TimeGroup timeGroup() const;
    void setTimeGroup(const ImageStorage::TimeGroup &group);

    ImageStorage::QueryType queryType() const;
    void setQueryType(const ImageStorage::QueryType &type);

    QByteArray query() const;
    void setQuery(const QByteArray &statement);

    Q_INVOKABLE QByteArray queryForIndex(const int &index);

    void slotLocationGroupChanged();
    void slotTimeGroupChanged();
    void slotResetModel();

Q_SIGNALS:
    void imageListChanged();
    void locationGroupChanged();
    void timeGroupChanged();
    void queryTypeChanged();
    void queryChanged();

private:
    ImageStorage::LocationGroup m_locationGroup = ImageStorage::LocationGroup::NotSet;
    ImageStorage::TimeGroup m_timeGroup = ImageStorage::TimeGroup::NotSet;
    ImageStorage::QueryType m_queryType = ImageStorage::QueryType::NotSet;
    QByteArray m_query;

    QList<QPair<QByteArray, QString>> m_times;
    QList<QPair<QByteArray, QString>> m_locations;
};
