/*
 *  SPDX-FileCopyrightText: 2026 Jan Rathmann <jan.rathmann@gmx.de>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#pragma once

#include <QString>

class MimeTypesHelper
{
public:
    // Does filtering for e.g. images only according to config options.
    static QString relevantMimeTypes();

private:
    static QStringList extensionsFromMimeDB(QString mimeTypesPrefix);
    static const QStringList s_imageFileExtensions;
    static const QStringList s_videoFileExtensions;
};
