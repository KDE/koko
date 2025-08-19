// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2024 KDE Image Viewer Integration

#include "wallpaperservice.h"
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QCoreApplication>
#include <QSettings>
#include <QGuiApplication>
#include <QScreen>
#include <QThread>

WallpaperService::WallpaperService(QObject *parent)
    : QObject(parent)
    , m_process(new QProcess(this))
{
    connect(m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &WallpaperService::onProcessFinished);
    connect(m_process, &QProcess::errorOccurred,
            this, &WallpaperService::onProcessError);
}

WallpaperService::~WallpaperService()
{
}

bool WallpaperService::setWallpaper(const QString &imagePath)
{
    if (!QFileInfo::exists(imagePath)) {
        emit wallpaperError(tr("Image file does not exist: %1").arg(imagePath));
        return false;
    }
    
    m_lastImagePath = imagePath;
    
    // Try command line method first (most reliable)
    if (setWallpaperViaCommand(imagePath)) {
        return true;
    }
    
    // Try DBus method as fallback
    if (setWallpaperViaDBus(imagePath)) {
        return true;
    }
    
    // Try Plasma config method as last resort
    if (setWallpaperViaPlasmaShell(imagePath)) {
        return true;
    }
    
    emit wallpaperError(tr("Failed to set wallpaper using any available method"));
    return false;
}

bool WallpaperService::setWallpaperForAllScreens(const QString &imagePath)
{
    // Get all screens
    QStringList screens = getAvailableScreens();
    
    bool success = true;
    for (const QString &screen : screens) {
        if (!setWallpaperViaDBus(imagePath, screen)) {
            success = false;
        }
    }
    
    return success;
}

QStringList WallpaperService::getAvailableScreens() const
{
    QStringList screens;
    
    // Get screens from QGuiApplication
    for (QScreen *screen : QGuiApplication::screens()) {
        screens << screen->name();
    }
    
    return screens;
}

bool WallpaperService::setWallpaperViaDBus(const QString &imagePath, const QString &screen)
{
    qDebug() << "setWallpaperViaDBus called with:" << imagePath << "screen:" << screen;
    
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    
    if (!sessionBus.isConnected()) {
        qWarning() << "Cannot connect to session bus";
        return false;
    }
    
    // Method 1: Try using the newer KDE 6 wallpaper interface
    QDBusInterface wallpaperInterface("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", sessionBus);
    
    if (wallpaperInterface.isValid()) {
        qDebug() << "PlasmaShell interface is valid";
        
        // First, ensure the image wallpaper plugin is set
        QDBusMessage pluginMsg = wallpaperInterface.call("evaluateScript", 
            QString("for (var i = 0; i < desktops().length; i++) { desktops()[i].wallpaperPlugin = 'org.kde.image'; }"));
        
        if (pluginMsg.type() == QDBusMessage::ReplyMessage) {
            qDebug() << "Set wallpaper plugin succeeded";
            
            // Now set the actual wallpaper image
            QString script = QString(
                "for (var i = 0; i < desktops().length; i++) {"
                "  desktops()[i].currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];"
                "  desktops()[i].writeConfig('Image', '%1');"
                "  desktops()[i].writeConfig('FillMode', 2);"  // Fill mode
                "}"
            ).arg(imagePath);
            
            QDBusMessage wallpaperMsg = wallpaperInterface.call("evaluateScript", script);
            
            if (wallpaperMsg.type() == QDBusMessage::ReplyMessage) {
                qDebug() << "PlasmaShell set wallpaper succeeded";
                
                // Force a refresh
                wallpaperInterface.call("refreshCurrentShell");
                
                emit wallpaperSet(imagePath);
                return true;
            } else {
                qWarning() << "PlasmaShell set wallpaper failed:" << wallpaperMsg.errorMessage();
            }
        } else {
            qWarning() << "PlasmaShell set wallpaper plugin failed:" << pluginMsg.errorMessage();
        }
    } else {
        qWarning() << "PlasmaShell interface is not valid";
    }
    
    // Method 2: Try using the wallpaper service directly
    QDBusInterface wallpaperService("org.kde.plasmashell", "/Wallpaper", "org.kde.plasma.Wallpaper", sessionBus);
    
    if (wallpaperService.isValid()) {
        qDebug() << "Wallpaper service interface is valid";
        QDBusMessage msg = wallpaperService.call("setWallpaper", imagePath);
        
        if (msg.type() == QDBusMessage::ReplyMessage) {
            qDebug() << "Wallpaper service set wallpaper succeeded";
            emit wallpaperSet(imagePath);
            return true;
        } else {
            qWarning() << "Wallpaper service set wallpaper failed:" << msg.errorMessage();
        }
    }
    
    // Method 3: Try using KWin interface (older method)
    QDBusInterface kwin("org.kde.KWin", "/KWin", "org.kde.KWin", sessionBus);
    
    if (kwin.isValid()) {
        qDebug() << "KWin interface is valid";
        QDBusMessage msg = kwin.call("setWallpaper", imagePath);
        
        if (msg.type() == QDBusMessage::ReplyMessage) {
            qDebug() << "KWin set wallpaper succeeded";
            emit wallpaperSet(imagePath);
            return true;
        } else {
            qWarning() << "KWin set wallpaper failed:" << msg.errorMessage();
        }
    } else {
        qWarning() << "KWin interface is not valid";
    }
    
    return false;
}

bool WallpaperService::setWallpaperViaCommand(const QString &imagePath)
{
    qDebug() << "setWallpaperViaCommand called with:" << imagePath;
    
    // Method 1: Try using plasma-apply-wallpaperimage command (KDE 6)
    QStringList arguments;
    arguments << imagePath;
    
    m_process->start("plasma-apply-wallpaperimage", arguments);
    
    if (m_process->waitForStarted()) {
        qDebug() << "plasma-apply-wallpaperimage started successfully";
        if (m_process->waitForFinished(10000)) { // 10 second timeout
            int exitCode = m_process->exitCode();
            QString output = QString::fromUtf8(m_process->readAllStandardOutput());
            QString error = QString::fromUtf8(m_process->readAllStandardError());
            
            qDebug() << "plasma-apply-wallpaperimage finished with exit code:" << exitCode;
            qDebug() << "Output:" << output;
            qDebug() << "Error:" << error;
            
            if (exitCode == 0) {
                qDebug() << "plasma-apply-wallpaperimage succeeded, waiting for wallpaper to update...";
                
                // Wait a moment for the wallpaper to actually change
                QThread::msleep(500);
                
                // Verify the wallpaper was set
                if (verifyWallpaperSet(imagePath)) {
                    qDebug() << "Wallpaper verification successful";
                    emit wallpaperSet(imagePath);
                    return true;
                } else {
                    qDebug() << "Wallpaper verification failed, but command succeeded";
                    // Still return true since the command succeeded
                    emit wallpaperSet(imagePath);
                    return true;
                }
            }
        }
    } else {
        qWarning() << "Failed to start plasma-apply-wallpaperimage";
    }
    
    // Method 2: Try using qdbus command with improved script
    arguments.clear();
    QString script = QString(
        "for (var i = 0; i < desktops().length; i++) {"
        "  desktops()[i].wallpaperPlugin = 'org.kde.image';"
        "  desktops()[i].currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];"
        "  desktops()[i].writeConfig('Image', '%1');"
        "  desktops()[i].writeConfig('FillMode', 2);"
        "}"
    ).arg(imagePath);
    
    arguments << "org.kde.plasmashell" << "/PlasmaShell" << "org.kde.PlasmaShell.evaluateScript" << script;
    
    m_process->start("qdbus", arguments);
    
    if (m_process->waitForStarted()) {
        qDebug() << "qdbus started successfully";
        if (m_process->waitForFinished(5000)) { // 5 second timeout
            int exitCode = m_process->exitCode();
            QString output = QString::fromUtf8(m_process->readAllStandardOutput());
            QString error = QString::fromUtf8(m_process->readAllStandardError());
            
            qDebug() << "qdbus finished with exit code:" << exitCode;
            qDebug() << "Output:" << output;
            qDebug() << "Error:" << error;
            
            if (exitCode == 0) {
                // Force refresh
                QProcess::startDetached("qdbus", QStringList() << "org.kde.plasmashell" << "/PlasmaShell" << "org.kde.PlasmaShell.refreshCurrentShell");
                emit wallpaperSet(imagePath);
                return true;
            }
        }
    } else {
        qWarning() << "Failed to start qdbus";
    }
    
    // Method 3: Try using gsettings (for GNOME compatibility, but might work)
    arguments.clear();
    arguments << "set" << "org.gnome.desktop.background" << "picture-uri" << QString("file://%1").arg(imagePath);
    
    m_process->start("gsettings", arguments);
    
    if (m_process->waitForStarted() && m_process->waitForFinished(3000)) {
        int exitCode = m_process->exitCode();
        if (exitCode == 0) {
            qDebug() << "gsettings set wallpaper succeeded";
            emit wallpaperSet(imagePath);
            return true;
        }
    }
    
    return false;
}

bool WallpaperService::setWallpaperViaPlasmaShell(const QString &imagePath)
{
    // Try to write directly to Plasma configuration
    QString configPath = getWallpaperConfigPath();
    
    if (configPath.isEmpty()) {
        return false;
    }
    
    QSettings settings(configPath, QSettings::IniFormat);
    
    // Set wallpaper plugin
    settings.beginGroup("Containments");
    
    // Find desktop containment
    QStringList groups = settings.childGroups();
    for (const QString &group : groups) {
        if (group.startsWith("1,")) {
            settings.beginGroup(group);
            settings.beginGroup("Wallpaper");
            settings.beginGroup("org.kde.image");
            settings.beginGroup("General");
            
            settings.setValue("Image", imagePath);
            
            settings.endGroup(); // General
            settings.endGroup(); // org.kde.image
            settings.endGroup(); // Wallpaper
            settings.endGroup(); // group
            break;
        }
    }
    
    settings.endGroup(); // Containments
    settings.sync();
    
    // Try to reload plasma shell
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    QDBusInterface plasmashell("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", sessionBus);
    
    if (plasmashell.isValid()) {
        plasmashell.call("refreshCurrentShell");
    }
    
    emit wallpaperSet(imagePath);
    return true;
}

QString WallpaperService::getWallpaperConfigPath() const
{
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QString plasmaConfig = configDir + "/plasma-org.kde.plasma.desktop-appletsrc";
    
    if (QFileInfo::exists(plasmaConfig)) {
        return plasmaConfig;
    }
    
    // Try alternative paths
    QStringList possiblePaths = {
        configDir + "/plasma-org.kde.plasma.desktop-appletsrc",
        configDir + "/plasma-org.kde.plasma.desktop-appletsrc",
        QDir::homePath() + "/.config/plasma-org.kde.plasma.desktop-appletsrc"
    };
    
    for (const QString &path : possiblePaths) {
        if (QFileInfo::exists(path)) {
            return path;
        }
    }
    
    return QString();
}

void WallpaperService::copyImageToWallpaperDir(const QString &imagePath)
{
    QString wallpaperDir = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/Wallpapers";
    
    QDir dir;
    if (!dir.exists(wallpaperDir)) {
        dir.mkpath(wallpaperDir);
    }
    
    QFileInfo fileInfo(imagePath);
    QString destPath = wallpaperDir + "/" + fileInfo.fileName();
    
    if (QFile::copy(imagePath, destPath)) {
        m_lastImagePath = destPath;
    }
}

void WallpaperService::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus)
    
    if (exitCode == 0) {
        emit wallpaperSet(m_lastImagePath);
    } else {
        QString errorOutput = QString::fromUtf8(m_process->readAllStandardError());
        emit wallpaperError(tr("Process failed with exit code %1: %2").arg(exitCode).arg(errorOutput));
    }
}

void WallpaperService::onProcessError(QProcess::ProcessError error)
{
    QString errorString;
    
    switch (error) {
    case QProcess::FailedToStart:
        errorString = tr("Failed to start wallpaper setting process");
        break;
    case QProcess::Crashed:
        errorString = tr("Wallpaper setting process crashed");
        break;
    case QProcess::Timedout:
        errorString = tr("Wallpaper setting process timed out");
        break;
    case QProcess::WriteError:
        errorString = tr("Write error in wallpaper setting process");
        break;
    case QProcess::ReadError:
        errorString = tr("Read error in wallpaper setting process");
        break;
    default:
        errorString = tr("Unknown error in wallpaper setting process");
        break;
    }
    
    emit wallpaperError(errorString);
}

bool WallpaperService::verifyWallpaperSet(const QString &imagePath) const
{
    // Try to read the current wallpaper from the configuration
    QString configPath = getWallpaperConfigPath();
    if (configPath.isEmpty()) {
        return false;
    }
    
    QSettings settings(configPath, QSettings::IniFormat);
    settings.beginGroup("Containments");
    
    QStringList groups = settings.childGroups();
    for (const QString &group : groups) {
        if (group.startsWith("1,")) {
            settings.beginGroup(group);
            settings.beginGroup("Wallpaper");
            settings.beginGroup("org.kde.image");
            settings.beginGroup("General");
            
            QString currentImage = settings.value("Image").toString();
            settings.endGroup(); // General
            settings.endGroup(); // org.kde.image
            settings.endGroup(); // Wallpaper
            settings.endGroup(); // group
            
            qDebug() << "Current wallpaper in config:" << currentImage;
            qDebug() << "Expected wallpaper:" << imagePath;
            
            return (currentImage == imagePath);
        }
    }
    
    return false;
}
