/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <QSortFilterProxyModel>
#include <qqmlregistration.h>

/*!
 * A model which provides sorting and filtering (search) for Koko's galleries
 */
class GallerySortFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(SortMode sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(bool sortReversed READ sortReversed WRITE setSortReversed NOTIFY sortReversedChanged)
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)

public:
    explicit GallerySortFilterProxyModel(QObject *parent = nullptr);

    enum SortMode {
        Name,
        Size,
        Modified,
        Created,
        Accessed
    };
    Q_ENUM(SortMode)

    SortMode sortMode() const;
    void setSortMode(SortMode sortMode);

    bool sortReversed() const;
    void setSortReversed(bool sortReversed);

    QString filterString() const;
    void setFilterString(const QString &filterString);

Q_SIGNALS:
    void sortModeChanged();
    void sortReversedChanged();
    void filterStringChanged();

protected:
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override;

private:
    SortMode m_sortMode;
    QString m_filterString;
};
