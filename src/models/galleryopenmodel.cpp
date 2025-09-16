/*
 *  SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *  SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include <KLocalizedString>

#include "galleryopenmodel.h"

QUrl pathToUrl(const QStringList &path, const KFileItemList &rootFileItems)
{
    if (path.isEmpty()) {
        return QUrl();
    }

    const int rootFileItemIndex = path.at(0).toInt();
    QUrl url = rootFileItems.at(rootFileItemIndex).url();

    // Ensure this is treated as a directory for resolved later
    if (!url.path().endsWith('/')) {
        url.setPath(url.path() + '/');
    }

    for (int i = 1; i < path.size(); ++i) {
        url = url.resolved(path.at(i) + '/');
    }

    return url;
}

GalleryOpenModel::GalleryOpenModel(QObject *parent)
    : AbstractNavigableGalleryModel(parent)
    , m_mode(OpenNone)
    , m_status(Unloaded)
    , m_galleryMode(Root)
    , m_dirLister(new KDirLister(this))
{
    connect(this, &GalleryOpenModel::pathChanged, this, &GalleryOpenModel::titleChanged);
    connect(m_dirLister, &KCoreDirLister::completed, this, [this]() {
        Q_ASSERT(m_galleryMode == Root);

        m_status = Loaded;
        Q_EMIT statusChanged();
    });
    connect(m_dirLister, &KCoreDirLister::itemsAdded, this, [this](const QUrl &directoryUrl, const KFileItemList &items) {
        Q_UNUSED(directoryUrl);
        Q_ASSERT(m_galleryMode == Root);

        if (items.isEmpty()) {
            return;
        }

        const int beginRow = m_fileItems.count();
        const int endRow = beginRow + items.count() - 1;

        beginInsertRows(QModelIndex(), beginRow, endRow);
        m_fileItems.append(items);
        endInsertRows();
    });
    connect(m_dirLister, &KCoreDirLister::itemsDeleted, this, [this](const KFileItemList &items) {
        Q_ASSERT(m_galleryMode == Root);

        for (const auto &fileItem : items) {
            const int row = m_fileItems.indexOf(fileItem);
            if (row != -1) {
                beginRemoveRows(QModelIndex(), row, row);
                m_fileItems.removeAt(row);
                endRemoveRows();
            }
        }
    });
}

GalleryOpenModel::Mode GalleryOpenModel::mode() const
{
    return m_mode;
}

QUrl GalleryOpenModel::urlToOpen() const
{
    return m_urlToOpen;
}

void GalleryOpenModel::updateOpenItems(const QList<QUrl> &urls)
{
    m_openUrls.clear();

    for (const QUrl &url : urls) {
        m_openUrls.append(url);
    }

    populate({});

    Mode mode;
    if (m_rootFileItems.size() == 0) {
        mode = Mode::OpenNone;
    } else if (m_rootFileItems.size() == 1) {
        mode = m_rootFileItems[0].isFile() ? Mode::OpenImage : Mode::OpenFolder;
    } else {
        mode = Mode::OpenMultiple;
    }

    if (m_mode != mode) {
        m_mode = mode;
        Q_EMIT modeChanged();
    }

    const QUrl urlToOpen = m_rootFileItems.size() == 1 ? m_rootFileItems[0].url() : QUrl();

    if (m_urlToOpen != urlToOpen) {
        m_urlToOpen = urlToOpen;
        Q_EMIT urlToOpenChanged();
    }

    Q_EMIT updated();
}

QString GalleryOpenModel::title() const
{
    return titleForPath(m_path);
}

AbstractGalleryModel::Status GalleryOpenModel::status() const
{
    return m_status;
}

QString GalleryOpenModel::titleForPath(const QVariant &path) const
{
    const QStringList pathList = path.toStringList();

    if (!pathList.isEmpty()) {
        const QUrl url = pathToUrl(pathList, m_rootFileItems).adjusted(QUrl::StripTrailingSlash);

        KFileItem fileItem(url);
        return fileItem.name();
    }

    return i18n("Open");
}

QVariant GalleryOpenModel::path() const
{
    return QVariant(m_path);
}

void GalleryOpenModel::setPath(const QVariant &path)
{
    const QStringList pathList = path.toStringList();

    if (m_path == pathList) {
        return;
    }

    populate(pathList);

    Q_EMIT statusChanged();
    Q_EMIT pathChanged();
}

QVariant GalleryOpenModel::pathForIndex(const QModelIndex &index) const
{
    switch (m_galleryMode) {
    case Root:
        return QString::number(index.row());
    case Directory:
        return QStringList(m_path) << index.data(AbstractGalleryModel::FileItemRole).value<KFileItem>().name();
    default:
        Q_UNREACHABLE();
    }
}

QVariant GalleryOpenModel::data(const QModelIndex &index, int role) const
{
    Q_ASSERT(checkIndex(index, CheckIndexOption::ParentIsInvalid | CheckIndexOption::IndexIsValid));

    switch (m_galleryMode) {
    case Root:
        return dataFromFileItem(m_rootFileItems.at(index.row()), role);
    case Directory:
        return dataFromFileItem(m_fileItems.at(index.row()), role);
    default:
        Q_UNREACHABLE();
    }
}

int GalleryOpenModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    switch (m_galleryMode) {
    case Root:
        return m_rootFileItems.size();
    case Directory:
        return m_fileItems.size();
    default:
        Q_UNREACHABLE();
    }
}

void GalleryOpenModel::populate(const QStringList &path)
{
    beginResetModel();
    m_path = path;

    if (m_path.size() == 0) {
        m_dirLister->stop();
        m_rootFileItems.clear();
        for (const QUrl &url : m_openUrls) {
            m_rootFileItems << KFileItem(url);
        }
        m_fileItems = {};
        m_galleryMode = Root;
        m_status = Loaded;
    } else {
        m_fileItems = {};
        m_status = Loading;
        m_dirLister->openUrl(pathToUrl(path, m_rootFileItems));
        m_galleryMode = Directory;
    }

    endResetModel();
}
