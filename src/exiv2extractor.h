/*
 * SPDX-FileCopyrightText: 2012-2015 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef EXIV2EXTRACTOR_H
#define EXIV2EXTRACTOR_H

#include <exiv2/exiv2.hpp>

#include <QAbstractListModel>
#include <QDateTime>
#include <QObject>
#include <QSortFilterProxyModel>
#include <QString>
#include <QUrl>

#include <KFileItem>

#include <qqmlregistration.h>

enum class GroupRow {
    GeneralGroup,
    ExifGroup,
    IptcGroup,
    XmpGroup,
};

struct MetaInfoEntry {
    GroupRow group;
    QString key;
    QString label;
    QString value;
};

class Exiv2Extractor : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QUrl filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    Q_PROPERTY(bool favorite READ favorite NOTIFY favoriteChanged)
    Q_PROPERTY(int rating READ rating WRITE setRating NOTIFY filePathChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY filePathChanged)
    Q_PROPERTY(QStringList tags READ tags WRITE setTags NOTIFY filePathChanged)

public:
    enum ExtraRoles {
        LabelRole = Qt::UserRole + 1,
        KeyRole,
        GroupRole,
        EnabledRole,
    };

    explicit Exiv2Extractor(QObject *parent = nullptr);
    ~Exiv2Extractor();

    void extract(const QString &filePath);
    Q_INVOKABLE void updateFavorite(const QString &filePath);
    Q_INVOKABLE void toggleFavorite(const QString &filePath);

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    QUrl filePath() const;
    void setFilePath(const QUrl &filePath)
    {
        extract(filePath.toLocalFile());
    }

    double gpsLatitude() const
    {
        return m_latitude;
    }
    double gpsLongitude() const
    {
        return m_longitude;
    }

    QDateTime dateTime() const
    {
        return m_dateTime;
    }

    bool favorite() const
    {
        return m_favorite;
    }

    int rating() const
    {
        return m_rating;
    }

    QString description() const
    {
        return m_description;
    }

    QStringList tags() const
    {
        return m_tags;
    }

    void setRating(const int &rating);
    void setDescription(const QString &description);
    void setTags(const QStringList &tags);

    bool error() const;

Q_SIGNALS:
    void filePathChanged();
    void favoriteChanged();

private:
    double fetchGpsDouble(const Exiv2::ExifData &data, const char *name);
    QByteArray fetchByteArray(const Exiv2::ExifData &data, const char *name);

    QString m_filePath;
    KFileItem m_item;
    double m_latitude;
    double m_longitude;
    QDateTime m_dateTime;
    int m_height;
    int m_width;
    bool m_favorite;
    int m_rating;
    QString m_description;
    QStringList m_tags;

    bool m_error;

    void initGeneralGroup(const KFileItem &item);
    void initExiv2Image(const Exiv2::Image *image);

    QList<MetaInfoEntry> m_entries;
};

class ExivFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    ExivFilterModel();

    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override
    {
        const QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
        const auto enabled =
            sourceModel()->data(index, Exiv2Extractor::EnabledRole).toBool() && !sourceModel()->data(index, Qt::DisplayRole).toString().isEmpty();
        return enabled;
    }
};

#endif // EXIV2EXTRACTOR_H
