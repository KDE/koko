/*
 * SPDX-FileCopyrightText: (C) 2014  Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "qmlplugins.h"

#include "dirmodelutils.h"
#include "displaycolorspace.h"
#include "exiv2extractor.h"
#include "fileinfo.h"
#include "imagefavoritesmodel.h"
#include "imagefoldermodel.h"
#include "imagelistmodel.h"
#include "imagelocationmodel.h"
#include "imagetagsmodel.h"
#include "imagetimemodel.h"
#include "notificationmanager.h"
#include "roles.h"
#include "sortmodel.h"
#include "types.h"

#include <QtQml/qqml.h>

void QmlPlugins::initializeEngine(QQmlEngine *, const char *)
{
}

void QmlPlugins::registerTypes(const char *uri)
{
#if QT_VERSION < QT_VERSION_CHECK(5, 14, 0)
    qmlRegisterType<QAbstractItemModel>();
#else
    qmlRegisterAnonymousType<QAbstractItemModel>(uri, 0);
#endif
    qmlRegisterType<ImageLocationModel>(uri, 0, 1, "ImageLocationModel");
    qmlRegisterType<ImageTimeModel>(uri, 0, 1, "ImageTimeModel");
    qmlRegisterType<ImageFavoritesModel>(uri, 0, 1, "ImageFavoritesModel");
    qmlRegisterType<ImageTagsModel>(uri, 0, 1, "ImageTagsModel");
    qmlRegisterType<ImageFolderModel>(uri, 0, 1, "ImageFolderModel");
    qmlRegisterType<Exiv2Extractor>(uri, 0, 1, "Exiv2Extractor");
    qmlRegisterType<SortModel>(uri, 0, 1, "SortModel");
    qmlRegisterType<ImageListModel>(uri, 0, 1, "ImageListModel");
    qmlRegisterType<NotificationManager>(uri, 0, 1, "NotificationManager");
    qmlRegisterUncreatableType<Types>(uri, 0, 1, "Types", "Cannot instantiate the Types class");
    qmlRegisterUncreatableType<Roles>(uri, 0, 1, "Roles", "Cannot instantiate the Roles class");
    qmlRegisterSingletonType<DirModelUtils>(uri, 0, 1, "DirModelUtils", [=](QQmlEngine *, QJSEngine *) {
        return new DirModelUtils;
    });
    qmlRegisterType<FileInfo>(uri, 0, 1, "FileInfo");
    qmlRegisterSingletonType<DisplayColorSpace>(uri, 0, 1, "DisplayColorSpace", [](QQmlEngine *, QJSEngine *) {
        return new DisplayColorSpace{};
    });
}
