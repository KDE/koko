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
#include <KLocalizedQmlContext>
#include <KLocalizedString>
#include <KWindowSystem>

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QQuickStyle>
#include <QQuickView>

#include <iostream>

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

using namespace Qt::StringLiterals;

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
#ifndef Q_OS_ANDROID
    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }
#endif
    KLocalizedString::setApplicationDomain("koko");

    KAboutData aboutData(QStringLiteral("koko"),
                         xi18nc("@title", "<application>Photos</application>"),
                         QStringLiteral(KOKO_VERSION_STRING),
                         xi18nc("@title", "Photos is an image viewer for your image collection."),
                         KAboutLicense::LGPL,
                         xi18nc("@info:credit", "(c) 2013-%1 KDE Contributors", QString::number(QDate::currentDate().year())),
                         QString(),
                         QStringLiteral("https://apps.kde.org/koko"));

    aboutData.setOrganizationDomain(QByteArray("kde.org"));
    aboutData.setProductName(QByteArray("koko"));
    aboutData.setBugAddress("https://bugs.kde.org/describecomponents.cgi?product=koko");

    aboutData.addAuthor(xi18nc("@info:credit", "Vishesh Handa"), xi18nc("@info:credit", "Developer"), "vhanda@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Atul Sharma"), xi18nc("@info:credit", "Developer"), "atulsharma406@gmail.com");

    aboutData.addAuthor(xi18nc("@info:credit", "Marco Martin"), xi18nc("@info:credit", "Developer"), "mart@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Nicolas Fella"), xi18nc("@info:credit", "Developer"), "nicolas.fella@gmx.de");

    aboutData.addAuthor(xi18nc("@info:credit", "Carl Schwan"),
                        xi18nc("@info:credit", "Developer"),
                        "carl@carlschwan.eu",
                        QStringLiteral("https://carlschwan.eu"),
                        QUrl(QStringLiteral("https://carlschwan.eu/avatar.png")));

    aboutData.addAuthor(xi18nc("@info:credit", "Mikel Johnson"), xi18nc("@info:credit", "Developer"), "mikel5764@gmail.com");

    KAboutData::setApplicationData(aboutData);

    QCommandLineParser parser;
    parser.addOption(QCommandLineOption("reset", i18n("Reset the database")));
    parser.addPositionalArgument("image", i18n("path of image you want to open"));

    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    QApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("org.kde.koko")));

    if (parser.isSet("reset") || ImageStorage::shouldReset()) {
        ImageStorage::reset();
    }

    KDBusService service(KDBusService::Unique);

    QThread trackerThread;

    const QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
    Q_ASSERT(locations.size() >= 1);
    qDebug() << locations;

    const QUrl currentDirPath = QUrl::fromLocalFile(QDir::currentPath().append('/'));

    QStringList directoryUrls;
    for (const auto &path : parser.positionalArguments()) {
        directoryUrls << currentDirPath.resolved(path).toString();
    }

#ifdef Q_OS_ANDROID
    QtAndroid::requestPermissionsSync({"android.permission.WRITE_EXTERNAL_STORAGE"});
#endif

    FileSystemTracker tracker;
    tracker.moveToThread(&trackerThread);

    Koko::Processor processor;
    QObject::connect(&tracker, &FileSystemTracker::imageAdded, &processor, &Koko::Processor::addFile);
    QObject::connect(&tracker, &FileSystemTracker::imageRemoved, &processor, &Koko::Processor::removeFile);
    QObject::connect(&tracker, &FileSystemTracker::initialScanComplete, &processor, &Koko::Processor::initialScanCompleted);

    QObject::connect(&trackerThread, &QThread::started, &tracker, &FileSystemTracker::setupDb);

    trackerThread.start();

    const QString imageDirLocation = locations.first();
    QMetaObject::invokeMethod(&tracker, [&tracker, imageDirLocation]() {
        tracker.setFolder(imageDirLocation);
        tracker.setSubFolder(tracker.folder());
    });

    QQmlApplicationEngine engine;
    KLocalization::setupLocalizedContext(&engine);

    const auto openFileModel = engine.singletonInstance<OpenFileModel *>("org.kde.koko", "OpenFileModel");
    openFileModel->updateOpenFiles(directoryUrls);

    QObject::connect(&service,
                     &KDBusService::activateRequested,
                     openFileModel,
                     [openFileModel, &parser, &engine](const QStringList &arguments, const QString &workingDirectory) {
                         QUrl currentDirPath = QUrl::fromLocalFile(workingDirectory);

                         parser.parse(arguments);

                         QStringList directoryUrls;
                         for (const auto &path : parser.positionalArguments()) {
                             directoryUrls << currentDirPath.resolved(path).toString();
                         }

                         openFileModel->updateOpenFiles(directoryUrls);

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

    qmlRegisterType<VectorImage>("org.kde.koko.image", 1, 0, "VectorImage");
    qmlRegisterType<FileMenu>("org.kde.koko.private", 1, 0, "FileMenu");

    engine.rootContext()->setContextProperty("kokoProcessor", &processor);

    // we want different main files on desktop or mobile
    // very small difference as they as they are subclasses of the same thing
    engine.loadFromModule(u"org.kde.koko"_s, u"Main"_s);

    int rt = app.exec();
    trackerThread.quit();
    trackerThread.wait();
    return rt;
}
