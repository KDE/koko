/*
 * SPDX-FileCopyrightText: (C) 2014  Vishesh Handa <me@vhanda.in>
 *
 * SPDX-LicenseIdentifier: LGPL-2.1-or-later
 */

#include "qmlplugins.h"

#include "tagmodel.h"
#include "imagelocationmodel.h"
#include "imagetimemodel.h"
#include "imagefoldermodel.h"
#include "sortmodel.h"
#include "allimagesmodel.h"
#include "imagelistmodel.h"
#include "notificationmanager.h"
#include "types.h"
#include "roles.h"
#include "imagedocument.h"

#include <QtQml/qqml.h>

void QmlPlugins::initializeEngine(QQmlEngine *, const char *)
{
}

void QmlPlugins::registerTypes(const char *uri)
{
#if QT_VERSION < QT_VERSION_CHECK(5, 14, 0)
    qmlRegisterType<QAbstractItemModel> ();
#else
    qmlRegisterAnonymousType<QAbstractItemModel>(uri, 0);
#endif
    qmlRegisterType<TagModel> (uri, 0, 1, "TagModel");
    qmlRegisterType<ImageLocationModel> (uri, 0, 1, "ImageLocationModel");
    qmlRegisterType<ImageTimeModel> (uri, 0, 1, "ImageTimeModel");
    qmlRegisterType<ImageFolderModel> (uri, 0, 1, "ImageFolderModel");
    qmlRegisterType<AllImagesModel> (uri, 0, 1, "AllImagesModel");
    qmlRegisterType<Jungle::SortModel> (uri, 0, 1, "SortModel");
    qmlRegisterType<ImageListModel> (uri, 0, 1, "ImageListModel");
    qmlRegisterType<ImageDocument> (uri, 0, 1, "ImageDocument");
    qmlRegisterType<NotificationManager> (uri, 0, 1, "NotificationManager");
    qmlRegisterUncreatableType<Types>(uri, 0, 1, "Types", "Cannot instantiate the Types class");
    qmlRegisterUncreatableType<Roles>(uri, 0, 1, "Roles", "Cannot instantiate the Roles class");
}
