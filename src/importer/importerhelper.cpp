// SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "importerhelper.h"

#include <QDesktopServices>
#include <QStandardPaths>
#include <QUrl>

#include <KIO/DesktopExecParser>
#include <KIO/StatJob>
#include <KLocalizedString>

#include "documentdirfinder.h"

using namespace Qt::StringLiterals;

ImporterHelper::ImporterHelper(QObject *parent)
    : QObject(parent)
{
    auto job = KIO::stat(QUrl(u"camera:/"_s));
    connect(job, &KJob::finished, this, [this](KJob *job) {
        if (job->error() == KIO::Error::ERR_CANNOT_CREATE_WORKER) {
            m_isMtpWorkerAvailable = false;
        } else {
            m_isMtpWorkerAvailable = true;
        }

        Q_EMIT isMtpWorkerAvailableChanged();
        m_loading = false;
        Q_EMIT loadingChanged();
    });
    job->start();

    m_discoverAvailable = !QStandardPaths::findExecutable(u"plasma-discover"_s).isEmpty();

    auto finder = new DocumentDirFinder(QUrl(u"camera:/"_s));
    connect(finder, &DocumentDirFinder::done, this, [this](const QUrl &url) {
        // QString path = QDir(d->mSrcBaseUrl.path()).relativeFilePath(d->mSrcUrl.path());
        // QString text;
        // if (path.isEmpty() || path == QLatin1String(".")) {
        //     text = d->mSrcBaseName;
        // } else {
        //     path = QUrl::fromPercentEncoding(path.toUtf8());
        //     path.replace('/', QString::fromUtf8(" › "));
        //     text = QString::fromUtf8("%1 › %2").arg(d->mSrcBaseName, path);
        // }
        // d->mSrcUrlButton->setText(text);
        // m_url;
    });
    connect(finder, &DocumentDirFinder::protocollNotSupportedError, this, [this](const QString &errorText) {
        m_isMtpWorkerAvailable = false;
        Q_EMIT isMtpWorkerAvailableChanged();
    });
    finder->start();
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
