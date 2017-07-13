/*
 * Copyright (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 * Copyright (C) 2014  Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>

#include <QStandardPaths>
#include <QDebug>
#include <QThread>
#include <QDir>

#include <KDBusService>
#include <KLocalizedString>
#include <KLocalizedContext>

#include <QApplication>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QQuickView>

#include <iostream>

#include "filesystemtracker.h"
#include "processor.h"
#include "kokoconfig.h"
#include "imagestorage.h"

int main(int argc, char** argv)
{
    QApplication app(argc, argv);
    app.setApplicationDisplayName("Koko");
    app.setOrganizationDomain("kde.org");

    KDBusService service(KDBusService::Unique);

    QCommandLineParser parser;
    parser.addOption(QCommandLineOption("reset", i18n("Reset the database")));
    parser.addPositionalArgument( "image", i18n("path of image you want to open"));
    parser.addHelpOption();
    parser.process(app);

    if (parser.positionalArguments().size() > 1) {
        parser.showHelp(1);
    }
    
    if (parser.isSet("reset")) {
        KokoConfig config;
        config.reset();

        ImageStorage::reset();
    }

    QThread trackerThread;

    QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
    Q_ASSERT(locations.size() >= 1);
    qDebug() << locations;

    QUrl currentDirPath = QUrl::fromLocalFile(QDir::currentPath().append('/'));
    QUrl resolvedImagePath = parser.positionalArguments().isEmpty() 
                                                       ? QUrl::fromLocalFile(locations.first().append('/')) 
                                                       : currentDirPath.resolved( parser.positionalArguments().first());
    
    if( !resolvedImagePath.isLocalFile()) {
        resolvedImagePath = QUrl::fromLocalFile(locations.first().append('/')) ;
    }
    
    FileSystemTracker tracker;
    tracker.setFolder(locations.first());
    tracker.moveToThread(&trackerThread);

    Koko::Processor processor;
    QObject::connect(&tracker, &FileSystemTracker::imageAdded, &processor, &Koko::Processor::addFile);
    QObject::connect(&tracker, &FileSystemTracker::imageRemoved, &processor, &Koko::Processor::removeFile);
    QObject::connect(&tracker, &FileSystemTracker::initialScanComplete, &processor, &Koko::Processor::initialScanCompleted);

    trackerThread.start();
    tracker.setSubFolder(tracker.folder());

    KokoConfig config;

    QQmlEngine engine;
    QQmlContext* objectContext = engine.rootContext();
    objectContext->setContextProperty("kokoProcessor", &processor);
    objectContext->setContextProperty("kokoConfig", &config);
    objectContext->setContextProperty("imagePathArgument", resolvedImagePath.toString());

    QString path;
    //we want different main files on desktop or mobile
    //very small difference as they as they are subclasses of the same thing
    if (qEnvironmentVariableIsSet("QT_QUICK_CONTROLS_MOBILE") &&
        (QString::fromLatin1(qgetenv("QT_QUICK_CONTROLS_MOBILE")) == QStringLiteral("1") ||
         QString::fromLatin1(qgetenv("QT_QUICK_CONTROLS_MOBILE")) == QStringLiteral("true"))) {
        path = QStandardPaths::locate(QStandardPaths::DataLocation, "ui/mobileMain.qml");
    } else {
        path = QStandardPaths::locate(QStandardPaths::DataLocation, "ui/desktopMain.qml");
    }
    
    QQuickView* view = new QQuickView( &engine, new QWindow());
    view->engine()->rootContext()->setContextObject(new KLocalizedContext(view));    
    
    QQmlComponent component(&engine, path);
    if (component.isError()) {
        std::cout << component.errorString().toUtf8().constData() << std::endl;
        Q_ASSERT(0);
    }
    Q_ASSERT(component.status() == QQmlComponent::Ready);

    QObject* obj = component.create(objectContext);
    Q_ASSERT(obj);

    int rt = app.exec();
    trackerThread.quit();
    return rt;
}
