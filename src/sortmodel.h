/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#pragma once

#include <QItemSelectionModel>
#include <QJsonArray>
#include <QSize>
#include <QSortFilterProxyModel>
#include <QVariant>
#include <kdirmodel.h>
#include <kimagecache.h>
#include <kshareddatacache.h>

class SortModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QByteArray sortRoleName READ sortRoleName WRITE setSortRoleName NOTIFY sortRoleNameChanged)
    Q_PROPERTY(bool containImages READ containImages WRITE setContainImages NOTIFY containImagesChanged)
    Q_PROPERTY(bool hasSelectedImages READ hasSelectedImages NOTIFY selectedImagesChanged)
public:
    explicit SortModel(QObject *parent = nullptr);
    virtual ~SortModel();

    QByteArray sortRoleName() const;
    void setSortRoleName(const QByteArray &name);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override;

    void setSourceModel(QAbstractItemModel *sourceModel) override;
    bool containImages();
    bool hasSelectedImages();

    Q_INVOKABLE void setSelected(int indexValue);
    Q_INVOKABLE void toggleSelected(int indexValue);
    Q_INVOKABLE void clearSelections();
    Q_INVOKABLE void selectAll();
    Q_INVOKABLE void deleteSelection();
    Q_INVOKABLE void restoreSelection();
    Q_INVOKABLE int proxyIndex(const int &indexValue);
    Q_INVOKABLE int sourceIndex(const int &indexValue);
    Q_INVOKABLE QJsonArray selectedImages();
    Q_INVOKABLE QJsonArray selectedImagesMimeTypes();
    Q_INVOKABLE int indexForUrl(const QString &url);

protected Q_SLOTS:
    void setContainImages(bool);
    void showPreview(const KFileItem &item, const QPixmap &preview);
    void previewFailed(const KFileItem &item);
    void delayedPreview();

signals:
    void sortRoleNameChanged();
    void containImagesChanged();
    void selectedImagesChanged();

private:
    QByteArray m_sortRoleName;
    QItemSelectionModel *m_selectionModel;

    QTimer *m_previewTimer;
    QHash<QUrl, QPersistentModelIndex> m_filesToPreview;
    QSize m_screenshotSize;
    QHash<QUrl, QPersistentModelIndex> m_previewJobs;
    KImageCache *m_imageCache;
    bool m_containImages;
};
