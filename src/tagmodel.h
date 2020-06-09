/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#ifndef TAGMODEL_H
#define TAGMODEL_H

#include <QAbstractListModel>

class TagModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QStringList tags READ tags WRITE setTags NOTIFY tagsChanged)
    Q_PROPERTY(QStringList colors READ colors NOTIFY colorsChanged)

public:
    explicit TagModel(QObject *parent = 0);

    enum Roles { ColorRole = Qt::UserRole + 1 };

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

signals:
    void tagsChanged();
    void colorsChanged();

public slots:
    bool removeRows(int row, int count, const QModelIndex &parent = QModelIndex()) override;

    QStringList tags() const;
    void setTags(const QStringList &tags);
    void addTag(const QString &tag);

    /**
     * Return the colors of all the tags
     */
    QStringList colors() const;

private:
    QStringList m_tags;
};

#endif // TAGMODEL_H
