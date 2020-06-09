/*
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-LicenseIdentifier: LGPL-2.0-or-later
 */

#ifndef ROLES_H
#define ROLES_H

#include <QObject>

class Roles : public QObject
{
    Q_OBJECT
    Q_ENUMS(RoleNames)
public:
    Roles(QObject *parent);
    ~Roles();
    enum RoleNames { ImageUrlRole = Qt::UserRole + 1, MimeTypeRole, Thumbnail, ItemTypeRole, FilesRole, FileCountRole, DateRole, SelectedRole, SourceIndex };
};

#endif
