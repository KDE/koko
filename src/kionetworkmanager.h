// KIONetworkReply.h
#pragma once

#include <KIO/TransferJob>
#include <QBuffer>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QQmlNetworkAccessManagerFactory>

// this bit would be in a _p header if moved to KIO
class KIONetworkReply : public QNetworkReply
{
    Q_OBJECT

public:
    KIONetworkReply(const QNetworkRequest &request, QObject *parent = nullptr);
    ~KIONetworkReply();

    void start(KIO::TransferJob *job);

    qint64 readData(char *data, qint64 maxlen) override;
    void close() override;
    void abort() override;

private Q_SLOTS:
    void slotDataReceived(KIO::Job *, const QByteArray &data);
    void slotFinished(KJob *job);

private:
    QBuffer m_buffer;
    KIO::TransferJob *m_job = nullptr;
};

class KIONetworkAccessManager : public QNetworkAccessManager
{
    Q_OBJECT

public:
    explicit KIONetworkAccessManager(QObject *parent = nullptr);
    QStringList supportedSchemes() const override;

protected:
    QNetworkReply *createRequest(Operation op, const QNetworkRequest &request, QIODevice *outgoingData = nullptr) override;
};

// this bit would be the only public API if moved to KIO

/**
 * Create a QQmlNetworkAccessManagerFactory that supports all KIO protocols
 * Any get() requests to a KIO supported URL will be fetched in a manner usable from QNetworkRequest
 */
class KIONetworkAccessManagerFactory : public QObject, public QQmlNetworkAccessManagerFactory
{
    Q_OBJECT

public:
    explicit KIONetworkAccessManagerFactory(QObject *parent = nullptr);

    QNetworkAccessManager *create(QObject *parent) override;
};
