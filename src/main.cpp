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

#include <QQmlApplicationEngine>
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
                                                       ? QUrl() 
                                                       : currentDirPath.resolved( parser.positionalArguments().first());
    
    if( !resolvedImagePath.isLocalFile()) {
        resolvedImagePath = QUrl() ;
    }
    
    QStringList directoryUrls;
    if (!resolvedImagePath.isEmpty()) {
        QString tempImagePath = resolvedImagePath.toString();
        directoryUrls << tempImagePath;
        
        if (resolvedImagePath.toString().startsWith(QUrl::fromLocalFile(locations.first()).toString())) {
            while (tempImagePath != QUrl::fromLocalFile(locations.first()).toString()) {
                tempImagePath = tempImagePath.left( tempImagePath.lastIndexOf('/'));
                directoryUrls.prepend(tempImagePath);
            }
        } else {
            directoryUrls.prepend(tempImagePath.left( tempImagePath.lastIndexOf('/')));
        }
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

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    engine.rootContext()->setContextProperty("kokoProcessor", &processor);
    engine.rootContext()->setContextProperty("kokoConfig", &config);
    engine.rootContext()->setContextProperty("imagePathArgument", directoryUrls);

    QString path;
    //we want different main files on desktop or mobile
    //very small difference as they as they are subclasses of the same thing
    if (qEnvironmentVariableIsSet("QT_QUICK_CONTROLS_MOBILE") &&
        (QString::fromLatin1(qgetenv("QT_QUICK_CONTROLS_MOBILE")) == QStringLiteral("1") ||
         QString::fromLatin1(qgetenv("QT_QUICK_CONTROLS_MOBILE")) == QStringLiteral("true"))) {
        engine.load(QUrl(QStringLiteral("qrc:/qml/mobileMain.qml")));
    } else {
        engine.load(QUrl(QStringLiteral("qrc:/qml/desktopMain.qml")));
    }

    int rt = app.exec();
    return rt;
}
