// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "importerhelper.h"

#include <QDesktopServices>
#include <QStandardPaths>

#include <KIO/DesktopExecParser>
#include <KLocalizedString>

#include "documentdirfinder.h"

using namespace Qt::StringLiterals;

ImporterHelper::ImporterHelper(QObject *parent)
    : QObject(parent)
{
    m_discoverAvailable = !QStandardPaths::findExecutable(u"plasma-discover"_s).isEmpty();

    refresh();
}

void ImporterHelper::refresh()
{
    auto finder = new DocumentDirFinder(QUrl(u"camera:"_s));
    connect(finder, &DocumentDirFinder::done, this, [this, finder](const QUrl &url, DocumentDirFinder::Status status) {
        if (status != DocumentDirFinder::NoDocumentFound) {
            m_imageDirectory = url;
            Q_EMIT imageDirectoryChanged();
        }

        m_isMtpWorkerAvailable = true;
        Q_EMIT isMtpWorkerAvailableChanged();

        m_loading = false;
        Q_EMIT loadingChanged();

        finder->deleteLater();
    });
    connect(finder, &DocumentDirFinder::protocollNotSupportedError, this, [this](const QString &errorText) {
        Q_UNUSED(errorText);
        m_isMtpWorkerAvailable = false;
        Q_EMIT isMtpWorkerAvailableChanged();

        m_loading = false;
        Q_EMIT loadingChanged();
    });
    finder->start();
}

QUrl ImporterHelper::imageDirectory() const
{
    return m_imageDirectory;
}

bool ImporterHelper::isMtpWorkerAvailable() const
{
    return m_isMtpWorkerAvailable;
}

bool ImporterHelper::loading() const
{
    return m_loading;
}

bool ImporterHelper::discoverAvailable() const
{
    return m_discoverAvailable;
}

void ImporterHelper::installKioWorker()
{
    const QUrl kameraInstallUrl("appstream://org.kde.kamera");
    if (KIO::DesktopExecParser::hasSchemeHandler(kameraInstallUrl)) {
        QDesktopServices::openUrl(kameraInstallUrl);
    } else {
        Q_EMIT errorOccured(xi18nc("@info when failing to open the appstream URL",
                                   "Opening Discover failed.<nl/>Please check if Discover is installed on your system, or use your system's package manager to "
                                   "install \"Kamera\" package."));
    }
}
