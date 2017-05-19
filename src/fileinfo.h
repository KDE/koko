#ifndef FILEINFO_H
#define FILEINFO_H

#include <QObject>

class FileInfo : public QObject
{
    Q_OBJECT
public:
    explicit FileInfo( QObject* parent = 0);
    Q_INVOKABLE bool checkExistence( const QString& path);
    
};

#endif
