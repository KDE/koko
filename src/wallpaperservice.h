// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2024 KDE Image Viewer Integration

#ifndef WALLPAPERSERVICE_H
#define WALLPAPERSERVICE_H

#include <QObject>
#include <QString>
#include <QProcess>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusInterface>
#include <QDBusReply>

class WallpaperService : public QObject
{
    Q_OBJECT

public:
    explicit WallpaperService(QObject *parent = nullptr);
    ~WallpaperService();

    Q_INVOKABLE bool setWallpaper(const QString &imagePath);
    Q_INVOKABLE bool setWallpaperForAllScreens(const QString &imagePath);
    Q_INVOKABLE QStringList getAvailableScreens() const;

signals:
    void wallpaperSet(const QString &imagePath);
    void wallpaperError(const QString &error);

private slots:
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessError(QProcess::ProcessError error);

private:
    bool setWallpaperViaDBus(const QString &imagePath, const QString &screen = QString());
    bool setWallpaperViaCommand(const QString &imagePath);
    bool setWallpaperViaPlasmaShell(const QString &imagePath);
    QString getWallpaperConfigPath() const;
    void copyImageToWallpaperDir(const QString &imagePath);
    bool verifyWallpaperSet(const QString &imagePath) const;

    QProcess *m_process;
    QString m_lastImagePath;
};

#endif // WALLPAPERSERVICE_H
