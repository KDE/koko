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

#include <KLocalizedContext>
#include <KLocalizedString>
#include <KAboutData>

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QQuickView>

#include <iostream>

#include "filesystemtracker.h"
#include "imagestorage.h"
#include "kokoconfig.h"
#include "processor.h"

#ifdef Q_OS_ANDROID
#include <QtAndroid>
#endif

static const char description[] = I18N_NOOP("Koko is a image viewer for your image collection.");

int main(int argc, char **argv)
{
    KLocalizedString::setApplicationDomain("koko");

    KAboutData aboutData(QStringLiteral("koko"),
                         xi18nc("@title", "<application>Koko</application>"),
                         QStringLiteral("0.1-dev"),
                         xi18nc("@title", "Koko is a image viewer for your image collection."),
                         KAboutLicense::LGPL,
                         xi18nc("@info:credit", "(c) 2013-2020 KDE Contributors"));

    aboutData.setOrganizationDomain(QByteArray("kde.org"));
    aboutData.setProductName(QByteArray("koko"));

    aboutData.addAuthor(xi18nc("@info:credit", "Vishesh Handa"),
            xi18nc("@info:credit","Developer"),
            "vhanda@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Atul Sharma"),
            xi18nc("@info:credit", "Developer"),
            "atulsharma406@gmail.com");

    aboutData.addAuthor(xi18nc("@info:credit", "Marco Martin"),
            xi18nc("@info:credit", "Developer"),
            "mart@kde.org");

    aboutData.addAuthor(xi18nc("@info:credit", "Nicolas Fella"),
            xi18nc("@info:credit", "Developer"),
            "nicolas.fella@gmx.de");

    aboutData.addAuthor(xi18nc("@info:credit", "Carl Schwan"),
            xi18nc("@info:credit", "Developer"),
            "carl@carlschwan.eu");

    KAboutData::setApplicationData(aboutData);

    QApplication app(argc, argv);
    app.setApplicationDisplayName("Koko");
    app.setOrganizationDomain("kde.org");

    QCommandLineParser parser;
    parser.addOption(QCommandLineOption("reset", i18n("Reset the database")));
    parser.addPositionalArgument("image", i18n("path of image you want to open"));
    parser.addHelpOption();
    parser.addVersionOption();

    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    QApplication::setApplicationName(aboutData.componentName());
    QApplication::setApplicationDisplayName(aboutData.displayName());
    QApplication::setOrganizationDomain(aboutData.organizationDomain());
    QApplication::setApplicationVersion(aboutData.version());
    QApplication::setWindowIcon(QIcon::fromTheme(QStringLiteral("koko")));

    if (parser.positionalArguments().size() > 1) {
        parser.showHelp(1);
    }

    if (parser.isSet("reset")) {
        ImageStorage::reset();
    }

    QThread trackerThread;

    QStringList locations = QStandardPaths::standardLocations(QStandardPaths::PicturesLocation);
    Q_ASSERT(locations.size() >= 1);
    qDebug() << locations;

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

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    engine.rootContext()->setContextProperty("kokoProcessor", &processor);
    engine.rootContext()->setContextProperty("kokoConfig", &config);
    engine.rootContext()->setContextProperty(QStringLiteral("kokoAboutData"), QVariant::fromValue(aboutData));

    QString path;
    // we want different main files on desktop or mobile
    // very small difference as they as they are subclasses of the same thing
    if (qEnvironmentVariableIsSet("QT_QUICK_CONTROLS_MOBILE") && (QString::fromLatin1(qgetenv("QT_QUICK_CONTROLS_MOBILE")) == QStringLiteral("1") || QString::fromLatin1(qgetenv("QT_QUICK_CONTROLS_MOBILE")) == QStringLiteral("true"))) {
        engine.load(QUrl(QStringLiteral("qrc:/qml/mobileMain.qml")));
    } else {
        engine.load(QUrl(QStringLiteral("qrc:/qml/desktopMain.qml")));
    }

    int rt = app.exec();
    trackerThread.quit();
    return rt;
}
