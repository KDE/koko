/*
 * SPDX-FileCopyrightText: (C) 2014 Vishesh Handa <vhanda@kde.org>
 * SPDX-FileCopyrightText: (C) 2017 Atul Sharma <atulsharma406@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>

#include <QDebug>
#include <QDir>
#include <QStandardPaths>
#include <QThread>

#include <KAboutData>
#include <KDBusService>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KWindowSystem>

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QQuickView>

#include <iostream>

#include "controller.h"
#include "filemenu.h"
#include "filesystemtracker.h"
#include "imagestorage.h"
#include "kokoconfig.h"
#include "openfilemodel.h"
#include "processor.h"
#include "vectorimage.h"
#include "version.h"

#ifndef Q_OS_ANDROID
#include <KConfigGroup>
#include <KSharedConfig>
#include <KWindowConfig>
#include <QQuickWindow>
#else
#include <QtAndroid>
#endif

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("koko");

    KAboutData aboutData(QStringLiteral("koko"),
                         xi18nc("@title", "<application>Koko</application>"),
                         QStringLiteral(KOKO_VERSION_STRING),
                         xi18nc("@title", "Koko is an image viewer for your image collection."),
                         KAboutLicense::LGPL,
                         xi18nc("@info:credit", "(c) 2013-2020 KDE Contributors"),
                         QString(),
                         QStringLiteral("https://apps.kde.org/koko"));

    aboutData.setOrganizationDomain(QByteArray("kde.org"));
    aboutData.setProductName(QByteArray("koko"));
    aboutData.setBugAddress("https://bugs.kde.org/describecomponents.cgi?product=koko");

    aboutData.addAuthor(xi18nc("@info:credit", "Vishesh Handa"), xi18nc("@info:credit", "Developer"), "vhanda@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Atul Sharma"), xi18nc("@info:credit", "Developer"), "atulsharma406@gmail.com");

    aboutData.addAuthor(xi18nc("@info:credit", "Marco Martin"), xi18nc("@info:credit", "Developer"), "mart@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Nicolas Fella"), xi18nc("@info:credit", "Developer"), "nicolas.fella@gmx.de");

    aboutData.addAuthor(xi18nc("@info:credit", "Carl Schwan"), xi18nc("@info:credit", "Developer"), "carl@carlschwan.eu");

    aboutData.addAuthor(xi18nc("@info:credit", "Mikel Johnson"), xi18nc("@info:credit", "Developer"), "mikel5764@gmail.com");

    KAboutData::setApplicationData(aboutData);

    QCommandLineParser parser;
    parser.addOption(QCommandLineOption("reset", i18n("Reset the database")));
    parser.addPositionalArgument("image", i18n("path of image you want to open"));

    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    QApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("koko")));

    if (parser.isSet("reset") || ImageStorage::shouldReset()) {
        ImageStorage::reset();
    }

    KDBusService service(KDBusService::Unique);

    QThread trackerThread;

    QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
    Q_ASSERT(locations.size() >= 1);
    qDebug() << locations;

    QUrl currentDirPath = QUrl::fromLocalFile(QDir::currentPath().append('/'));

    QStringList directoryUrls;
    for (const auto &path : parser.positionalArguments()) {
        directoryUrls << currentDirPath.resolved(path).toString();
    }

#ifdef Q_OS_ANDROID
    QtAndroid::requestPermissionsSync({"android.permission.WRITE_EXTERNAL_STORAGE"});
#endif

    FileSystemTracker tracker;
    tracker.setFolder(locations.first());
    tracker.moveToThread(&trackerThread);

    Koko::Processor processor;
    QObject::connect(&tracker, &FileSystemTracker::imageAdded, &processor, &Koko::Processor::addFile);
    QObject::connect(&tracker, &FileSystemTracker::imageRemoved, &processor, &Koko::Processor::removeFile);
    QObject::connect(&tracker, &FileSystemTracker::initialScanComplete, &processor, &Koko::Processor::initialScanCompleted);

    QObject::connect(&trackerThread, &QThread::started, &tracker, &FileSystemTracker::setupDb);

    trackerThread.start();
    tracker.setSubFolder(tracker.folder());

    KokoConfig config;
    // General group
    QObject::connect(&config, &KokoConfig::IconSizeChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::ImageViewPreviewChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::SavedFoldersChanged, &config, &KokoConfig::save);
    // Slideshow group
    QObject::connect(&config, &KokoConfig::NextImageIntervalChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::LoopImagesChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::RandomizeImagesChanged, &config, &KokoConfig::save);
    // KokoConfig WindowState group
    QObject::connect(&config, &KokoConfig::WidthChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::HeightChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::VisibilityChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::ControlsVisibleChanged, &config, &KokoConfig::save);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    OpenFileModel openFileModel(directoryUrls);
    QObject::connect(&service,
                     &KDBusService::activateRequested,
                     &openFileModel,
                     [&openFileModel, &parser, &engine](const QStringList &arguments, const QString &workingDirectory) {
                         QUrl currentDirPath = QUrl::fromLocalFile(workingDirectory);

                         parser.parse(arguments);

                         QStringList directoryUrls;
                         for (const auto &path : parser.positionalArguments()) {
                             directoryUrls << currentDirPath.resolved(path).toString();
                         }

                         openFileModel.updateOpenFiles(directoryUrls);

                         const auto rootObjects = engine.rootObjects();
                         for (auto obj : rootObjects) {
                             auto window = qobject_cast<QQuickWindow *>(obj);
                             if (window) {
                                 KWindowSystem::updateStartupId(window);
                                 KWindowSystem::activateWindow(window);
                                 return;
                             }
                         }
                     });

    qmlRegisterSingletonInstance("org.kde.koko.private", 0, 1, "OpenFileModel", &openFileModel);
    qmlRegisterType<VectorImage>("org.kde.koko.image", 0, 1, "VectorImage");
    qmlRegisterType<FileMenu>("org.kde.koko.private", 0, 1, "FileMenu");

    Controller controller;
    qmlRegisterSingletonInstance("org.kde.koko.private", 0, 1, "Controller", &controller);

    engine.rootContext()->setContextProperty("kokoProcessor", &processor);
    engine.rootContext()->setContextProperty("kokoConfig", &config);
    engine.rootContext()->setContextProperty(QStringLiteral("kokoAboutData"), QVariant::fromValue(aboutData));

    // we want different main files on desktop or mobile
    // very small difference as they as they are subclasses of the same thing
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

#ifndef Q_OS_ANDROID
    const auto rootObjects = engine.rootObjects();
    for (auto obj : rootObjects) {
        auto view = qobject_cast<QQuickWindow *>(obj);
        if (view) {
            KConfig dataResource(QStringLiteral("data"), KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
            KConfigGroup windowGroup(&dataResource, "Window");
            KWindowConfig::restoreWindowSize(view, windowGroup);
            KWindowConfig::restoreWindowPosition(view, windowGroup);
            break;
        }
    }
#endif

    int rt = app.exec();
    trackerThread.quit();
    return rt;
}
