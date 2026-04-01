// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>

#pragma once

#include <QAction>
#include <QObject>
#include <qqmlregistration.h>

class QActionGroup;

class PhotosApplication : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QList<QAction *> savedFolders READ savedFolders NOTIFY savedFoldersChanged)
    Q_PROPERTY(QList<QAction *> tags READ tags NOTIFY tagsChanged)

public:
    explicit PhotosApplication(QObject *parent = nullptr);
    ~PhotosApplication() override;

    enum ModelType {
        OpenModel,
        FolderModel,
        FavoritesModel,
        LocationModel,
        TimeModel,
        TagsModel,
    };
    Q_ENUM(ModelType)

    QList<QAction *> savedFolders() const;
    QList<QAction *> tags() const;

    // FIXME: better way to do this
    Q_INVOKABLE void goHome();

Q_SIGNALS:
    void savedFoldersChanged();
    void tagsChanged();
    void navigate(const ModelType model, const QVariant path);

private:
    void setupActions();
    void updateSavedFolders();
    void updateTags();

    QList<QAction *> m_savedFolders;
    QList<QAction *> m_tags;
    QStringList m_tagNames;
    QActionGroup *const m_pagesGroup;
};
