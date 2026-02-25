/*
    SPDX-FileCopyrightText: 2016, 2019 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2025 Noah Davis <noahadvs@gmail.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#include "filemenuactions.h"
#include "printerhelper.h"

#include <QApplication>
#include <QClipboard>
#include <QFileDialog>
#include <QIcon>
#include <QImageReader>
#include <QImageWriter>
#include <QMenu>
#include <QMimeData>
#include <QMimeDatabase>
#include <QQuickItem>
#include <QQuickWindow>
#include <QScreen>
#include <QTimer>

#include <KConfigGroup>
#include <KFileItemActions>
#include <KFileItemListProperties>
#include <KLocalizedString>
#include <KPropertiesDialog>
#include <KProtocolManager>
#include <KSharedConfig>
#include <KStandardAction>
#include <KUrlMimeData>

#include <KIO/ApplicationLauncherJob>
#include <KIO/CopyJob> // for KIO::trash
#include <KIO/DeleteJob>
#include <KIO/FileUndoManager>
#include <KIO/JobUiDelegate>
#include <KIO/JobUiDelegateFactory>
#include <KIO/OpenFileManagerWindowJob>
#include <KIO/WidgetsAskUserActionHandler>

using namespace Qt::StringLiterals;

FileMenuActions::FileMenuActions(QObject *parent)
    : QObject(parent)
{
}

QList<QObject *> FileMenuActions::actions() const
{
    return m_actions;
}

QList<QUrl> FileMenuActions::urls() const
{
    return m_urls;
}

void FileMenuActions::setUrls(const QList<QUrl> &urls)
{
    if (m_urls == urls) {
        return;
    }

    m_urls = urls;
    for (auto action : m_actions) {
        action->deleteLater();
    }
    m_actions.clear();

    if (m_urls.isEmpty()) {
        Q_EMIT urlsChanged();
        return;
    }

    static const auto addAction = [this](const QIcon &icon, const QString &text, auto func) {
        auto action = new QAction(icon, text, this);
        connect(action, &QAction::triggered, this, func);
        m_actions.push_back(action);
        return action;
    };

    KFileItemList fileItems;
    fileItems.reserve(m_urls.size());
    std::transform(urls.cbegin(), urls.cend(), std::back_inserter(fileItems), [](const QUrl &url) {
        return KFileItem(url);
    });

    KFileItemListProperties itemProperties(fileItems);

    const bool singleFile = fileItems.size() == 1;
    const auto singleFileMimetype = fileItems[0].mimetype().toLatin1();
    const auto singleFileReadableImageMimetype = QImageReader::supportedMimeTypes().contains(singleFileMimetype);

    // Save As action
    if (singleFile) {
        // TODO: Mix of using m_urls, urls and fileItem, pick one
        auto saveAsLambda = [=, this] {
            const auto suffix = fileItems[0].suffix();
            const auto writableImageMimetypes = QImageWriter::supportedMimeTypes();
            // We only list different writable types when writing as a different
            // type is possible.
            // For an image file to be converted with QImage, it needs to be
            // readable and writable by QImage.
            QStringList mimetypeFilters{};
            if (singleFileReadableImageMimetype && fileItems[0].isLocalFile()) {
                mimetypeFilters.reserve(mimetypeFilters.size() + writableImageMimetypes.size());
                // If we can read the mimetype with QImage, but not write it with QImage,
                // we can still make a copy.
                if (!writableImageMimetypes.contains(singleFileMimetype)) {
                    mimetypeFilters.append(singleFileMimetype);
                }
                for (const auto &imageMimetype : writableImageMimetypes) {
                    mimetypeFilters.append(QString::fromUtf8(imageMimetype).trimmed());
                }
            } else if (!singleFileMimetype.isEmpty()) {
                // we can still make a copy.
                mimetypeFilters.append(singleFileMimetype);
            }
            // Add an "All files" filter at the end.
            mimetypeFilters.append(u"application/octet-stream"_s);
            auto dialog = new QFileDialog();
            dialog->setAcceptMode(QFileDialog::AcceptSave);
            dialog->setFileMode(QFileDialog::AnyFile);
            QUrl dirUrl = urls[0].adjusted(QUrl::RemoveFilename);
            dialog->setDirectoryUrl(dirUrl);
            dialog->selectFile(urls[0].fileName());
            dialog->setDefaultSuffix(suffix);
            dialog->setMimeTypeFilters(mimetypeFilters);
            dialog->selectMimeTypeFilter(singleFileMimetype);

            // Don't use exec() like the QFileDialog docs show.
            // It can cause a race condition that leads to a crash when the QML environment is being destroyed.
            connect(dialog,
                    &QFileDialog::finished,
                    this,
                    [this, dialog, singleFileMimetype, writableImageMimetypes, singleFileReadableImageMimetype](int result) mutable {
                        dialog->deleteLater();
                        const bool accepted = result == QDialog::Accepted;
                        const auto &selectedUrl = dialog->selectedUrls().value(0, QUrl());
                        if (!accepted || selectedUrl.fileName().isEmpty()) {
                            return;
                        }
                        if (singleFileReadableImageMimetype && selectedUrl.isLocalFile()) {
                            auto selectedUrlMimetype = QMimeDatabase().mimeTypeForUrl(selectedUrl).name().toLatin1();
                            if (singleFileMimetype != selectedUrlMimetype && writableImageMimetypes.contains(selectedUrlMimetype)) {
                                QImage image(m_urls[0].toLocalFile());
                                image.save(selectedUrl.toLocalFile());
                                return;
                            }
                            // TODO: Maybe catch cases where users select a url with a
                            // mimetype that isn't supported by QImageWriter? It's unclear
                            // how that should be handled. Mimetypes for urls are based on
                            // filename extensions, but a filename can have no extension or
                            // an unusual extension and still be read by apps that support
                            // the mimetype for the file's data.
                        }
                        KIO::copyAs(m_urls[0], selectedUrl)->start();
                    });
            dialog->open();
        };
        m_actions.push_back(KStandardAction::saveAs(this, saveAsLambda, this));
    }

    // Open Containing Folder action
    if (std::all_of(m_urls.cbegin(), m_urls.cend(), [](const QUrl &url) {
            return KProtocolManager::supportsListing(url);
        })) {
        auto openFolderLambda = [this] {
            KIO::highlightInFileManager(m_urls);
        };
        addAction(QIcon::fromTheme(u"folder-open"_s), i18nc("@action:inmenu", "Open Containing Folder"), openFolderLambda);
    }

    // Standard actions
    KFileItemActions kFileItemActions(this);
    kFileItemActions.setItemListProperties(itemProperties);

    QMenu menu;
    kFileItemActions.insertOpenWithActionsTo(nullptr, &menu, {qApp->desktopFileName()});

    auto openWithLambda = [this] {
        auto job = new KIO::ApplicationLauncherJob(this);
        job->setUrls(m_urls);
        job->setUiDelegate(KIO::createDefaultJobUiDelegate());
        job->start();
    };
    addAction(QIcon::fromTheme(u"system-run"_s), i18nc("@action:inmenu", "&Open With…"), openWithLambda);

    auto copyLambda = [fileItems] {
        QMimeData *data = new QMimeData(); // Cleaned up by Qt later

        QList<QUrl> urls;
        QList<QUrl> mostLocalUrls;
        urls.reserve(fileItems.size());
        mostLocalUrls.reserve(fileItems.size());
        for (const KFileItem &item : fileItems) {
            urls << item.url();
            mostLocalUrls << item.mostLocalUrl();
        }

        KUrlMimeData::setUrls(urls, mostLocalUrls, data);
        QApplication::clipboard()->setMimeData(data);
    };
    m_actions.push_back(KStandardAction::copy(this, copyLambda, this));

    auto copyPathLambda = [fileItems] {
        // TODO: Is better behaviour possible for multiple fileItems?
        //       Maybe with multiple, we don't have fallback and verify that all
        //       localPath is the same first? Is fallback even proper?
        QString path = fileItems[0].localPath();
        if (path.isEmpty()) {
            path = fileItems[0].url().toDisplayString();
        }
        QApplication::clipboard()->setText(path);
    };

    addAction(QIcon::fromTheme(u"edit-copy-path"_s), i18nc("@action:inmenu", "Copy Location"), copyPathLambda);

    const bool canTrash = itemProperties.isLocal() && itemProperties.supportsMoving();
    if (canTrash) {
        auto moveToTrashLambda = [this] {
            auto handler = new KIO::WidgetsAskUserActionHandler(this);
            connect(handler, &KIO::WidgetsAskUserActionHandler::askUserDeleteResult, [handler](bool allow, const QList<QUrl> &urls) {
                if (allow) {
                    auto job = KIO::trash(urls);
                    job->uiDelegate()->setAutoErrorHandlingEnabled(true);
                    KIO::FileUndoManager::self()->recordJob(KIO::FileUndoManager::Trash, urls, QUrl(QStringLiteral("trash:/")), job);
                }
                handler->deleteLater();
            });
            handler->askUserDelete({m_urls}, KIO::AskUserActionInterface::Trash, KIO::AskUserActionInterface::DefaultConfirmation);
        };
        m_actions.push_back(KStandardAction::moveToTrash(this, moveToTrashLambda, this));
    }

    KConfigGroup cg(KSharedConfig::openConfig(), u"KDE"_s);
    const bool showDeleteCommand = cg.readEntry("ShowDeleteCommand", false);

    if (itemProperties.supportsDeleting() && (!canTrash || showDeleteCommand)) {
        auto deleteLambda = [this] {
            auto handler = new KIO::WidgetsAskUserActionHandler(this);
            connect(handler, &KIO::WidgetsAskUserActionHandler::askUserDeleteResult, [handler](bool allow, const QList<QUrl> &urls) {
                if (allow) {
                    auto job = KIO::del(urls);
                    job->uiDelegate()->setAutoErrorHandlingEnabled(true);
                }
                handler->deleteLater();
            });
            handler->askUserDelete(m_urls, KIO::AskUserActionInterface::Delete, KIO::AskUserActionInterface::DefaultConfirmation);
        };
        m_actions.push_back(KStandardAction::deleteFile(this, deleteLambda, this));
    }

    // QPrinter requires the use of QPainter, so it must be a readable image.
    if (singleFile && PrinterHelper::printerSupportAvailable() && singleFileReadableImageMimetype) {
        auto printLambda = [this] {
            PrinterHelper::printFileFromUrl(m_urls[0]);
        };
        m_actions.push_back(KStandardAction::print(this, printLambda, this));
    }

    Q_EMIT urlsChanged();
}
