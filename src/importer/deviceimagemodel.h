// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#pragma once

#include <KFileItem>
#include <QAbstractListModel>
#include <qqmlregistration.h>

class KCoreDirLister;

class DeviceImageModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)

public:
    explicit DeviceImageModel(QObject *parent = nullptr);
    ~DeviceImageModel() override;

    [[nodiscard]] QUrl url() const;
    void setUrl(const QUrl &);

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &) const override;
    QVariant data(const QModelIndex &, int role = Qt::DisplayRole) const override;

Q_SIGNALS:
    void completed();
    void urlChanged();

private Q_SLOTS:
    void slotItemsAdded(const QUrl &dirUrl, const KFileItemList &);
    void slotItemsDeleted(const KFileItemList &);
    void slotDirCleared(const QUrl &);
    void slotCleared();

private:
    void removeAt(int row);
    void addItem(const KFileItem &item);
    void clear();

    KCoreDirLister *const m_dirLister;
    KFileItemList m_list;
    QHash<QUrl, int> m_rowForUrl;
};