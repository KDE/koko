// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>

#pragma once

#include <QAction>
#include <QObject>
#include <qqmlregistration.h>

class QActionGroup;

class NavigationActions : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(NavigationActions)

    Q_PROPERTY(QStringList savedFolders MEMBER m_savedFolderNames NOTIFY savedFoldersChanged)
    Q_PROPERTY(QStringList tags MEMBER m_tagNames NOTIFY tagsChanged)

public:
    explicit NavigationActions(QObject *parent = nullptr);
    ~NavigationActions() override;

    enum ModelType {
        OpenModel,
        FolderModel,
        FavoritesModel,
        LocationModel,
        TimeModel,
        TagsModel,
    };
    Q_ENUM(ModelType)

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

    QStringList m_savedFolderNames;
    QStringList m_tagNames;
    QActionGroup *const m_pagesGroup;
};
