#include "kionetworkmanager.h"
#include <KIO/JobUiDelegate>
#include <KIO/JobUiDelegateFactory>
#include <KIO/TransferJob>
#include <QTimer>
#include <kprotocolinfo.h>

KIONetworkAccessManagerFactory::KIONetworkAccessManagerFactory(QObject *parent)
    : QObject(parent)
{
}

QNetworkAccessManager *KIONetworkAccessManagerFactory::create(QObject *parent)
{
    return new KIONetworkAccessManager(parent);
}

KIONetworkAccessManager::KIONetworkAccessManager(QObject *parent)
    : QNetworkAccessManager(parent)
{
}

QStringList KIONetworkAccessManager::supportedSchemes() const
{
    QStringList protocols = KProtocolInfo::protocols();
    protocols.removeAll(QStringLiteral("file")); // an open question is whether we should let Qt to HTTP? Rather than us proxying it
    return protocols;
}

QNetworkReply *KIONetworkAccessManager::createRequest(Operation op, const QNetworkRequest &request, QIODevice *)
{
    if (op == QNetworkAccessManager::GetOperation && supportedSchemes().contains(request.url().scheme())) {
        auto reply = new KIONetworkReply(request);
        auto job = KIO::get(request.url(), KIO::NoReload, KIO::HideProgressInfo);
        job->setUiDelegate(KIO::createDefaultJobUiDelegate());
        reply->start(job);
        return reply;
    }

    // Fallback to default
    return QNetworkAccessManager::createRequest(op, request);
}

KIONetworkReply::KIONetworkReply(const QNetworkRequest &request, QObject *parent)
    : QNetworkReply(parent)
{
    setRequest(request);
    setUrl(request.url());
    setOpenMode(QIODevice::ReadOnly);
    setOperation(QNetworkAccessManager::GetOperation);
    // setHeader(QNetworkRequest::ContentTypeHeader, "image/jpg"); //FIXME
    m_buffer.open(QIODevice::ReadOnly); // it's only accessed read only, we write to the underlying store
}

KIONetworkReply::~KIONetworkReply()
{
    if (m_job) {
        m_job->kill();
    }
}

void KIONetworkReply::start(KIO::TransferJob *job)
{
    m_job = job;

    connect(job, &KIO::TransferJob::data, this, &KIONetworkReply::slotDataReceived);
    connect(job, &KJob::result, this, &KIONetworkReply::slotFinished);
}

void KIONetworkReply::slotDataReceived(KIO::Job *, const QByteArray &data)
{
    m_buffer.buffer().append(data);
    Q_EMIT readyRead();
}

void KIONetworkReply::slotFinished(KJob *job)
{
    if (job->error()) {
        qDebug() << "boo";
        setError(QNetworkReply::NetworkError::UnknownNetworkError, job->errorString());
        Q_EMIT errorOccurred(error());
        Q_EMIT finished();
        close();
        return;
    }

    qDebug() << "yay";

    setAttribute(QNetworkRequest::HttpStatusCodeAttribute, 200);
    Q_EMIT finished();
    close();
}

qint64 KIONetworkReply::readData(char *data, qint64 maxlen)
{
    return m_buffer.read(data, maxlen);
}

void KIONetworkReply::close()
{
    m_buffer.close();
    QNetworkReply::close();
}

void KIONetworkReply::abort()
{
    if (m_job) {
        m_job->kill();
    }
}
