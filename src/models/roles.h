/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <QHash>
#include <QObject>
#include <qqmlregistration.h>

class Roles : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("ENUM")

    Q_ENUMS(RoleNames)
public:
    using QObject::QObject;
    ~Roles() = default;
    enum RoleNames {
        ImageUrlRole = Qt::UserRole + 1,
        MimeTypeRole,
        Thumbnail,
        ItemTypeRole,
        FilesRole,
        FileCountRole,
        DateRole,
        SelectedRole,
        SourceIndex,
        ContentRole,
        ItemRole,
    };

    static QHash<int, QByteArray> roleNames()
    {
        return {
            {Qt::DecorationRole, "decoration"},
            {Roles::FilesRole, "files"},
            {Roles::FileCountRole, "fileCount"},
            {Roles::ImageUrlRole, "imageurl"},
            {Roles::DateRole, "date"},
            {Roles::MimeTypeRole, "mimeType"},
            {Roles::ItemTypeRole, "itemType"},
            {Roles::ContentRole, "content"},
            {Roles::SelectedRole, "selected"},
            {Roles::ItemRole, "item"},
        };
    }
};
