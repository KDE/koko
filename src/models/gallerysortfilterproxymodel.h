/*
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <QCollator>
#include <QSortFilterProxyModel>
#include <qqmlregistration.h>

/*!
 * A model which provides sorting and filtering (search) for Koko's galleries
 */
class GallerySortFilterProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(SortBehavior sortBehavior READ sortBehavior WRITE setSortBehavior NOTIFY sortBehaviorChanged)
    Q_PROPERTY(SortMode sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(bool sortReversed READ sortReversed WRITE setSortReversed NOTIFY sortReversedChanged)
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)

public:
    explicit GallerySortFilterProxyModel(QObject *parent = nullptr);

    enum SortBehavior {
        Natural,
        AlphabeticalCaseInsensitive,
        AlphabeticalCaseSensitive
    };
    Q_ENUM(SortBehavior)

    SortBehavior sortBehavior() const;
    void setSortBehavior(const SortBehavior sortBehavior);

    enum SortMode {
        Name,
        Size,
        Modified,
        Created,
        Accessed
    };
    Q_ENUM(SortMode)

    SortMode sortMode() const;
    void setSortMode(const SortMode sortMode);

    bool sortReversed() const;
    void setSortReversed(const bool sortReversed);

    QString filterString() const;
    void setFilterString(const QString &filterString);

Q_SIGNALS:
    void sortBehaviorChanged();
    void sortModeChanged();
    void sortReversedChanged();
    void filterStringChanged();

protected:
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override;

private:
    SortBehavior m_sortBehavior;
    SortMode m_sortMode;
    QString m_filterString;
    QCollator m_collator;

    int stringCompare(const QString &a, const QString &b, const QCollator &collator) const;
};
