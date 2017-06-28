/*
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include "qmlplugins.h"

#include "tagmodel.h"
#include "imagelocationmodel.h"
#include "imagetimemodel.h"
#include "imagefoldermodel.h"
#include "sortmodel.h"
#include "allimagesmodel.h"
#include "fileinfo.h"
#include "imagelistmodel.h"

#include <QtQml/qqml.h>

void QmlPlugins::initializeEngine(QQmlEngine *, const char *)
{
}

void QmlPlugins::registerTypes(const char *uri)
{
    qmlRegisterType<QAbstractItemModel> ();
    qmlRegisterType<TagModel> (uri, 0, 1, "TagModel");
    qmlRegisterType<ImageLocationModel> (uri, 0, 1, "ImageLocationModel");
    qmlRegisterType<ImageTimeModel> (uri, 0, 1, "ImageTimeModel");
    qmlRegisterType<ImageFolderModel> (uri, 0, 1, "ImageFolderModel");
    qmlRegisterType<AllImagesModel> (uri, 0, 1, "AllImagesModel");
    qmlRegisterType<Jungle::SortModel> (uri, 0, 1, "SortModel");
    qmlRegisterType<FileInfo> (uri, 0, 1, "FileInfo");
    qmlRegisterType<ImageListModel> (uri, 0, 1, "ImageListModel");
}
