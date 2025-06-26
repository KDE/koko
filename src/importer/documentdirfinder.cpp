// Copied from Gwenview: an image viewer
// SPDX-FileCopyrightText: 2009 Aurélien Gâteau <agateau@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "documentdirfinder.h"

#include <KCoreDirLister>
#include <KIO/Job>
#include <KJobUiDelegate>

#include "mimetypeutils.h"

DocumentDirFinder::DocumentDirFinder(const QUrl &rootUrl)
{
    mRootUrl = rootUrl;
    mDirLister = new KCoreDirLister(this);
    connect(mDirLister, &KCoreDirLister::itemsAdded, this, &DocumentDirFinder::slotItemsAdded);
    connect(mDirLister, &KCoreDirLister::completed, this, &DocumentDirFinder::slotCompleted);
    connect(mDirLister, &KCoreDirLister::jobError, this, [this](KIO::Job *job) {
        if (job->error() == KIO::Error::ERR_CANNOT_CREATE_WORKER) {
            Q_EMIT protocollNotSupportedError(job->errorText());
        } else {
            job->uiDelegate()->showErrorMessage();
        }
    });
    mDirLister->setAutoErrorHandlingEnabled(false);
    mDirLister->openUrl(rootUrl);
}

DocumentDirFinder::~DocumentDirFinder() = default;

void DocumentDirFinder::start()
{
    mDirLister->openUrl(mRootUrl);
}

void DocumentDirFinder::slotItemsAdded(const QUrl &dir, const KFileItemList &list)
{
    for (const KFileItem &item : list) {
        MimeTypeUtils::Kind kind = MimeTypeUtils::fileItemKind(item);
        switch (kind) {
        case MimeTypeUtils::KIND_DIR:
            if (mFoundDirUrl.isValid()) {
                // This is the second dir we find, stop now
                finish(dir, MultipleDirsFound);
                return;
            } else {
                // First dir
                mFoundDirUrl = item.url();
            }
            break;

        case MimeTypeUtils::KIND_RASTER_IMAGE:
        case MimeTypeUtils::KIND_SVG_IMAGE:
        case MimeTypeUtils::KIND_VIDEO:
            finish(dir, DocumentDirFound);
            return;

        case MimeTypeUtils::KIND_UNKNOWN:
        case MimeTypeUtils::KIND_FILE:
            break;
        }
    }
}

void DocumentDirFinder::slotCompleted()
{
    if (mFoundDirUrl.isValid()) {
        const QUrl url = mFoundDirUrl;
        mFoundDirUrl.clear();
        mDirLister->openUrl(url);
    } else {
        finish(mRootUrl, NoDocumentFound);
    }
}

void DocumentDirFinder::finish(const QUrl &url, DocumentDirFinder::Status status)
{
    disconnect(mDirLister, nullptr, this, nullptr);
    Q_EMIT done(url, status);
    deleteLater();
}

#include "moc_documentdirfinder.cpp"
