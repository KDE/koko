/*
    SPDX-FileCopyrightText: 2016, 2019 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#include "filemenu.h"

#include <QApplication>
#include <QClipboard>
#include <QFileDialog>
#include <QIcon>
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

class FileMenuSingleton
{
public:
    FileMenu self;
};

Q_GLOBAL_STATIC(FileMenuSingleton, privateFileMenuSelf)

FileMenu::FileMenu(QWidget *parent)
    : QMenu(parent)
{
    setAttribute(Qt::WA_TranslucentBackground);
}

FileMenu *FileMenu::instance()
{
    return &privateFileMenuSelf->self;
}

QUrl FileMenu::url() const
{
    return m_url;
}

void FileMenu::setUrl(const QUrl &url)
{
    if (m_url == url) {
        return;
    }

    clear();
    m_url = url;
    if (!m_url.isValid()) {
        Q_EMIT urlChanged();
        return;
    }

    KFileItem fileItem(m_url);

    if (KProtocolManager::supportsWriting(m_url)) {
        QAction *saveAsAction = addAction(QIcon::fromTheme(QStringLiteral("document-save-as")), i18n("Save As"));
        static const auto saveAs = [this] {
            QStringList supportedFilters;
            const auto mimetype = QMimeDatabase().mimeTypeForUrl(m_url);
            const auto mimetypeName = mimetype.name().toLatin1();
            const auto preferredSuffix = mimetype.preferredSuffix().toLatin1();
            const auto imageMimeTypes = QImageWriter::supportedMimeTypes();
            const auto isWritableImageFormat = imageMimeTypes.contains(mimetypeName);
            if (isWritableImageFormat) {
                supportedFilters.reserve(imageMimeTypes.size());
                for (const auto &mimeType : imageMimeTypes) {
                    supportedFilters.append(QString::fromUtf8(mimeType).trimmed());
                }
            }
            auto dialog = new QFileDialog();
            dialog->setAcceptMode(QFileDialog::AcceptSave);
            dialog->setFileMode(QFileDialog::AnyFile);
            QUrl dirUrl = m_url.adjusted(QUrl::RemoveFilename);
            dialog->setDirectoryUrl(dirUrl);
            dialog->selectFile(m_url.fileName());
            dialog->setDefaultSuffix(preferredSuffix);
            dialog->setMimeTypeFilters(supportedFilters);
            dialog->selectMimeTypeFilter(mimetype.name());

            // Don't use exec() like the QFileDialog docs show.
            // It can cause a race condition that leads to a crash when the QML environment is being destroyed.
            connect(dialog, &QFileDialog::finished, this, [this, dialog, isWritableImageFormat](int result) mutable {
                dialog->deleteLater();
                const bool accepted = result == QDialog::Accepted;
                const auto &selectedUrl = dialog->selectedUrls().value(0, QUrl());
                if (!accepted || selectedUrl.fileName().isEmpty()) {
                    return;
                }
                if (isWritableImageFormat && selectedUrl.isLocalFile()) {
                    QImage image(m_url.toLocalFile());
                    image.save(selectedUrl.toLocalFile());
                    return;
                }
                KIO::copyAs(m_url, selectedUrl)->start();
            });
            dialog->open();
        };
        connect(saveAsAction, &QAction::triggered, saveAs);
    }

    if (KProtocolManager::supportsListing(m_url)) {
        QAction *openContainingFolderAction = addAction(QIcon::fromTheme(QStringLiteral("folder-open")), i18n("Open Containing Folder"));
        connect(openContainingFolderAction, &QAction::triggered, [this] {
            KIO::highlightInFileManager({m_url});
        });
    }

    // KFileItemActions *kFileItemActions = new KFileItemActions(this);
    KFileItemListProperties itemProperties(KFileItemList({fileItem}));
    // kFileItemActions->setItemListProperties(itemProperties);
    // kFileItemActions->setParentWidget(this);

    auto openWithAction = addAction(QIcon::fromTheme(u"system-run"_s), i18nc("@action:inmenu", "&Open With…"));
    connect(openWithAction, &QAction::triggered, [this, itemProperties] {
        auto *job = new KIO::ApplicationLauncherJob();
        job->setUrls(itemProperties.urlList());
        job->setUiDelegate(KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, this));
        job->start();
    });

    // KStandardAction? But then the Ctrl+C shortcut makes no sense in this context
    QAction *copyAction = addAction(QIcon::fromTheme(QStringLiteral("edit-copy")), i18n("&Copy"));
    connect(copyAction, &QAction::triggered, this, [fileItem] {
        // inspired by KDirModel::mimeData()
        QMimeData *data = new QMimeData(); // who cleans it up?
        KUrlMimeData::setUrls({fileItem.url()}, {fileItem.mostLocalUrl()}, data);
        QApplication::clipboard()->setMimeData(data);
    });

    QAction *copyPathAction = addAction(QIcon::fromTheme(QStringLiteral("edit-copy-path")), i18nc("@action:incontextmenu", "Copy Location"));
    connect(copyPathAction, &QAction::triggered, this, [fileItem] {
        QString path = fileItem.localPath();
        if (path.isEmpty()) {
            path = fileItem.url().toDisplayString();
        }
        QApplication::clipboard()->setText(path);
    });

    addSeparator();

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
        QAction *moveToTrashAction = KStandardAction::moveToTrash(this, moveToTrashLambda, this);
        moveToTrashAction->setShortcut({}); // Can't focus notification to press Delete
        addAction(moveToTrashAction);
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
        QAction *deleteAction = KStandardAction::deleteFile(this, deleteLambda, this);
        deleteAction->setShortcut({});
        addAction(deleteAction);
    }

    // addSeparator();
    // kFileItemActions->addActionsTo(this);
    Q_EMIT urlChanged();
}

void FileMenu::setVisible(bool visible)
{
    bool oldVisible = isVisible();
    if (oldVisible == visible) {
        return;
    }
    // Workaround for a bug where Qt Quick buttons always open the menu even when the menu is already open
    if (visible) {
        QMenu::setVisible(true);
    } else {
        QTimer::singleShot(200, this, [this] {
            QMenu::setVisible(false);
        });
    }
}

void FileMenu::popup(QQuickItem *item, qreal xOffset, qreal yOffset)
{
    if (!item || !item->window()) {
        windowHandle()->setTransientParent(nullptr);
        QTimer::singleShot(0, this, [&]() {
            QMenu::popup(QCursor::pos() + QPoint{qRound(xOffset), qRound(yOffset)});
        });
        return;
    }
    auto itemWindow = item->window();
    auto point = item->mapToGlobal({xOffset, yOffset});
    auto screenRect = itemWindow->screen()->geometry();
    auto sizeHint = this->sizeHint();
    if (point.y() + sizeHint.height() > screenRect.bottom()) {
        point.setY(point.y() - item->height() - sizeHint.height());
    }
    if (point.x() + sizeHint.width() > screenRect.right()) {
        point.setX(point.x() - sizeHint.width() + item->width());
    }
    if (winId() && itemWindow->winId()) {
        windowHandle()->setTransientParent(itemWindow);
    }
    // Workaround same as plasma to have click anywhere to close the menu
    // https://bugreports.qt.io/browse/QTBUG-59044
    QTimer::singleShot(0, this, [this, itemWindow, point]() {
        if (itemWindow->mouseGrabberItem()) {
            itemWindow->mouseGrabberItem()->ungrabMouse();
        }
        QMenu::popup(point.toPoint());
    });
}

void FileMenu::showEvent(QShowEvent *event)
{
    QMenu::showEvent(event);
    Q_EMIT visibleChanged();
}

void FileMenu::hideEvent(QHideEvent *event)
{
    QMenu::hideEvent(event);
    Q_EMIT visibleChanged();
}
