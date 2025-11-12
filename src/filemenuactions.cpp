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

QUrl FileMenuActions::url() const
{
    return m_url;
}

void FileMenuActions::setUrl(const QUrl &url)
{
    if (m_url == url) {
        return;
    }

    m_url = url;
    for (auto action : m_actions) {
        action->deleteLater();
    }
    m_actions.clear();

    if (!m_url.isValid()) {
        Q_EMIT urlChanged();
        return;
    }

    static const auto addAction = [this](const QIcon &icon, const QString &text, auto func) {
        auto action = new QAction(icon, text, this);
        connect(action, &QAction::triggered, this, func);
        m_actions.push_back(action);
        return action;
    };

    KFileItem fileItem(m_url);
    KFileItemListProperties itemProperties(KFileItemList({fileItem}));

    const auto mimetype = fileItem.mimetype().toLatin1();
    const auto readableImageMimetypes = QImageReader::supportedMimeTypes();
    const auto isReadableImageMimetype = readableImageMimetypes.contains(mimetype);

    auto saveAsLambda = [=] {
        const auto suffix = fileItem.suffix();
        const auto writableImageMimetypes = QImageWriter::supportedMimeTypes();
        // We only list different writable types when writing as a different
        // type is possible.
        // For an image file to be converted with QImage, it needs to be
        // readable and writable by QImage.
        QStringList mimetypeFilters{};
        if (isReadableImageMimetype && fileItem.isLocalFile()) {
            mimetypeFilters.reserve(mimetypeFilters.size() + writableImageMimetypes.size());
            // If we can read the mimetype with QImage, but not write it with QImage,
            // we can still make a copy.
            if (!writableImageMimetypes.contains(mimetype)) {
                mimetypeFilters.append(mimetype);
            }
            for (const auto &imageMimetype : writableImageMimetypes) {
                mimetypeFilters.append(QString::fromUtf8(imageMimetype).trimmed());
            }
        } else if (!mimetype.isEmpty()) {
            // we can still make a copy.
            mimetypeFilters.append(mimetype);
        }
        // Add an "All files" filter at the end.
        mimetypeFilters.append(u"application/octet-stream"_s);
        auto dialog = new QFileDialog();
        dialog->setAcceptMode(QFileDialog::AcceptSave);
        dialog->setFileMode(QFileDialog::AnyFile);
        QUrl dirUrl = url.adjusted(QUrl::RemoveFilename);
        dialog->setDirectoryUrl(dirUrl);
        dialog->selectFile(url.fileName());
        dialog->setDefaultSuffix(suffix);
        dialog->setMimeTypeFilters(mimetypeFilters);
        dialog->selectMimeTypeFilter(mimetype);

        // Don't use exec() like the QFileDialog docs show.
        // It can cause a race condition that leads to a crash when the QML environment is being destroyed.
        connect(dialog, &QFileDialog::finished, this, [this, dialog, mimetype, writableImageMimetypes, isReadableImageMimetype](int result) mutable {
            dialog->deleteLater();
            const bool accepted = result == QDialog::Accepted;
            const auto &selectedUrl = dialog->selectedUrls().value(0, QUrl());
            if (!accepted || selectedUrl.fileName().isEmpty()) {
                return;
            }
            if (isReadableImageMimetype && selectedUrl.isLocalFile()) {
                auto selectedUrlMimetype = QMimeDatabase().mimeTypeForUrl(selectedUrl).name().toLatin1();
                if (mimetype != selectedUrlMimetype
                    && writableImageMimetypes.contains(selectedUrlMimetype)) {
                    QImage image(m_url.toLocalFile());
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
            KIO::copyAs(m_url, selectedUrl)->start();
        });
        dialog->open();
    };
    m_actions.push_back(KStandardAction::saveAs(this, saveAsLambda, this));

    if (KProtocolManager::supportsListing(m_url)) {
        auto openFolderLambda = [this] {
            KIO::highlightInFileManager({m_url});
        };
        addAction(QIcon::fromTheme(u"folder-open"_s), i18nc("@action:inmenu", "Open Containing Folder"), openFolderLambda);
    }

    KFileItemActions kFileItemActions(this);
    kFileItemActions.setItemListProperties(itemProperties);
    QMenu menu;
    kFileItemActions.insertOpenWithActionsTo(nullptr, &menu, {qApp->desktopFileName()});

    auto openWithLambda = [this] {
        auto job = new KIO::ApplicationLauncherJob(this);
        job->setUrls({m_url});
        job->setSuggestedFileName(m_url.fileName());
        job->setUiDelegate(KIO::createDefaultJobUiDelegate());
        job->start();
    };
    addAction(QIcon::fromTheme(u"system-run"_s), i18nc("@action:inmenu", "&Open With…"), openWithLambda);

    auto copyLambda = [fileItem] {
        QMimeData *data = new QMimeData(); // Cleaned up by Qt later
        KUrlMimeData::setUrls({fileItem.url()}, {fileItem.mostLocalUrl()}, data);
        QApplication::clipboard()->setMimeData(data);
    };
    m_actions.push_back(KStandardAction::copy(this, copyLambda, this));

    auto copyPathLambda = [fileItem] {
        QString path = fileItem.localPath();
        if (path.isEmpty()) {
            path = fileItem.url().toDisplayString();
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
            handler->askUserDelete({m_url}, KIO::AskUserActionInterface::Trash, KIO::AskUserActionInterface::DefaultConfirmation);
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
            handler->askUserDelete({m_url}, KIO::AskUserActionInterface::Delete, KIO::AskUserActionInterface::DefaultConfirmation);
        };
        m_actions.push_back(KStandardAction::deleteFile(this, deleteLambda, this));
    }

    // QPrinter requires the use of QPainter, so it must be a readable image.
    if (PrinterHelper::printerSupportAvailable() && isReadableImageMimetype) {
        auto printLambda = [this] {
            PrinterHelper::printFileFromUrl(m_url);
        };
        m_actions.push_back(KStandardAction::print(this, printLambda, this));
    }

    Q_EMIT urlChanged();
}
