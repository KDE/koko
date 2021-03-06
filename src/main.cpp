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

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QQuickView>

#include <iostream>

#include "filesystemtracker.h"
#include "imagestorage.h"
#include "kokoconfig.h"
#include "openfilemodel.h"
#include "processor.h"
#include "version.h"

#ifdef Q_OS_ANDROID
#include <QtAndroid>
#endif

int main(int argc, char **argv)
{
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    app.setApplicationDisplayName("Koko");
    app.setOrganizationDomain("kde.org");

    KAboutData aboutData(QStringLiteral("koko"),
                         xi18nc("@title", "<application>Koko</application>"),
                         QStringLiteral(KOKO_VERSION_STRING),
                         xi18nc("@title", "Koko is an image viewer for your image collection."),
                         KAboutLicense::LGPL,
                         xi18nc("@info:credit", "(c) 2013-2020 KDE Contributors"));

    aboutData.setOrganizationDomain(QByteArray("kde.org"));
    aboutData.setProductName(QByteArray("koko"));

    aboutData.addAuthor(xi18nc("@info:credit", "Vishesh Handa"), xi18nc("@info:credit", "Developer"), "vhanda@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Atul Sharma"), xi18nc("@info:credit", "Developer"), "atulsharma406@gmail.com");

    aboutData.addAuthor(xi18nc("@info:credit", "Marco Martin"), xi18nc("@info:credit", "Developer"), "mart@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Nicolas Fella"), xi18nc("@info:credit", "Developer"), "nicolas.fella@gmx.de");

    aboutData.addAuthor(xi18nc("@info:credit", "Carl Schwan"), xi18nc("@info:credit", "Developer"), "carl@carlschwan.eu");

    aboutData.addAuthor(xi18nc("@info:credit", "Mikel Johnson"), xi18nc("@info:credit", "Developer"), "mikel5764@gmail.com");

    KAboutData::setApplicationData(aboutData);

    KLocalizedString::setApplicationDomain("koko");

    QCommandLineParser parser;
    parser.setApplicationDescription(i18n("Image viewer"));
    parser.addOption(QCommandLineOption("reset", i18n("Reset the database")));
    parser.addPositionalArgument("image", i18n("path of image you want to open"));

    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    QApplication::setApplicationName(aboutData.componentName());
    QApplication::setApplicationDisplayName(aboutData.displayName());
    QApplication::setOrganizationDomain(aboutData.organizationDomain());
    QApplication::setApplicationVersion(aboutData.version());
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

    OpenFileModel openFileModel(directoryUrls);
    service.connect(&service,
                    &KDBusService::activateRequested,
                    &openFileModel,
                    [&openFileModel](const QStringList &arguments, const QString &workingDirectory) {
                        QUrl currentDirPath = QUrl::fromLocalFile(workingDirectory);

                        QStringList directoryUrls;
                        auto args = arguments;
                        args.removeFirst();
                        for (const auto &path : args) {
                            directoryUrls << currentDirPath.resolved(path).toString();
                        }
                        openFileModel.updateOpenFiles(directoryUrls);
                    });

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
    QObject::connect(&config, &KokoConfig::IconSizeChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::NextImageIntervalChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::LoopImagesChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::RandomizeImagesChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::ImageViewPreviewChanged, &config, &KokoConfig::save);
    QObject::connect(&config, &KokoConfig::SavedFoldersChanged, &config, &KokoConfig::save);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    qmlRegisterSingletonInstance("org.kde.koko.private", 0, 1, "OpenFileModel", &openFileModel);

    engine.rootContext()->setContextProperty("kokoProcessor", &processor);
    engine.rootContext()->setContextProperty("kokoConfig", &config);
    engine.rootContext()->setContextProperty(QStringLiteral("kokoAboutData"), QVariant::fromValue(aboutData));

    QString path;
    // we want different main files on desktop or mobile
    // very small difference as they as they are subclasses of the same thing
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    int rt = app.exec();
    trackerThread.quit();
    return rt;
}
