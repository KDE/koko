// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>

#pragma once

#include <AbstractKirigamiApplication>

class QActionGroup;

class PhotosApplication : public AbstractKirigamiApplication
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QList<QAction *> savedFolders READ savedFolders NOTIFY savedFoldersChanged)

public:
    explicit PhotosApplication(QObject *parent = nullptr);
    ~PhotosApplication() override;

    QList<QAction *> savedFolders() const;

Q_SIGNALS:
    void savedFoldersChanged();
    void tagsChanged();
    void filterBy(const QString &filter, const QString &query);

private:
    void setupActions() override;
    void updateSavedFolders();

    QList<QAction *> m_savedFolders;
    QActionGroup *const m_pagesGroup;
};