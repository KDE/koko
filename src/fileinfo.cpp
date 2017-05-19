#include "fileinfo.h"
#include <QFileInfo>

FileInfo::FileInfo(QObject* parent)
{
    Q_UNUSED(parent)
}

bool FileInfo::checkExistence(const QString& path)
{
    return QFileInfo::exists(path);
}
